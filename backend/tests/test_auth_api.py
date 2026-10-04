def test_missing_authorization_header(client):
    res = client.get("/api/v1/auth/me")
    assert res.status_code == 401
    assert "authentication required" in res.json()["detail"].lower()


def test_invalid_firebase_token(client):
    res = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token"},
    )
    assert res.status_code == 401
    assert "invalid or expired" in res.json()["detail"].lower()


def test_expired_firebase_token(client):
    res = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer expired_token"},
    )
    assert res.status_code == 401
    assert "invalid or expired" in res.json()["detail"].lower()


def test_first_time_signup_sync_and_profile_creation(client):
    # 1. First-time sync with valid Firebase ID token
    res = client.post(
        "/api/v1/auth/sync",
        headers={"Authorization": "Bearer valid_token_alex_uid_101"},
        json={
            "role": "learner",
            "age_band": "teen",
            "support_focus": "dld_track",
            "display_name": "Alex Learner",
            "terms_acknowledged": True,
            "non_diagnostic_acknowledged": True,
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["user"]["firebase_uid"] == "alex_uid_101"
    assert data["user"]["email"] == "alex_uid_101@lingua.ai"
    assert data["user"]["role"] == "learner"
    assert data["profile"]["display_name"] == "Alex Learner"
    assert data["profile"]["age_band"] == "teen"
    assert data["profile"]["support_focus"] == "dld_track"
    assert data["profile"]["guardian_consent_status"] == "not_required"
    assert data["accessibility"]["font_scale"] == 1.0
    assert data["onboarding"]["is_completed"] is False


def test_repeated_login_sync_does_not_duplicate_users(client):
    # 1. First sync creates user
    res1 = client.post(
        "/api/v1/auth/sync",
        headers={"Authorization": "Bearer valid_token_sam_uid_202"},
        json={
            "role": "learner",
            "age_band": "child",
            "support_focus": "dyslexia_track",
            "display_name": "Sam",
            "terms_acknowledged": True,
            "non_diagnostic_acknowledged": True,
        },
    )
    assert res1.status_code == 200
    user_id_first = res1.json()["user"]["id"]
    assert res1.json()["profile"]["guardian_consent_status"] == "pending"

    # 2. Repeated login sync for the same Firebase UID
    res2 = client.post(
        "/api/v1/auth/sync",
        headers={"Authorization": "Bearer valid_token_sam_uid_202"},
        json={},
    )
    assert res2.status_code == 200
    user_id_second = res2.json()["user"]["id"]
    assert user_id_first == user_id_second
    assert res2.json()["user"]["firebase_uid"] == "sam_uid_202"


def test_get_me_endpoint_for_authenticated_firebase_user(client):
    # Sync first
    client.post(
        "/api/v1/auth/sync",
        headers={"Authorization": "Bearer valid_token_taylor_uid_303"},
        json={"display_name": "Taylor"},
    )

    # Call /me with Bearer token
    res_me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer valid_token_taylor_uid_303"},
    )
    assert res_me.status_code == 200
    me_data = res_me.json()
    assert me_data["user"]["firebase_uid"] == "taylor_uid_303"
    assert me_data["profile"]["display_name"] == "Taylor"


def test_logout_endpoint(client):
    # Sync first
    client.post(
        "/api/v1/auth/sync",
        headers={"Authorization": "Bearer valid_token_logout_uid_404"},
        json={},
    )

    # Logout
    res = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": "Bearer valid_token_logout_uid_404"},
        json={"reason": "user_initiated"},
    )
    assert res.status_code == 200
    assert res.json()["status"] == "success"


def test_forgot_password_valid_email_returns_safe_confirmation(client):
    res = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "sarah.jenkins@example.com"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert "If an account exists" in data["message"]
    # Check that secrets/tokens are never exposed in response
    assert "token" not in data
    assert "password" not in data


def test_forgot_password_invalid_email_format(client):
    res = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "not-an-email"},
    )
    assert res.status_code == 422


def test_forgot_password_user_enumeration_protection(client):
    # Non-existent user email receives identical generic message
    res = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "nonexistent.user.test@example.com"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert "If an account exists for this email, we'll send a reset link." in data["message"]
