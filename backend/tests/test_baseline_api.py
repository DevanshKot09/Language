import pytest
from fastapi.testclient import TestClient


def setup_learner(client: TestClient, token: str, age_band: str = "teen", support_focus: str = "dld_track"):
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/api/v1/auth/sync",
        headers=headers,
        json={"email": "learner@lingua.ai", "role": "learner"},
    )
    client.put(
        "/api/v1/profile/me",
        headers=headers,
        json={
            "display_name": "Test Learner",
            "age_band": age_band,
            "support_focus": support_focus,
        },
    )
    return headers


def test_baseline_session_flow(client: TestClient):
    headers = setup_learner(client, "valid_token_learner_flow", age_band="teen", support_focus="dld_track")

    # 1. Start baseline session
    start_resp = client.post("/api/v1/baseline/sessions", headers=headers)
    assert start_resp.status_code == 201
    session_data = start_resp.json()

    assert session_data["status"] == "in_progress"
    assert session_data["track"] == "dld_track"
    assert len(session_data["activities"]) > 0
    session_id = session_data["id"]

    # 2. Resuming returns same active session
    resume_resp = client.post("/api/v1/baseline/sessions", headers=headers)
    assert resume_resp.status_code == 201
    assert resume_resp.json()["id"] == session_id

    # 3. Retrieve session by ID
    get_resp = client.get(f"/api/v1/baseline/sessions/{session_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == session_id

    # 4. Submit responses to activities
    activities = session_data["activities"]
    first_act = activities[0]

    resp1 = client.post(
        f"/api/v1/baseline/sessions/{session_id}/responses",
        headers=headers,
        json={
            "activity_id": first_act["id"],
            "selected_option": first_act["options"][0],
            "time_taken_ms": 3200,
        },
    )
    assert resp1.status_code == 200
    res1_data = resp1.json()
    assert res1_data["completed_activities"] == 1
    assert "is_correct" in res1_data

    # Submit remaining activities
    for act in activities[1:]:
        client.post(
            f"/api/v1/baseline/sessions/{session_id}/responses",
            headers=headers,
            json={
                "activity_id": act["id"],
                "selected_option": act["options"][0],
                "time_taken_ms": 2500,
            },
        )

    # 5. Complete session
    complete_resp = client.post(f"/api/v1/baseline/sessions/{session_id}/complete", headers=headers)
    assert complete_resp.status_code == 200
    snapshot = complete_resp.json()
    assert snapshot["baseline_status"] == "completed"
    assert len(snapshot["skills"]) > 0

    # Ensure bands are strictly non-diagnostic
    valid_bands = {"Consistent", "Practicing", "Developing", "Starting"}
    for item in snapshot["skills"]:
        assert item["band"] in valid_bands
        assert 0.0 <= item["accuracy"] <= 1.0

    # 6. Retrieve Learner Skill Snapshot via GET /api/v1/learner/skill-snapshot
    snapshot_resp = client.get("/api/v1/learner/skill-snapshot", headers=headers)
    assert snapshot_resp.status_code == 200
    snapshot_data = snapshot_resp.json()
    assert snapshot_data["baseline_status"] == "completed"
    assert len(snapshot_data["skills"]) == len(snapshot["skills"])


def test_session_ownership_enforcement(client: TestClient):
    headers_a = setup_learner(client, "valid_token_learner_a")
    headers_b = setup_learner(client, "valid_token_learner_b")

    # Learner A creates a session
    sess_a = client.post("/api/v1/baseline/sessions", headers=headers_a).json()
    session_id_a = sess_a["id"]

    # Learner B attempts to view Learner A's session -> 403 Forbidden
    resp_get = client.get(f"/api/v1/baseline/sessions/{session_id_a}", headers=headers_b)
    assert resp_get.status_code == 403

    # Learner B attempts to submit response to Learner A's session -> 403 Forbidden
    resp_post = client.post(
        f"/api/v1/baseline/sessions/{session_id_a}/responses",
        headers=headers_b,
        json={
            "activity_id": sess_a["activities"][0]["id"],
            "selected_option": "test",
            "time_taken_ms": 1000,
        },
    )
    assert resp_post.status_code == 403

    # Learner B attempts to complete Learner A's session -> 403 Forbidden
    resp_complete = client.post(f"/api/v1/baseline/sessions/{session_id_a}/complete", headers=headers_b)
    assert resp_complete.status_code == 403


def test_learner_goals_flow(client: TestClient):
    headers = setup_learner(client, "valid_token_learner_goals")

    # 1. Initially no goals
    get_resp = client.get("/api/v1/learner/goals", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json() == []

    # 2. Create goal
    create_resp = client.post(
        "/api/v1/learner/goals",
        headers=headers,
        json={
            "title": "Practice vocabulary 3 times a week",
            "target_frequency": "weekly",
            "target_behavior": "Complete 1 vocabulary session on Mon, Wed, Fri",
        },
    )
    assert create_resp.status_code == 201
    goal = create_resp.json()
    assert goal["title"] == "Practice vocabulary 3 times a week"
    assert goal["status"] == "active"

    # 3. Retrieve goals
    get_resp2 = client.get("/api/v1/learner/goals", headers=headers)
    assert get_resp2.status_code == 200
    goals = get_resp2.json()
    assert len(goals) == 1
    assert goals[0]["id"] == goal["id"]

    # 4. Another learner cannot see this goal
    headers_other = setup_learner(client, "valid_token_learner_other")
    get_resp_other = client.get("/api/v1/learner/goals", headers=headers_other)
    assert get_resp_other.status_code == 200
    assert get_resp_other.json() == []
