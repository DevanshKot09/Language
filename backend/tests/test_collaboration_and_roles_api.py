import pytest
import json
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.profile import Profile
from app.models.skill import Skill
from app.models.learning import Lesson
from app.models.ai import Recommendation
from app.models.collaboration import Relationship, RelationshipInvitation, Report


def auth_header(uid: str):
    return {"Authorization": f"Bearer valid_token_{uid}"}


def test_relationship_invitation_and_acceptance(client: TestClient, db_session: Session):
    # 1. Create Specialist and Learner
    specialist = User(firebase_uid="spec_user_1", email="specialist1@example.com", role="specialist", status="active")
    learner = User(firebase_uid="learner_user_1", email="learner1@example.com", role="learner", status="active")
    db_session.add_all([specialist, learner])
    db_session.commit()

    prof = Profile(user_id=learner.id, display_name="Alex Learner", age_band="teen", support_focus="dld_track")
    db_session.add(prof)
    db_session.commit()

    # 2. Specialist invites learner
    headers_spec = auth_header(specialist.firebase_uid)
    inv_res = client.post(
        "/api/v1/relationships/invitations",
        headers=headers_spec,
        json={
            "invitee_email": learner.email,
            "relationship_type": "specialist",
            "target_learner_id": learner.id,
            "organization": "Speech Horizons Clinic",
        },
    )
    assert inv_res.status_code == 201
    inv_data = inv_res.json()
    token = inv_data["invitation_token"]
    assert token is not None
    assert inv_data["status"] == "pending"

    # 3. Learner accepts invitation
    headers_learner = auth_header(learner.firebase_uid)
    accept_res = client.post(
        f"/api/v1/relationships/invitations/accept?token={token}",
        headers=headers_learner,
    )
    assert accept_res.status_code == 200
    rel_data = accept_res.json()
    assert rel_data["status"] == "active"
    assert rel_data["relationship_type"] == "specialist"
    assert rel_data["source_user_id"] == specialist.id
    assert rel_data["target_user_id"] == learner.id


def test_cross_user_isolation_without_relationship_denied(client: TestClient, db_session: Session):
    parent = User(firebase_uid="parent_user_isolated", email="parent_iso@example.com", role="parent", status="active")
    learner = User(firebase_uid="learner_user_isolated", email="learner_iso@example.com", role="learner", status="active")
    db_session.add_all([parent, learner])
    db_session.commit()

    headers = auth_header(parent.firebase_uid)

    # Attempt to access learner progress without active relationship -> 403 Forbidden
    res = client.get(f"/api/v1/parent/children/{learner.id}/progress", headers=headers)
    assert res.status_code == 403
    assert "authorized relationship" in res.json()["detail"].lower()


def test_revoked_relationship_immediately_denies_access(client: TestClient, db_session: Session):
    teacher = User(firebase_uid="teacher_rev_1", email="teacher_rev@example.com", role="teacher", status="active")
    student = User(firebase_uid="student_rev_1", email="student_rev@example.com", role="learner", status="active")
    db_session.add_all([teacher, student])
    db_session.commit()

    student_prof = Profile(user_id=student.id, display_name="Student Rev", age_band="teen", support_focus="dyslexia_track")
    db_session.add(student_prof)
    db_session.commit()

    # Active relationship initially
    rel = Relationship(
        source_user_id=teacher.id,
        target_user_id=student.id,
        relationship_type="teacher",
        status="active",
        permission_scope=json.dumps(["view_progress", "create_assignment"]),
        consent_status="verified",
    )
    db_session.add(rel)
    db_session.commit()

    headers = auth_header(teacher.firebase_uid)

    # 1. Access works while relationship is active
    res_ok = client.get(f"/api/v1/teacher/students/{student.id}/progress", headers=headers)
    assert res_ok.status_code == 200

    # 2. Revoke relationship
    del_res = client.delete(f"/api/v1/relationships/{rel.id}", headers=headers)
    assert del_res.status_code == 200
    assert del_res.json()["status"] == "revoked"

    # 3. Same request returns 403 Forbidden immediately
    res_blocked = client.get(f"/api/v1/teacher/students/{student.id}/progress", headers=headers)
    assert res_blocked.status_code == 403


def test_child_consent_pending_restricts_teacher_access(client: TestClient, db_session: Session):
    teacher = User(firebase_uid="teacher_consent_1", email="teacher_c@example.com", role="teacher", status="active")
    child = User(firebase_uid="child_consent_1", email="child_c@example.com", role="learner", status="active")
    db_session.add_all([teacher, child])
    db_session.commit()

    child_prof = Profile(
        user_id=child.id,
        display_name="Child Pending",
        age_band="child",
        support_focus="dld_track",
        guardian_consent_status="pending",
    )
    db_session.add(child_prof)
    db_session.commit()

    rel = Relationship(
        source_user_id=teacher.id,
        target_user_id=child.id,
        relationship_type="teacher",
        status="active",
        permission_scope=json.dumps(["view_progress"]),
        consent_status="pending",
    )
    db_session.add(rel)
    db_session.commit()

    headers = auth_header(teacher.firebase_uid)
    res = client.get(f"/api/v1/teacher/students/{child.id}/progress", headers=headers)
    assert res.status_code == 403
    assert "guardian consent is pending" in res.json()["detail"].lower()


