def test_profile_and_onboarding_lifecycle(client):
    # 1. Sync User with Firebase ID token
    auth_headers = {"Authorization": "Bearer valid_token_jordan_uid_505"}
    sync_res = client.post(
        "/api/v1/auth/sync",
        headers=auth_headers,
        json={
            "role": "learner",
            "age_band": "teen",
            "support_focus": "dld_track",
            "display_name": "Jordan",
            "terms_acknowledged": True,
            "non_diagnostic_acknowledged": True,
        },
    )
    assert sync_res.status_code == 200

    # 2. Get Profile
    get_res = client.get("/api/v1/profile/", headers=auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()["age_band"] == "teen"

    # 3. Update Profile (e.g. adjust to Adult, dual track)
    update_res = client.put(
        "/api/v1/profile/",
        headers=auth_headers,
        json={
            "display_name": "Jordan Learner",
            "age_band": "adult",
            "support_focus": "both_track",
        },
    )
    assert update_res.status_code == 200
    profile_data = update_res.json()
    assert profile_data["display_name"] == "Jordan Learner"
    assert profile_data["age_band"] == "adult"
    assert profile_data["support_focus"] == "both_track"

    # 4. Update Onboarding Progress
    onboard_res = client.put(
        "/api/v1/profile/onboarding",
        headers=auth_headers,
        json={
            "is_completed": True,
            "current_step": "completed",
        },
    )
    assert onboard_res.status_code == 200
    assert onboard_res.json()["is_completed"] is True
    assert onboard_res.json()["completed_at"] is not None

    # 5. Update Accessibility Preferences
    access_res = client.put(
        "/api/v1/profile/accessibility",
        headers=auth_headers,
        json={
            "font_scale": 1.25,
            "use_dyslexic_font": True,
            "high_contrast": True,
        },
    )
    assert access_res.status_code == 200
    access_data = access_res.json()
    assert access_data["font_scale"] == 1.25
    assert access_data["use_dyslexic_font"] is True
    assert access_data["high_contrast"] is True
