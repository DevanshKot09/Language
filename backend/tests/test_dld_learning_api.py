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
            "display_name": "DLD Learner",
            "age_band": age_band,
            "support_focus": support_focus,
        },
    )
    return headers


def test_dld_lessons_retrieval_and_filtering(client: TestClient):
    """Verify that querying DLD lessons returns only DLD track lessons."""
    headers = setup_learner(client, "valid_token_dld_user_1", age_band="all", support_focus="dld_track")

    # 1. Fetch DLD track lessons
    response = client.get("/api/v1/lessons?track=dld_track", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 10

    for lesson in data:
        assert lesson["track"] in ("dld_track", "both_track")
        assert "dyslexia" not in lesson["track"].lower()


def test_dld_lessons_age_band_adaptation(client: TestClient):
    """Verify that Child, Teen, and Adult receive distinct age-appropriate DLD lessons."""
    headers = setup_learner(client, "valid_token_dld_age_user", age_band="all", support_focus="dld_track")

    # Child DLD lessons
    res_child = client.get("/api/v1/lessons?track=dld_track&age_band=child", headers=headers)
    assert res_child.status_code == 200
    child_lessons = res_child.json()
    assert len(child_lessons) >= 4
    for l in child_lessons:
        assert l["age_band"] in ("child", "all")
        assert l["difficulty"] in (1, 2)

    # Teen DLD lessons
    res_teen = client.get("/api/v1/lessons?track=dld_track&age_band=teen", headers=headers)
    assert res_teen.status_code == 200
    teen_lessons = res_teen.json()
    assert len(teen_lessons) >= 4
    for l in teen_lessons:
        assert l["age_band"] in ("teen", "all")
        assert l["difficulty"] in (1, 2, 3)

    # Adult DLD lessons
    res_adult = client.get("/api/v1/lessons?track=dld_track&age_band=adult", headers=headers)
    assert res_adult.status_code == 200
    adult_lessons = res_adult.json()
    assert len(adult_lessons) >= 4
    for l in adult_lessons:
        assert l["age_band"] in ("adult", "all")
        assert l["difficulty"] in (2, 3, 4)


def test_dld_listening_comprehension_exercise(client: TestClient):
    """Verify that listening comprehension exercises evaluate deterministically without voice processing."""
    headers = setup_learner(client, "valid_token_dld_listener", age_band="child", support_focus="dld_track")

    # Fetch child listening lesson
    detail_res = client.get("/api/v1/lessons/lesson-dld-006", headers=headers)
    assert detail_res.status_code == 200
    lesson = detail_res.json()
    assert lesson["title"] == "Following Two-Step Directions"

    # Start lesson
    start_res = client.post("/api/v1/lessons/lesson-dld-006/start", headers=headers)
    assert start_res.status_code == 200

    exercises = lesson["exercises"]
    assert len(exercises) >= 2
    ex1 = exercises[0]
    assert ex1["exercise_type"] == "listening_comprehension"
    assert "transcript" in ex1["content"]
    assert "options" in ex1["content"]

    # Submit correct choice
    correct_payload = {
        "response": "Wash hands with soap and water",
        "attempt_number": 1,
        "hint_used": False,
        "time_spent_ms": 3200,
    }
    att_res = client.post(f"/api/v1/exercises/{ex1['id']}/attempt", json=correct_payload, headers=headers)
    assert att_res.status_code == 200
    result = att_res.json()
    assert result["is_correct"] is True
    assert result["status"] == "correct"
    assert "Before" in result["explanation"]


def test_dld_social_communication_exercise(client: TestClient):
    """Verify that social communication and pragmatic choices evaluate deterministically."""
    headers = setup_learner(client, "valid_token_dld_pragmatics", age_band="teen", support_focus="dld_track")

    # Fetch teen pragmatics lesson
    detail_res = client.get("/api/v1/lessons/lesson-dld-012", headers=headers)
    assert detail_res.status_code == 200
    lesson = detail_res.json()
    assert lesson["title"] == "Conversational Context & Clarification"

    exercises = lesson["exercises"]
    ex1 = exercises[0]
    assert ex1["exercise_type"] == "social_communication"
    assert "scenario" in ex1["content"]

    # Submit collaborative, polite clarification
    valid_resp = {
        "response": "Could you please repeat the date for that deliverable? I want to make sure I noted it correctly.",
        "attempt_number": 1,
        "hint_used": False,
    }
    att_res = client.post(f"/api/v1/exercises/{ex1['id']}/attempt", json=valid_resp, headers=headers)
    assert att_res.status_code == 200
    eval_data = att_res.json()
    assert eval_data["is_correct"] is True
    assert eval_data["status"] == "correct"

    # Submit inappropriate hostile option -> evaluates to incorrect with non-shaming feedback
    bad_resp = {
        "response": "You talked way too fast, so I have no idea what you said.",
        "attempt_number": 2,
        "hint_used": True,
    }
    att_bad = client.post(f"/api/v1/exercises/{ex1['id']}/attempt", json=bad_resp, headers=headers)
    assert att_bad.status_code == 200
    bad_data = att_bad.json()
    assert bad_data["is_correct"] is False
    assert bad_data["status"] == "incorrect"
    assert "clinical" not in bad_data["feedback_message"].lower()
    assert "dld" not in bad_data["feedback_message"].lower()


def test_dld_non_diagnostic_safety_guard(client: TestClient):
    """Verify that DLD curriculum endpoints never return prohibited diagnostic language."""
    headers = setup_learner(client, "valid_token_dld_safety", age_band="adult", support_focus="dld_track")
    prohibited_terms = [
        "you have dld",
        "dld severity",
        "dld score",
        "dld diagnosis",
        "cured",
        "disorder improved",
        "clinical risk",
    ]

    response = client.get("/api/v1/lessons?track=dld_track", headers=headers)
    assert response.status_code == 200
    raw_text = response.text.lower()

    for term in prohibited_terms:
        assert term not in raw_text, f"Prohibited clinical term '{term}' found in DLD curriculum response"