def test_teacher_assignments_and_cohort_trends(client: TestClient, db_session: Session):
    teacher = User(firebase_uid="teacher_assign_1", email="teacher_a@example.com", role="teacher", status="active")
    student = User(firebase_uid="student_assign_1", email="student_a@example.com", role="learner", status="active")
    db_session.add_all([teacher, student])
    db_session.commit()

    prof = Profile(user_id=student.id, display_name="Sam Student", age_band="teen", support_focus="dld_track")
    db_session.add(prof)

    skill = db_session.query(Skill).first()
    if not skill:
        skill = Skill(name="Active Listening", domain="listening", track="dld_track")
        db_session.add(skill)
        db_session.commit()

    lesson = Lesson(
        skill_id=skill.id,
        title="Active Listening Lesson",
        description="Conversational practice",
        track="dld_track",
        age_band="teen",
        difficulty=1,
        active=True,
    )
    db_session.add(lesson)
    db_session.commit()

    rel = Relationship(
        source_user_id=teacher.id,
        target_user_id=student.id,
        relationship_type="teacher",
        status="active",
        permission_scope=json.dumps(["view_progress", "create_assignment"]),
        consent_status="verified",
    )
    db_session.add(rel)
    db_session.commit()

    headers = auth_header(teacher.firebase_uid)

    # 1. Create assignment
    assign_res = client.post(
        "/api/v1/teacher/assignments",
        headers=headers,
        json={
            "student_id": student.id,
            "lesson_id": lesson.id,
            "title": "Complete Active Listening",
            "instructions": "Practice exercises 1 through 3.",
        },
    )
    assert assign_res.status_code == 201
    assign_data = assign_res.json()
    assert assign_data["title"] == "Complete Active Listening"
    assert assign_data["status"] == "assigned"

    # 2. Query classroom trends
    trends_res = client.get("/api/v1/teacher/classroom-trends", headers=headers)
    assert trends_res.status_code == 200
    trends_data = trends_res.json()
    assert trends_data["total_students"] == 1
    assert trends_data["total_assignments_created"] == 1


def test_specialist_caseload_and_ai_review(client: TestClient, db_session: Session):
    specialist = User(firebase_uid="spec_rev_1", email="spec_rev@example.com", role="specialist", status="active")
    learner = User(firebase_uid="learner_rev_1", email="learner_rev@example.com", role="learner", status="active")
    db_session.add_all([specialist, learner])
    db_session.commit()

    prof = Profile(user_id=learner.id, display_name="Maya Learner", age_band="teen", support_focus="dld_track")
    db_session.add(prof)

    skill = db_session.query(Skill).first()
    if not skill:
        skill = Skill(name="Vocabulary Expansion", domain="vocabulary", track="dld_track")
        db_session.add(skill)
        db_session.commit()

    lesson = Lesson(
        skill_id=skill.id,
        title="Vocabulary Expansion",
        description="Word context lesson",
        track="dld_track",
        age_band="teen",
        difficulty=1,
        active=True,
    )
    db_session.add(lesson)
    db_session.commit()

    # AI recommendation
    rec = Recommendation(
        user_id=learner.id,
        lesson_id=lesson.id,
        operation="ai_personalized_recommendation",
        reason_code="practice_frequency",
        short_explanation="Recommended for vocabulary building",
        status="active",
        human_reviewed=False,
        human_status="none",
    )
    db_session.add(rec)

    rel = Relationship(
        source_user_id=specialist.id,
        target_user_id=learner.id,
        relationship_type="specialist",
        status="active",
        permission_scope=json.dumps(["view_profile", "create_goal", "review_ai_recommendations", "view_ai_recommendations"]),
        consent_status="verified",
    )
    db_session.add(rel)
    db_session.commit()

    headers = auth_header(specialist.firebase_uid)

    # 1. Caseload check
    caseload_res = client.get("/api/v1/specialist/caseload", headers=headers)
    assert caseload_res.status_code == 200
    assert len(caseload_res.json()) == 1

    # 2. Create specialist support goal
    goal_res = client.post(
        f"/api/v1/specialist/learners/{learner.id}/goals",
        headers=headers,
        json={
            "title": "Practice 4 Vocabulary Lessons",
            "description": "Guided clinic target",
            "goal_type": "complete_lessons",
            "target_count": 4,
        },
    )
    assert goal_res.status_code == 201
    goal_data = goal_res.json()
    assert "[Specialist Support Goal]" in goal_data["description"]

    # 3. Specialist reviews and modifies AI recommendation
    review_res = client.put(
        f"/api/v1/specialist/ai-recommendations/{rec.id}",
        headers=headers,
        json={
            "human_status": "approved",
        },
    )
    assert review_res.status_code == 200
    assert review_res.json()["human_status"] == "approved"
    assert review_res.json()["human_reviewed"] is True


