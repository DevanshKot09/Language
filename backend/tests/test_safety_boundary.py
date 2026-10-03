import json
import pytest
from fastapi.testclient import TestClient
from tests.test_baseline_api import setup_learner

PROHIBITED_TERMS = [
    "diagnosis",
    "diagnosed",
    "you have dyslexia",
    "you have dld",
    "clinical severity",
    "medical diagnosis",
    "dyslexia probability",
    "dld probability",
    "medical risk",
    "clinical score",
    "disorder classification",
]


def check_for_prohibited_terms(payload, context: str):
    dumped = json.dumps(payload).lower()
    for term in PROHIBITED_TERMS:
        assert term not in dumped, f"Safety violation: Prohibited diagnostic term '{term}' found in {context}: {dumped}"


def test_safety_boundary_on_skills_and_baseline(client: TestClient):
    headers = setup_learner(client, "valid_token_safety_learner")

    # 1. Check skills taxonomy response
    skills_resp = client.get("/api/v1/skills/", headers=headers)
    assert skills_resp.status_code == 200
    check_for_prohibited_terms(skills_resp.json(), "Skills Taxonomy")

    # 2. Check baseline session response
    session_resp = client.post("/api/v1/baseline/sessions", headers=headers)
    assert session_resp.status_code == 201
    check_for_prohibited_terms(session_resp.json(), "Baseline Session")

    # 3. Check baseline activities
    activities = session_resp.json()["activities"]
    check_for_prohibited_terms(activities, "Baseline Activities")

    # 4. Submit all answers and complete
    session_id = session_resp.json()["id"]
    for act in activities:
        resp = client.post(
            f"/api/v1/baseline/sessions/{session_id}/responses",
            headers=headers,
            json={
                "activity_id": act["id"],
                "selected_option": act["options"][0],
                "time_taken_ms": 2000,
            },
        )
        assert resp.status_code == 200
        check_for_prohibited_terms(resp.json(), f"Activity Response {act['id']}")

    complete_resp = client.post(f"/api/v1/baseline/sessions/{session_id}/complete", headers=headers)
    assert complete_resp.status_code == 200
    check_for_prohibited_terms(complete_resp.json(), "Baseline Completion / Skill Snapshot")

    # 5. Check Learner Snapshot endpoint
    snapshot_resp = client.get("/api/v1/learner/skill-snapshot", headers=headers)
    assert snapshot_resp.status_code == 200
    check_for_prohibited_terms(snapshot_resp.json(), "Learner Skill Snapshot")
