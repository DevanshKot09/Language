import pytest
from fastapi.testclient import TestClient


def setup_learner(client: TestClient, token: str, age_band: str = "child", support_focus: str = "dld_track"):
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/api/v1/auth/sync",
        headers=headers,
        json={"email": f"{token}@lingua.ai", "role": "learner"},
    )
    client.put(
        "/api/v1/profile/",
        headers=headers,
        json={
            "display_name": "Practice Learner",
            "age_band": age_band,
            "support_focus": support_focus,
        },
    )
    return headers



def test_list_lessons_and_filtering(client: TestClient):
    headers = setup_learner(client, "valid_token_list_lessons", age_band="child", support_focus="dld_track")

    # 1. Get all lessons
    resp = client.get("/api/v1/lessons", headers=headers)
    assert resp.status_code == 200
    lessons = resp.json()
    assert len(lessons) >= 6

    # 2. Filter by track
    dld_resp = client.get("/api/v1/lessons?track=dld_track", headers=headers)
    assert dld_resp.status_code == 200
    dld_lessons = dld_resp.json()
    for l in dld_lessons:
        assert l["track"] in ("dld_track", "both_track")

    dys_resp = client.get("/api/v1/lessons?track=dyslexia_track", headers=headers)
    assert dys_resp.status_code == 200
    dys_lessons = dys_resp.json()
    for l in dys_lessons:
        assert l["track"] in ("dyslexia_track", "both_track")


def test_get_lesson_detail_hides_answers(client: TestClient):
    headers = setup_learner(client, "valid_token_detail", age_band="child", support_focus="dld_track")

    resp = client.get("/api/v1/lessons", headers=headers)
    lesson_id = resp.json()[0]["id"]

    detail_resp = client.get(f"/api/v1/lessons/{lesson_id}", headers=headers)
    assert detail_resp.status_code == 200
    data = detail_resp.json()
    assert "exercises" in data
    assert len(data["exercises"]) > 0

    # Ensure correct answers are NOT exposed to the client
    for ex in data["exercises"]:
        assert "correct_answer" not in ex
        assert "correct_answer_json" not in ex
        assert "content" in ex


def test_start_and_resume_lesson(client: TestClient):
    headers = setup_learner(client, "valid_token_start_resume", age_band="child")

    lessons = client.get("/api/v1/lessons", headers=headers).json()
    lesson_id = lessons[0]["id"]

    # Start lesson
    start_resp = client.post(f"/api/v1/lessons/{lesson_id}/start", headers=headers)
    assert start_resp.status_code == 200
    progress = start_resp.json()
    assert progress["status"] == "in_progress"
    assert progress["current_exercise_index"] == 0

    # Resume lesson returns same progress
    state_resp = client.get(f"/api/v1/lessons/{lesson_id}/state", headers=headers)
    assert state_resp.status_code == 200
    assert state_resp.json()["status"] == "in_progress"


def test_deterministic_exercise_evaluations(client: TestClient):
    headers = setup_learner(client, "valid_token_evals", age_band="child")

    lessons = client.get("/api/v1/lessons", headers=headers).json()

    # Find Everyday Action Words lesson
    dld_lesson = next(l for l in lessons if l["id"] == "lesson-dld-001")
    detail = client.get(f"/api/v1/lessons/{dld_lesson['id']}", headers=headers).json()
    exercises = detail["exercises"]

    # 1. Multiple choice: correct answer
    ex_mc = exercises[0]
    mc_resp = client.post(
        f"/api/v1/exercises/{ex_mc['id']}/attempt",
        headers=headers,
        json={"response": "To look around and discover new things", "attempt_number": 1},
    )
    assert mc_resp.status_code == 200
    data = mc_resp.json()
    assert data["is_correct"] is True
    assert data["status"] == "correct"
    assert data["partial_score"] == 1.0
    assert "Wonderful job!" in data["feedback_message"]

    # 2. Multiple choice: incorrect answer (allows retry without penalty)
    mc_wrong = client.post(
        f"/api/v1/exercises/{ex_mc['id']}/attempt",
        headers=headers,
        json={"response": "To sleep quietly in bed", "attempt_number": 2},
    )
    assert mc_wrong.status_code == 200
    wrong_data = mc_wrong.json()
    assert wrong_data["is_correct"] is False
    assert wrong_data["status"] == "incorrect"
    assert "Good try!" in wrong_data["feedback_message"]

    # 3. Matching exercise with partial correctness
    ex_matching = next(e for e in exercises if e["exercise_type"] == "matching")
    partial_match = client.post(
        f"/api/v1/exercises/{ex_matching['id']}/attempt",
        headers=headers,
        json={
            "response": {
                "soar": "to fly high in the air",  # correct
                "sprint": "wrong definition",       # incorrect
                "whisper": "to speak very softly", # correct
            },
            "attempt_number": 1,
        },
    )
    assert partial_match.status_code == 200
    pdata = partial_match.json()
    assert pdata["is_correct"] is False
    assert pdata["status"] == "partially_correct"
    assert pdata["partial_score"] == pytest.approx(0.67, 0.01)

    # 4. Word Order Exercise in sentence formation lesson
    sent_lesson = next(l for l in lessons if l["id"] == "lesson-dld-003")
    sent_detail = client.get(f"/api/v1/lessons/{sent_lesson['id']}", headers=headers).json()
    ex_word_order = next(e for e in sent_detail["exercises"] if e["exercise_type"] == "word_order")

    wo_correct = client.post(
        f"/api/v1/exercises/{ex_word_order['id']}/attempt",
        headers=headers,
        json={
            "response": ["The", "children", "built", "a", "tall", "sandcastle."],
            "attempt_number": 1,
        },
    )
    assert wo_correct.status_code == 200
    assert wo_correct.json()["is_correct"] is True
    assert wo_correct.json()["status"] == "correct"


