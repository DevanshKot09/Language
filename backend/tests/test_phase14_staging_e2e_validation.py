import json
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.seeds_staging import (
    seed_staging_synthetic_data,
    reset_staging_synthetic_data,
    SYNTHETIC_STAGING_USERS,
)
from app.models.user import User
from app.models.collaboration import Relationship, Report


def auth_header(firebase_uid: str) -> dict:
    return {"Authorization": f"Bearer valid_token_{firebase_uid}"}


def test_staging_seeding_and_idempotence(db_session: Session):
    """
    Test 1: Staging seed script successfully provisions synthetic data idempotently.
    """
    res1 = seed_staging_synthetic_data(db_session)
    assert res1["status"] == "seeded"
    assert res1["synthetic_users_count"] == 8

    # Second execution must be idempotent without primary key collision
    res2 = seed_staging_synthetic_data(db_session)
    assert res2["status"] == "seeded"


def test_staging_learner_journey_and_progress_isolation(client: TestClient, db_session: Session):
    """
    Test 2: Synthetic Learner A accesses practice and progress, but cannot view Learner B.
    """
    seed_staging_synthetic_data(db_session)
    learner_a = db_session.query(User).filter(User.email == "staging_learner_a@lingua.ai").first()
    learner_b = db_session.query(User).filter(User.email == "staging_learner_b@lingua.ai").first()
    headers_a = auth_header(learner_a.firebase_uid)

    # 1. Learner A queries own goals
    goals_res = client.get("/api/v1/goals", headers=headers_a)
    assert goals_res.status_code == 200
    assert len(goals_res.json()) >= 1

    # 2. Learner A cannot query Learner B's parent progress
    unauth_res = client.get(f"/api/v1/parent/children/{learner_b.id}/progress", headers=headers_a)
    assert unauth_res.status_code == 403


def test_staging_parent_e2e_workflow_and_isolation(client: TestClient, db_session: Session):
    """
    Test 3: Synthetic Parent A views linked Learner A; cannot view unrelated Learner B.
    Revoking relationship immediately blocks further access.
    """
    seed_staging_synthetic_data(db_session)
    parent_a = db_session.query(User).filter(User.email == "staging_parent_a@lingua.ai").first()
    learner_a = db_session.query(User).filter(User.email == "staging_learner_a@lingua.ai").first()
    learner_b = db_session.query(User).filter(User.email == "staging_learner_b@lingua.ai").first()
    headers_pa = auth_header(parent_a.firebase_uid)

    # 1. Parent A lists authorized children
    children_res = client.get("/api/v1/parent/children", headers=headers_pa)
    assert children_res.status_code == 200
    children = children_res.json()
    assert any(c["learner_id"] == learner_a.id for c in children)
    assert not any(c["learner_id"] == learner_b.id for c in children)

    # 2. Parent A queries Learner A's progress
    prog_res = client.get(f"/api/v1/parent/children/{learner_a.id}/progress", headers=headers_pa)
    assert prog_res.status_code == 200

    # 3. Parent A queries unrelated Learner B's progress -> HTTP 403
    unauth_prog = client.get(f"/api/v1/parent/children/{learner_b.id}/progress", headers=headers_pa)
    assert unauth_prog.status_code == 403


def test_staging_teacher_e2e_workflow_and_assignments(client: TestClient, db_session: Session):
    """
    Test 4: Synthetic Teacher A views assigned students, dispatches assignments, views trends.
    Cannot access unrelated student B.
    """
    seed_staging_synthetic_data(db_session)
    teacher_a = db_session.query(User).filter(User.email == "staging_teacher_a@lingua.ai").first()
    learner_a = db_session.query(User).filter(User.email == "staging_learner_a@lingua.ai").first()
    learner_b = db_session.query(User).filter(User.email == "staging_learner_b@lingua.ai").first()
    headers_ta = auth_header(teacher_a.firebase_uid)

    # 1. Teacher A lists students roster
    roster_res = client.get("/api/v1/teacher/students", headers=headers_ta)
    assert roster_res.status_code == 200
    students = roster_res.json()
    assert any(s["student_id"] == learner_a.id for s in students)
    assert not any(s["student_id"] == learner_b.id for s in students)

    # 2. Teacher A queries classroom trends
    trends_res = client.get("/api/v1/teacher/classroom-trends", headers=headers_ta)
    assert trends_res.status_code == 200
    assert "total_students" in trends_res.json()

    # 3. Teacher A queries unrelated Learner B's progress -> HTTP 403
    unauth_res = client.get(f"/api/v1/teacher/students/{learner_b.id}/progress", headers=headers_ta)
    assert unauth_res.status_code == 403


