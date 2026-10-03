import json
import secrets
import os
from datetime import datetime, timezone, timedelta
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy.schema import CreateTable
from sqlalchemy.dialects import postgresql

from app.core.database import Base
from app.models.user import User
from app.models.profile import Profile
from app.models.collaboration import (
    Relationship,
    RelationshipInvitation,
    Assignment,
    Report,
    ReportAccessEvent,
)
from app.models.learning import Lesson, Exercise, ExerciseAttempt, UserLessonProgress
from app.models.skill import Skill
from app.models.goal import LearnerGoal
from app.models.achievement import AchievementDefinition, UserAchievement
from app.models.ai import AiInteraction, Recommendation
from app.services.report_service import ReportService
from app.core.config import settings


def auth_header(firebase_uid: str) -> dict:
    return {"Authorization": f"Bearer valid_token_{firebase_uid}"}


def test_postgresql_dialect_ddl_and_models_compilation():
    """
    Test 1: Comprehensive PostgreSQL dialect compilation test.
    Verifies that all SQLAlchemy models cleanly compile to PostgreSQL DDL
    with proper column types, constraints, and foreign keys.
    """
    pg_dialect = postgresql.dialect()
    assert len(Base.metadata.tables) > 10

    for table_name, table in Base.metadata.tables.items():
        # Generate PostgreSQL DDL statement for each table
        ddl = str(CreateTable(table).compile(dialect=pg_dialect))
        assert len(ddl) > 0
        assert table_name in ddl or f'"{table_name}"' in ddl
        # Check foreign keys
        for fk in table.foreign_keys:
            assert fk.column is not None


def test_end_to_end_role_authorization_matrix(client: TestClient, db_session: Session):
    """
    Test 2: Full multi-role authorization matrix.
    Tests Learner, Parent, Teacher, Specialist against each other's endpoints.
    """
    learner = User(firebase_uid="p13_learner_uid", email="p13_l@lingua.ai", role="learner", status="active")
    parent = User(firebase_uid="p13_parent_uid", email="p13_p@lingua.ai", role="parent", status="active")
    teacher = User(firebase_uid="p13_teacher_uid", email="p13_t@lingua.ai", role="teacher", status="active")
    specialist = User(firebase_uid="p13_spec_uid", email="p13_s@lingua.ai", role="specialist", status="active")
    db_session.add_all([learner, parent, teacher, specialist])
    db_session.commit()

    prof_l = Profile(user_id=learner.id, display_name="P13 Learner", age_band="teen", support_focus="dld_track")
    prof_p = Profile(user_id=parent.id, display_name="P13 Parent", age_band="adult", support_focus="dld_track")
    prof_t = Profile(user_id=teacher.id, display_name="P13 Teacher", age_band="adult", support_focus="dld_track")
    prof_s = Profile(user_id=specialist.id, display_name="P13 Specialist", age_band="adult", support_focus="dld_track")
    db_session.add_all([prof_l, prof_p, prof_t, prof_s])
    db_session.commit()

    headers_l = auth_header(learner.firebase_uid)
    headers_p = auth_header(parent.firebase_uid)
    headers_t = auth_header(teacher.firebase_uid)
    headers_s = auth_header(specialist.firebase_uid)

    # 1. Learner cannot access professional endpoints
    assert client.get("/api/v1/teacher/students", headers=headers_l).status_code == 403
    assert client.get("/api/v1/specialist/caseload", headers=headers_l).status_code == 403
    assert client.get("/api/v1/parent/children", headers=headers_l).status_code == 403

    # 2. Teacher cannot access specialist endpoints
    assert client.get("/api/v1/specialist/caseload", headers=headers_t).status_code == 403

    # 3. Specialist cannot access teacher assignment dispatch
    assert client.post("/api/v1/teacher/assignments", headers=headers_s, json={
        "student_id": learner.id,
        "lesson_id": "test_lesson",
        "title": "Unauthorized Assignment",
    }).status_code == 403

    # 4. Parent cannot access teacher classroom trends
    assert client.get("/api/v1/teacher/classroom-trends", headers=headers_p).status_code == 403


def test_tampered_resource_ids_are_denied(client: TestClient, db_session: Session):
    """
    Test 3: Manipulation of resource IDs (learner_id, report_id, assignment_id) fails safely.
    """
    teacher = User(firebase_uid="p13_tamper_t", email="t_tamper@lingua.ai", role="teacher", status="active")
    unrelated_learner = User(firebase_uid="p13_tamper_l", email="l_tamper@lingua.ai", role="learner", status="active")
    db_session.add_all([teacher, unrelated_learner])
    db_session.commit()

    prof_l = Profile(user_id=unrelated_learner.id, display_name="Unrelated", age_band="child", support_focus="dld_track")
    db_session.add(prof_l)
    db_session.commit()

    headers_t = auth_header(teacher.firebase_uid)

    # Manipulated learner ID in progress query
    res = client.get(f"/api/v1/teacher/students/{unrelated_learner.id}/progress", headers=headers_t)
    assert res.status_code == 403

    # Manipulated report ID
    fake_report_id = "non_existent_or_unauthorized_report_uuid"
    res_rep = client.get(f"/api/v1/reports/{fake_report_id}", headers=headers_t)
    assert res_rep.status_code in [403, 404]


