import pytest
from app.core.security import log_security_event
from app.core.firebase import verify_firebase_id_token


def test_security_audit_logging(caplog):
    import logging
    with caplog.at_level(logging.INFO):
        log_security_event("test_security_event", user_id="user_test_99", details="action=verified")
    assert "test_security_event" in caplog.text
    assert "user_test_99" in caplog.text


def test_mock_firebase_token_verifier():
    claims = verify_firebase_id_token("valid_token_test_user_777")
    assert claims["uid"] == "test_user_777"
    assert claims["email"] == "test_user_777@lingua.ai"

    with pytest.raises(ValueError, match="expired"):
        verify_firebase_id_token("expired_token")

    with pytest.raises(ValueError, match="invalid"):
        verify_firebase_id_token("invalid_token")
