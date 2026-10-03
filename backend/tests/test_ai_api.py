import pytest
from fastapi.testclient import TestClient
from app.main import app


def setup_test_learner(client: TestClient, token: str = "valid_token_ai_user"):
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/api/v1/auth/sync",
        headers=headers,
        json={"email": f"{token}@lingua.ai", "role": "learner"},
    )
    return headers


def test_ai_status_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    response = client.get("/api/v1/ai/status", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "ai_enabled" in data
    assert "provider" in data
    assert data["safety_guardrails"] == "enforced"
    assert data["diagnostic_processing"] == "prohibited"


def test_ai_recommendations_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    payload = {
        "user_id": "test-user-id",
        "track": "dld_track",
        "age_band": "teen",
        "candidate_lesson_ids": ["lesson-dld-001", "lesson-dld-002"],
        "recent_completed_lesson_ids": [],
        "current_goals": ["Grammar"],
    }
    response = client.post("/api/v1/ai/recommendations", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "recommendations" in data
    assert len(data["recommendations"]) > 0
    # Must only contain IDs from candidates
    for rec in data["recommendations"]:
        assert rec["lesson_id"] in payload["candidate_lesson_ids"]


def test_ai_explanation_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    payload = {
        "lesson_title": "Relative Pronouns",
        "exercise_prompt": "Join the sentences with 'who'.",
        "target_concept": "Relative clauses",
        "learner_question": "Why do we use who instead of which?",
        "age_band": "teen",
    }
    response = client.post("/api/v1/ai/explanations", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "explanation" in data
    assert len(data["explanation"]) > 0


def test_ai_feedback_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    payload = {
        "activity_type": "writing",
        "prompt": "Describe your morning routine.",
        "learner_submission": "I wake up and brush my teeth then eat breakfast.",
        "age_band": "child",
        "track": "dld_track",
    }
    response = client.post("/api/v1/ai/feedback", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "clarity_note" in data
    assert "encouragement" in data


def test_ai_conversation_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    payload = {
        "scenario_id": "sc-1",
        "scenario_title": "Asking for Clarification",
        "scenario_context": "You did not hear which page the teacher mentioned.",
        "age_band": "teen",
        "history": [],
        "user_message": "Excuse me, which page are we working on?",
    }
    response = client.post("/api/v1/ai/conversation", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "reply" in data
    assert len(data["reply"]) > 0


def test_ai_progress_insight_endpoint(client: TestClient):
    headers = setup_test_learner(client)
    payload = {
        "age_band": "adult",
        "track": "dld_track",
        "completed_lesson_count": 5,
        "practice_attempt_count": 12,
        "active_goals": ["Pragmatics"],
        "recent_skills": ["Clarification requests"],
    }
    response = client.post("/api/v1/ai/progress-insight", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "practice_summary" in data
    assert "what_went_well" in data