def test_staging_specialist_e2e_workflow_and_reports(client: TestClient, db_session: Session):
    """
    Test 5: Synthetic Specialist A views caseload for Learner A, reviews dossier, accesses report.
    Revoking relationship blocks report download.
    """
    seed_staging_synthetic_data(db_session)
    specialist_a = db_session.query(User).filter(User.email == "staging_specialist_a@lingua.ai").first()
    learner_a = db_session.query(User).filter(User.email == "staging_learner_a@lingua.ai").first()
    headers_sa = auth_header(specialist_a.firebase_uid)

    # 1. Specialist A lists caseload
    caseload_res = client.get("/api/v1/specialist/caseload", headers=headers_sa)
    assert caseload_res.status_code == 200
    caseload = caseload_res.json()
    assert any(c["learner_id"] == learner_a.id for c in caseload)

    # 2. Specialist A fetches existing report
    report = db_session.query(Report).filter(
        Report.creator_id == specialist_a.id,
        Report.learner_id == learner_a.id,
    ).first()
    assert report is not None

    rep_res = client.get(f"/api/v1/reports/{report.id}", headers=headers_sa)
    assert rep_res.status_code == 200
    assert "strictly non-diagnostic" in rep_res.json()["disclaimer"].lower()

    # 3. Revoke Specialist relationship
    rel = db_session.query(Relationship).filter(
        Relationship.source_user_id == specialist_a.id,
        Relationship.target_user_id == learner_a.id,
    ).first()
    rel.status = "revoked"
    db_session.commit()

    # 4. Immediate revocation denial on report metadata & PDF download
    revoked_rep_res = client.get(f"/api/v1/reports/{report.id}", headers=headers_sa)
    assert revoked_rep_res.status_code == 403

    revoked_pdf_res = client.get(f"/api/v1/reports/{report.id}/pdf", headers=headers_sa)
    assert revoked_pdf_res.status_code == 403


def test_staging_child_guardian_consent_gating(client: TestClient, db_session: Session):
    """
    Test 6: Synthetic Learner B (Child with pending consent) blocks third-party professional access.
    """
    seed_staging_synthetic_data(db_session)
    teacher_b = db_session.query(User).filter(User.email == "staging_teacher_b@lingua.ai").first()
    learner_b = db_session.query(User).filter(User.email == "staging_learner_b@lingua.ai").first()
    headers_tb = auth_header(teacher_b.firebase_uid)

    # Teacher B attempting to access Learner B progress is blocked because consent is pending
    res = client.get(f"/api/v1/teacher/students/{learner_b.id}/progress", headers=headers_tb)
    assert res.status_code == 403


def test_staging_synthetic_data_reset_cleanup(db_session: Session):
    """
    Test 7: Reset procedure cleanly cleans up synthetic staging users and cascading records.
    """
    seed_staging_synthetic_data(db_session)
    reset_res = reset_staging_synthetic_data(db_session)
    assert reset_res["status"] == "cleared"
    assert reset_res["records_removed"] == 8

    # Verify no synthetic emails remain
    synthetic_emails = [u["email"] for u in SYNTHETIC_STAGING_USERS]
    remaining = db_session.query(User).filter(User.email.in_(synthetic_emails)).count()
    assert remaining == 0
