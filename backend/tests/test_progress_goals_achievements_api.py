import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.profile import Profile
from app.models.skill import Skill
from app.models.learning import Lesson, Exercise, ExerciseAttempt, UserLessonProgress
from app.models.goal import LearnerGoal
from app.models.achievement import AchievementDefinition, UserAchievement
from app.services.achievement_service import AchievementService


def create_test_user(db: Session, uid: str, track: str = "both_track", age_band: str = "teen") -> User:
    user = User(
        firebase_uid=uid,
        email=f"{uid}@lingua.ai",
        role="learner",
        status="active",
    )
    db.add(user)
    db.flush()

    profile = Profile(
        user_id=user.id,
        display_name=f"Learner {uid}",
        age_band=age_band,
        support_focus=track,
        baseline_status="completed",
    )
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user


def auth_header(uid: str):
    return {"Authorization": f"Bearer valid_token_{uid}"}


def test_progress_empty_state(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-empty-progress")
    response = client.get("/api/v1/progress", headers=auth_header(user.firebase_uid))

    assert response.status_code == 200
    data = response.json()
    assert data["summary"]["total_lessons_completed"] == 0
    assert data["summary"]["total_exercises_attempted"] == 0
    assert data["summary"]["independent_rate"] == 100.0
    assert len(data["skills"]) > 0
    assert data["trend"]["accessible_description"] is not None
    assert "no recorded activities" in data["trend"]["accessible_description"].lower() or "0" in data["trend"]["accessible_description"]


def test_progress_numeric_integrity(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-numeric-integrity")

    # Fetch 2 real seeded lessons
    lessons = db_session.query(Lesson).filter(Lesson.active == True).limit(2).all()
    assert len(lessons) >= 2

    # Simulate completed lessons in database
    now = datetime.now(timezone.utc)
    for l in lessons:
        prog = UserLessonProgress(
            user_id=user.id,
            lesson_id=l.id,
            current_exercise_index=len(l.exercises),
            status="completed",
            completed_at=now,
            last_attempted_at=now,
        )
        db_session.add(prog)

        # Add 2 attempts per lesson
        for ex in l.exercises[:2]:
            att = ExerciseAttempt(
                user_id=user.id,
                exercise_id=ex.id,
                lesson_id=l.id,
                response_json='{"answer": "test"}',
                is_correct=True,
                partial_score=1.0,
                attempt_number=1,
                time_spent_ms=15000,
                hint_used=False,
                created_at=now,
            )
            db_session.add(att)

    db_session.commit()

    # Query API
    response = client.get("/api/v1/progress", headers=auth_header(user.firebase_uid))
    assert response.status_code == 200
    data = response.json()

    # Verify exact numeric matches with DB counts
    assert data["summary"]["total_lessons_completed"] == 2
    assert data["summary"]["total_exercises_attempted"] == 4
    assert data["summary"]["independent_rate"] == 100.0
    assert data["summary"]["consistency_streak_days"] == 1


def test_track_isolation(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-track-isolation", track="both_track")
    response = client.get("/api/v1/progress", headers=auth_header(user.firebase_uid))
    assert response.status_code == 200
    data = response.json()

    # DLD skills must only be dld_track
    for s in data["dld_skills"]:
        assert s["track"] == "dld_track"

    # Dyslexia skills must only be dyslexia_track
    for s in data["dyslexia_skills"]:
        assert s["track"] == "dyslexia_track"

    # Track summaries must remain separate
    assert data["dld_track_summary"]["track"] == "dld_track"
    assert data["dyslexia_track_summary"]["track"] == "dyslexia_track"


def test_non_diagnostic_terminology_safety(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-safety-terms")
    response = client.get("/api/v1/progress", headers=auth_header(user.firebase_uid))
    assert response.status_code == 200
    text_content = response.text.lower()

    prohibited_terms = [
        "dld severity",
        "dyslexia severity",
        "dld score",
        "dyslexia score",
        "clinical score",
        "risk score",
        "diagnostic improvement",
        "clinical progress",
        "disorder improvement",
        "disorder worsening",
    ]
    for term in prohibited_terms:
        assert term not in text_content, f"Prohibited clinical term found: {term}"

    # Verify descriptive bands adhere to allowed educational bands
    data = response.json()
    allowed_bands = {"starting", "developing", "practicing", "consistent"}
    for skill in data["skills"]:
        assert skill["current_band"] in allowed_bands


def test_goal_crud_and_target_validation(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-goal-crud")

    # 1. Validation failure: target_count <= 0
    bad_req = {
        "title": "Invalid Goal",
        "target_count": 0,
        "goal_type": "complete_lessons",
    }
    res_bad = client.post("/api/v1/goals", json=bad_req, headers=auth_header(user.firebase_uid))
    assert res_bad.status_code == 422

    # 2. Validation failure: nonexistent skill
    bad_skill_req = {
        "title": "Invalid Skill Goal",
        "target_count": 3,
        "skill_id": "nonexistent-skill-id-12345",
    }
    res_skill_bad = client.post("/api/v1/goals", json=bad_skill_req, headers=auth_header(user.firebase_uid))
    assert res_skill_bad.status_code == 400

    # 3. Successful goal creation
    skill = db_session.query(Skill).first()
    create_req = {
        "title": "Practice Vocabulary 3 Times",
        "description": "Building word depth and everyday communication",
        "skill_id": skill.id if skill else None,
        "goal_type": "practice_skill",
        "target_count": 3,
        "target_frequency": "weekly",
    }
    res_create = client.post("/api/v1/goals", json=create_req, headers=auth_header(user.firebase_uid))
    assert res_create.status_code == 201
    goal_data = res_create.json()
    assert goal_data["title"] == "Practice Vocabulary 3 Times"
    assert goal_data["current_count"] == 0
    assert goal_data["target_count"] == 3
    assert goal_data["status"] == "active"
    goal_id = goal_data["id"]

    # 4. Read goal
    res_get = client.get(f"/api/v1/goals/{goal_id}", headers=auth_header(user.firebase_uid))
    assert res_get.status_code == 200
    assert res_get.json()["id"] == goal_id

    # 5. Update goal
    update_req = {
        "title": "Practice Vocabulary 4 Times",
        "target_count": 4,
    }
    res_put = client.put(f"/api/v1/goals/{goal_id}", json=update_req, headers=auth_header(user.firebase_uid))
    assert res_put.status_code == 200
    assert res_put.json()["target_count"] == 4
    assert res_put.json()["title"] == "Practice Vocabulary 4 Times"

    # 6. Delete goal
    res_del = client.delete(f"/api/v1/goals/{goal_id}", headers=auth_header(user.firebase_uid))
    assert res_del.status_code == 204

    # Confirm deletion
    res_check = client.get(f"/api/v1/goals/{goal_id}", headers=auth_header(user.firebase_uid))
    assert res_check.status_code == 404


def test_goal_ownership_isolation(client: TestClient, db_session: Session):
    user_a = create_test_user(db_session, "user-a-owner")
    user_b = create_test_user(db_session, "user-b-intruder")

    # User A creates a goal
    create_req = {
        "title": "Learner A Personal Goal",
        "target_count": 2,
        "goal_type": "complete_lessons",
    }
    res = client.post("/api/v1/goals", json=create_req, headers=auth_header(user_a.firebase_uid))
    assert res.status_code == 201
    goal_id = res.json()["id"]

    # User B attempts to access User A's goal -> 403 Forbidden
    res_get = client.get(f"/api/v1/goals/{goal_id}", headers=auth_header(user_b.firebase_uid))
    assert res_get.status_code == 403

    # User B attempts to update User A's goal -> 403 Forbidden
    res_put = client.put(f"/api/v1/goals/{goal_id}", json={"title": "Hacked"}, headers=auth_header(user_b.firebase_uid))
    assert res_put.status_code == 403

    # User B attempts to delete User A's goal -> 403 Forbidden
    res_del = client.delete(f"/api/v1/goals/{goal_id}", headers=auth_header(user_b.firebase_uid))
    assert res_del.status_code == 403


def test_goal_progress_auto_increment(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-goal-progress")

    # User creates goal: complete 2 lessons
    create_req = {
        "title": "Complete 2 Lessons",
        "target_count": 2,
        "goal_type": "complete_lessons",
    }
    res = client.post("/api/v1/goals", json=create_req, headers=auth_header(user.firebase_uid))
    goal_id = res.json()["id"]

    # Complete 1st lesson
    lesson1 = db_session.query(Lesson).first()
    client.post(f"/api/v1/lessons/{lesson1.id}/complete", headers=auth_header(user.firebase_uid))

    goal_check_1 = client.get(f"/api/v1/goals/{goal_id}", headers=auth_header(user.firebase_uid)).json()
    assert goal_check_1["current_count"] == 1
    assert goal_check_1["status"] == "active"

    # Complete 2nd lesson
    lesson2 = db_session.query(Lesson).offset(1).first()
    client.post(f"/api/v1/lessons/{lesson2.id}/complete", headers=auth_header(user.firebase_uid))

    goal_check_2 = client.get(f"/api/v1/goals/{goal_id}", headers=auth_header(user.firebase_uid)).json()
    assert goal_check_2["current_count"] == 2
    assert goal_check_2["status"] == "completed"
    assert goal_check_2["completed_at"] is not None


def test_achievements_deterministic_evaluation(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-achievements-flow")

    # Initially 0 unlocked achievements
    res_init = client.get("/api/v1/achievements", headers=auth_header(user.firebase_uid))
    assert res_init.status_code == 200
    achs = res_init.json()
    assert len(achs) >= 8
    assert all(not a["is_unlocked"] for a in achs)

    # Complete 1 lesson
    lesson = db_session.query(Lesson).first()
    client.post(f"/api/v1/lessons/{lesson.id}/complete", headers=auth_header(user.firebase_uid))

    # Re-check achievements
    res_after = client.get("/api/v1/achievements", headers=auth_header(user.firebase_uid))
    achs_after = res_after.json()
    first_lesson_ach = next(a for a in achs_after if a["code"] == "first_lesson")
    assert first_lesson_ach["is_unlocked"] is True
    assert first_lesson_ach["unlocked_at"] is not None
    assert first_lesson_ach["badge_tier"] == "bronze"

    # Trigger evaluation again: duplicate must be prevented
    newly_unlocked = AchievementService.evaluate_and_unlock(db_session, user.id)
    assert len(newly_unlocked) == 0

    user_ach_records = db_session.query(UserAchievement).filter(UserAchievement.user_id == user.id).all()
    assert len(user_ach_records) == 1


def test_timeline_chronological_order_and_privacy(client: TestClient, db_session: Session):
    user = create_test_user(db_session, "user-timeline-test")

    # Create goal, complete lesson
    client.post(
        "/api/v1/goals",
        json={"title": "Explore Reading", "target_count": 1, "goal_type": "complete_lessons"},
        headers=auth_header(user.firebase_uid),
    )
    lesson = db_session.query(Lesson).first()
    client.post(f"/api/v1/lessons/{lesson.id}/complete", headers=auth_header(user.firebase_uid))

    res = client.get("/api/v1/progress/timeline", headers=auth_header(user.firebase_uid))
    assert res.status_code == 200
    events = res.json()
    assert len(events) >= 2

    # Events must be chronologically descending
    timestamps = [datetime.fromisoformat(e["timestamp"]) for e in events]
    for i in range(len(timestamps) - 1):
        assert timestamps[i] >= timestamps[i + 1]

    # Privacy check: Ensure no raw tokens, UIDs, audio file paths, or prompt JSONs
    raw_text = res.text
    assert "firebase_uid" not in raw_text
    assert "user_id" not in raw_text
    assert "audio_path" not in raw_text
    assert "prompt_text" not in raw_text
