import pytest
from fastapi.testclient import TestClient


def setup_user(client: TestClient, token: str = "valid_token_learner1"):
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/api/v1/auth/sync",
        headers=headers,
        json={"email": "learner1@lingua.ai", "role": "learner"},
    )
    return headers


def test_get_skills_unauthenticated(client: TestClient):
    response = client.get("/api/v1/skills/")
    assert response.status_code == 401


def test_get_skills_authenticated(client: TestClient):
    headers = setup_user(client)
    response = client.get("/api/v1/skills/", headers=headers)
    assert response.status_code == 200

    skills = response.json()
    assert len(skills) >= 10

    # Ensure separation between DLD and Dyslexia tracks
    dld_skills = [s for s in skills if s["track"] == "dld_track"]
    dyslexia_skills = [s for s in skills if s["track"] == "dyslexia_track"]

    assert len(dld_skills) >= 5
    assert len(dyslexia_skills) >= 5

    # Check required fields
    for s in skills:
        assert "id" in s
        assert "code" in s
        assert "name" in s
        assert "description" in s
        assert "track" in s
        assert "domain" in s


def test_filter_skills_by_track(client: TestClient):
    headers = setup_user(client)
    response = client.get("/api/v1/skills/?track=dld_track", headers=headers)
    assert response.status_code == 200
    skills = response.json()
    assert len(skills) >= 5
    for s in skills:
        assert s["track"] == "dld_track"


def test_get_skill_by_id(client: TestClient):
    headers = setup_user(client)
    list_resp = client.get("/api/v1/skills/", headers=headers)
    first_skill = list_resp.json()[0]

    response = client.get(f"/api/v1/skills/{first_skill['id']}", headers=headers)
    assert response.status_code == 200
    skill = response.json()
    assert skill["id"] == first_skill["id"]
    assert skill["code"] == first_skill["code"]


def test_get_nonexistent_skill(client: TestClient):
    headers = setup_user(client)
    response = client.get("/api/v1/skills/non-existent-skill-id", headers=headers)
    assert response.status_code == 404