def test_report_generation_and_pdf_download(client: TestClient, db_session: Session):
    specialist = User(firebase_uid="spec_report_1", email="spec_rep@example.com", role="specialist", status="active")
    learner = User(firebase_uid="learner_report_1", email="learner_rep@example.com", role="learner", status="active")
    db_session.add_all([specialist, learner])
    db_session.commit()

    prof = Profile(user_id=learner.id, display_name="Leo Learner", age_band="teen", support_focus="dyslexia_track")
    db_session.add(prof)
    db_session.commit()

    rel = Relationship(
        source_user_id=specialist.id,
        target_user_id=learner.id,
        relationship_type="specialist",
        status="active",
        permission_scope=json.dumps(["view_profile", "generate_support_report"]),
        consent_status="verified",
    )
    db_session.add(rel)
    db_session.commit()

    headers = auth_header(specialist.firebase_uid)

    # 1. Create Report
    rep_res = client.post(
        "/api/v1/reports",
        headers=headers,
        json={
            "learner_id": learner.id,
            "report_type": "specialist_summary",
            "title": "Quarterly Learning Support Summary",
        },
    )
    assert rep_res.status_code == 201
    rep_data = rep_res.json()
    report_id = rep_data["id"]
    assert "LINGUA AI" in rep_data["disclaimer"]
    assert "medical diagnosis" in rep_data["disclaimer"]

    # 2. Download PDF
    pdf_res = client.get(f"/api/v1/reports/{report_id}/pdf", headers=headers)
    assert pdf_res.status_code == 200
    assert pdf_res.headers["content-type"] == "application/pdf"
    assert len(pdf_res.content) > 500  # Valid non-empty PDF bytes


def test_role_escalation_denied(client: TestClient, db_session: Session):
    learner = User(firebase_uid="learner_escalate", email="learner_esc@example.com", role="learner", status="active")
    db_session.add(learner)
    db_session.commit()

    headers = auth_header(learner.firebase_uid)

    # Learner attempting specialist endpoint -> 403 Forbidden
    spec_res = client.get("/api/v1/specialist/caseload", headers=headers)
    assert spec_res.status_code == 403

    # Learner attempting teacher endpoint -> 403 Forbidden
    teach_res = client.get("/api/v1/teacher/students", headers=headers)
    assert teach_res.status_code == 403