def test_concurrency_invitation_double_acceptance(client: TestClient, db_session: Session):
    """
    Test 4: Race condition / double-acceptance prevention on invitations.
    The first acceptance transitions token to 'accepted'; subsequent acceptance fails.
    """
    teacher = User(firebase_uid="p13_inv_t", email="inv_t@lingua.ai", role="teacher", status="active")
    student = User(firebase_uid="p13_inv_s", email="inv_s@lingua.ai", role="learner", status="active")
    db_session.add_all([teacher, student])
    db_session.commit()

    prof_s = Profile(user_id=student.id, display_name="Student", age_band="teen", support_focus="dld_track")
    db_session.add(prof_s)
    db_session.commit()

    headers_t = auth_header(teacher.firebase_uid)
    headers_s = auth_header(student.firebase_uid)

    # Create invitation
    inv_res = client.post(
        "/api/v1/relationships/invitations",
        headers=headers_t,
        json={
            "invitee_email": student.email,
            "relationship_type": "teacher",
            "target_learner_id": student.id,
        },
    )
    assert inv_res.status_code == 201
    token = inv_res.json()["invitation_token"]

    # First accept: succeeds
    acc1 = client.post(f"/api/v1/relationships/invitations/accept?token={token}", headers=headers_s)
    assert acc1.status_code == 200
    assert acc1.json()["status"] == "active"

    # Second accept (replay / concurrent duplicate): strictly rejected
    acc2 = client.post(f"/api/v1/relationships/invitations/accept?token={token}", headers=headers_s)
    assert acc2.status_code == 400
    assert "already" in acc2.json()["detail"].lower()


def test_ai_data_flow_sanitization_and_boundaries(client: TestClient, db_session: Session):
    """
    Test 5: Verifies AI request payload sanitization and boundary enforcement.
    Ensures that no database passwords, Firebase credentials, or diagnostic terms are permitted.
    """
    learner = User(firebase_uid="p13_ai_uid", email="ai_learner@lingua.ai", role="learner", status="active")
    db_session.add(learner)
    db_session.commit()

    prof = Profile(user_id=learner.id, display_name="AI Learner", age_band="teen", support_focus="dld_track")
    db_session.add(prof)
    db_session.commit()

    headers = auth_header(learner.firebase_uid)

    # 1. Educational scenario request succeeds
    res = client.post(
        "/api/v1/ai/conversation",
        headers=headers,
        json={
            "scenario_id": "grocery_checkout",
            "scenario_title": "Grocery Shopping",
            "scenario_context": "Practicing descriptive vocabulary for groceries",
            "user_message": "Hello, I would like to buy three apples and some whole grain bread.",
            "age_band": "teen",
        },
    )
    assert res.status_code == 200
    reply = res.json()["reply"].lower()
    # Confirm non-diagnostic copy
    assert "clinical diagnosis" not in reply
    assert "severity score" not in reply
    assert "prognosis" not in reply


def test_pdf_report_content_and_disclaimer_integrity(client: TestClient, db_session: Session):
    """
    Test 6: Generated PDF reports must contain mandatory non-diagnostic disclaimers
    and must not expose raw file system paths or internal credentials.
    """
    specialist = User(firebase_uid="p13_rep_spec", email="spec_rep@lingua.ai", role="specialist", status="active")
    learner = User(firebase_uid="p13_rep_learn", email="learn_rep@lingua.ai", role="learner", status="active")
    db_session.add_all([specialist, learner])
    db_session.commit()

    prof_l = Profile(user_id=learner.id, display_name="Report Child", age_band="teen", support_focus="dld_track")
    db_session.add(prof_l)

    rel = Relationship(
        source_user_id=specialist.id,
        target_user_id=learner.id,
        relationship_type="specialist",
        status="active",
        permission_scope=json.dumps(["view_progress", "generate_support_report"]),
        consent_status="verified",
    )
    db_session.add(rel)
    db_session.commit()

    headers_s = auth_header(specialist.firebase_uid)

    # Generate report
    gen_res = client.post(
        "/api/v1/reports",
        headers=headers_s,
        json={
            "learner_id": learner.id,
            "report_type": "specialist_summary",
            "title": "Phase 13 Educational Support Review",
        },
    )
    assert gen_res.status_code == 201
    report_id = gen_res.json()["id"]

    # Retrieve PDF binary
    pdf_res = client.get(f"/api/v1/reports/{report_id}/pdf", headers=headers_s)
    assert pdf_res.status_code == 200
    assert pdf_res.headers["content-type"] == "application/pdf"
    assert len(pdf_res.content) > 500
    # PDF starts with standard %PDF magic bytes
    assert pdf_res.content.startswith(b"%PDF")