def test_hint_usage_recorded_without_penalty(client: TestClient):
    headers = setup_learner(client, "valid_token_hint", age_band="child")

    lessons = client.get("/api/v1/lessons", headers=headers).json()
    dld_lesson = next(l for l in lessons if l["id"] == "lesson-dld-001")
    detail = client.get(f"/api/v1/lessons/{dld_lesson['id']}", headers=headers).json()
    ex = detail["exercises"][0]

    attempt_resp = client.post(
        f"/api/v1/exercises/{ex['id']}/attempt",
        headers=headers,
        json={
            "response": "To look around and discover new things",
            "attempt_number": 1,
            "hint_used": True,
        },
    )
    assert attempt_resp.status_code == 200
    # Score remains 1.0 even when hint is used (non-punitive design)
    assert attempt_resp.json()["partial_score"] == 1.0
    assert attempt_resp.json()["is_correct"] is True


def test_complete_lesson(client: TestClient):
    headers = setup_learner(client, "valid_token_complete", age_band="child")

    lessons = client.get("/api/v1/lessons", headers=headers).json()
    lesson_id = lessons[0]["id"]

    comp_resp = client.post(f"/api/v1/lessons/{lesson_id}/complete", headers=headers)
    assert comp_resp.status_code == 200
    data = comp_resp.json()
    assert data["status"] == "completed"
    assert data["completed_at"] is not None


def test_practice_hub_overview(client: TestClient):
    headers = setup_learner(client, "valid_token_hub", age_band="child", support_focus="dld_track")

    hub_resp = client.get("/api/v1/practice", headers=headers)
    assert hub_resp.status_code == 200
    data = hub_resp.json()
    assert "recommended_lessons" in data
    assert "in_progress_lessons" in data
    assert "completed_lessons" in data
    assert "skills_summary" in data
    assert len(data["skills_summary"]) > 0


def test_learning_path_with_real_lessons(client: TestClient):
    headers = setup_learner(client, "valid_token_path", age_band="child", support_focus="dld_track")

    path_resp = client.get("/api/v1/learning-path", headers=headers)
    assert path_resp.status_code == 200
    data = path_resp.json()
    assert "nodes" in data
    assert len(data["nodes"]) >= 5
    # First node should be active if none completed
    assert data["nodes"][0]["is_active"] is True


def test_unauthorized_requests(client: TestClient):
    assert client.get("/api/v1/lessons").status_code == 401
    assert client.get("/api/v1/practice").status_code == 401
    assert client.get("/api/v1/learning-path").status_code == 401


def test_safety_non_diagnostic_feedback(client: TestClient):
    """
    Strict safety check: ensure feedback messages never contain prohibited clinical or diagnostic vocabulary.
    """
    prohibited_terms = [
        "disorder", "dyslexia", "dld", "severity", "cured", "diagnosis",
        "diagnostic", "pathology", "handicap", "deficit", "abnormal", "behind"
    ]
    headers = setup_learner(client, "valid_token_safety", age_band="child")
    lessons = client.get("/api/v1/lessons", headers=headers).json()
    detail = client.get(f"/api/v1/lessons/{lessons[0]['id']}", headers=headers).json()
    ex = detail["exercises"][0]

    # Test incorrect feedback
    resp = client.post(
        f"/api/v1/exercises/{ex['id']}/attempt",
        headers=headers,
        json={"response": "wrong answer", "attempt_number": 1},
    )
    feedback = resp.json()["feedback_message"].lower()
    for term in prohibited_terms:
        assert term not in feedback, f"Prohibited clinical term '{term}' found in feedback message: {feedback}"