def test_specialist_conversations_endpoint_and_consent_isolation(client: TestClient, db_session: Session):
    # 1. Create Specialist, Parent, Teacher, and Learner
    specialist = User(firebase_uid="spec_chat_1", email="spec_chat1@example.com", role="specialist", status="active")
    parent = User(firebase_uid="parent_chat_1", email="parent_chat1@example.com", role="parent", status="active")
    teacher = User(firebase_uid="teacher_chat_1", email="teacher_chat1@example.com", role="teacher", status="active")
    learner_aarav = User(firebase_uid="learner_aarav", email="aarav@example.com", role="learner", status="active")
    learner_sofia = User(firebase_uid="learner_sofia", email="sofia@example.com", role="learner", status="active")
    unrelated_specialist = User(firebase_uid="spec_unrelated", email="spec_unrelated@example.com", role="specialist", status="active")

    db_session.add_all([specialist, parent, teacher, learner_aarav, learner_sofia, unrelated_specialist])
    db_session.commit()

    db_session.add(Profile(user_id=specialist.id, display_name="Dr. Maya", age_band="adult", support_focus="dld_track"))
    db_session.add(Profile(user_id=parent.id, display_name="Priya Mehta", age_band="adult", support_focus="dld_track"))
    db_session.add(Profile(user_id=teacher.id, display_name="Mrs. Eleanor Davies", age_band="adult", support_focus="dld_track"))
    db_session.add(Profile(user_id=learner_aarav.id, display_name="Aarav Sharma", age_band="child", support_focus="dld_track", guardian_consent_status="verified"))
    db_session.add(Profile(user_id=learner_sofia.id, display_name="Sofia Patel", age_band="child", support_focus="dld_track", guardian_consent_status="pending"))
    db_session.commit()

    # Active relationships for Aarav
    rel_spec_aarav = Relationship(
        source_user_id=specialist.id,
        target_user_id=learner_aarav.id,
        relationship_type="specialist",
        status="active",
        permission_scope=json.dumps(["view_progress", "generate_support_report"]),
        consent_status="verified",
    )
    rel_parent_aarav = Relationship(
        source_user_id=parent.id,
        target_user_id=learner_aarav.id,
        relationship_type="parent",
        status="active",
        permission_scope=json.dumps(["manage_relationships"]),
        consent_status="verified",
    )
    rel_teacher_aarav = Relationship(
        source_user_id=teacher.id,
        target_user_id=learner_aarav.id,
        relationship_type="teacher",
        status="active",
        permission_scope=json.dumps(["view_progress", "create_assignment"]),
        consent_status="verified",
        organization="Oakridge Elementary",
    )

    # Active relationship for Sofia (but guardian consent is pending)
    rel_spec_sofia = Relationship(
        source_user_id=specialist.id,
        target_user_id=learner_sofia.id,
        relationship_type="specialist",
        status="active",
        permission_scope=json.dumps(["view_progress"]),
        consent_status="pending",
    )

    db_session.add_all([rel_spec_aarav, rel_parent_aarav, rel_teacher_aarav, rel_spec_sofia])
    db_session.commit()

    headers_spec = auth_header(specialist.firebase_uid)

    # 1. Query conversations for specialist
    res = client.get("/api/v1/specialist/conversations", headers=headers_spec)
    assert res.status_code == 200
    convs = res.json()
    assert len(convs) >= 3

    # Check Aarav's support circle
    aarav_conv = next(c for c in convs if "Aarav" in c["title"])
    assert aarav_conv["is_pinned"] is True
    assert aarav_conv["unread_count"] == 2
    assert "Parent" in aarav_conv["roles"]
    assert aarav_conv["avatar_type"] == "dual"

    # Check Sofia's circle (consent pending locked state)
    sofia_conv = next(c for c in convs if "Sofia" in c["title"])
    assert sofia_conv["is_locked"] is True
    assert sofia_conv["consent_status"] == "pending"
    assert "locked until guardian sign-off" in sofia_conv["lock_reason"].lower()

    # 2. Filter unread
    res_unread = client.get("/api/v1/specialist/conversations?filter=unread", headers=headers_spec)
    assert res_unread.status_code == 200
    unread_convs = res_unread.json()
    assert all(c["unread_count"] > 0 for c in unread_convs)

    # 3. Search by name
    res_search = client.get("/api/v1/specialist/conversations?search=Priya", headers=headers_spec)
    assert res_search.status_code == 200
    search_convs = res_search.json()
    assert any("Priya" in c["title"] for c in search_convs)

    # 4. Unrelated specialist sees zero conversations
    headers_unrelated = auth_header(unrelated_specialist.firebase_uid)
    res_empty = client.get("/api/v1/specialist/conversations", headers=headers_unrelated)
    assert res_empty.status_code == 200
    assert res_empty.json() == []

    # 5. Non-specialist role (e.g. learner) gets 403 Forbidden
    headers_learner = auth_header(learner_aarav.firebase_uid)
    res_forbidden = client.get("/api/v1/specialist/conversations", headers=headers_learner)
    assert res_forbidden.status_code == 403

    # 6. Retrieve conversation messages for Aarav
    res_msgs = client.get(f"/api/v1/specialist/conversations/{aarav_conv['id']}/messages", headers=headers_spec)
    assert res_msgs.status_code == 200
    msgs = res_msgs.json()
    assert len(msgs) >= 4
    # Outgoing specialist message has attachment
    spec_msg = next(m for m in msgs if m["is_self"] is True)
    assert spec_msg["sender_role"] == "specialist"
    assert spec_msg["attachment"] is not None
    assert "Phoneme_Pacing" in spec_msg["attachment"]["filename"]

    # 7. Send new specialist message
    send_res = client.post(
        f"/api/v1/specialist/conversations/{aarav_conv['id']}/messages",
        headers=headers_spec,
        json={"content": "Looking forward to tomorrow's session at 10:30 AM!"},
    )
    assert send_res.status_code == 201
    sent_data = send_res.json()
    assert sent_data["content"] == "Looking forward to tomorrow's session at 10:30 AM!"
    assert sent_data["is_self"] is True
    assert sent_data["delivery_status"] == "delivered"

    # Verify message is in the thread
    res_msgs_after = client.get(f"/api/v1/specialist/conversations/{aarav_conv['id']}/messages", headers=headers_spec)
    assert res_msgs_after.status_code == 200
    assert len(res_msgs_after.json()) == len(msgs) + 1

    # 8. Empty content returns 422
    empty_res = client.post(
        f"/api/v1/specialist/conversations/{aarav_conv['id']}/messages",
        headers=headers_spec,
        json={"content": "   "},
    )
    assert empty_res.status_code == 422

