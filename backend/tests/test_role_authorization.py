from fastapi import APIRouter, Depends
from app.api.deps import require_role
from app.models.user import User

test_router = APIRouter()


@test_router.get("/specialist-only")
def specialist_only_endpoint(user: User = Depends(require_role(["specialist"]))):
    return {"message": "Welcome specialist"}


def test_role_authorization_enforcement(client):
    # Register test route dynamically for role check
    client.app.include_router(test_router, prefix="/api/v1/test")

    # 1. Create a learner account via Firebase sync
    learner_headers = {"Authorization": "Bearer valid_token_learner_uid_601"}
    client.post(
        "/api/v1/auth/sync",
        headers=learner_headers,
        json={
            "role": "learner",
            "terms_acknowledged": True,
            "non_diagnostic_acknowledged": True,
        },
    )

    # Learner should be denied access to specialist-only route (403 Forbidden)
    res_denied = client.get(
        "/api/v1/test/specialist-only",
        headers=learner_headers,
    )
    assert res_denied.status_code == 403
    assert "permission" in res_denied.json()["detail"].lower()

    # 2. Create a specialist account via Firebase sync
    spec_headers = {"Authorization": "Bearer valid_token_specialist_uid_701"}
    client.post(
        "/api/v1/auth/sync",
        headers=spec_headers,
        json={
            "role": "specialist",
            "terms_acknowledged": True,
            "non_diagnostic_acknowledged": True,
        },
    )

    # Specialist should be allowed access (200 OK)
    res_allowed = client.get(
        "/api/v1/test/specialist-only",
        headers=spec_headers,
    )
    assert res_allowed.status_code == 200
    assert res_allowed.json()["message"] == "Welcome specialist"
