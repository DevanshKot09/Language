import os
import logging
from typing import Any, Dict, Optional
import firebase_admin
from firebase_admin import auth, credentials
from app.core.config import settings

logger = logging.getLogger("lingua_ai.firebase")

_firebase_app: Optional[firebase_admin.App] = None


def get_firebase_app() -> firebase_admin.App:
    """Initializes and returns the singleton Firebase Admin App instance."""
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app

    if settings.FIREBASE_AUTH_EMULATOR_HOST:
        os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = settings.FIREBASE_AUTH_EMULATOR_HOST
        logger.info(f"Using Firebase Auth Emulator at {settings.FIREBASE_AUTH_EMULATOR_HOST}")

    # Check if an app is already initialized in the process
    try:
        _firebase_app = firebase_admin.get_app()
        return _firebase_app
    except ValueError:
        pass

    options = {"projectId": settings.FIREBASE_PROJECT_ID}
    if settings.FIREBASE_CREDENTIALS_PATH and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred, options)
    else:
        # Default application credentials or mock-friendly initialization
        try:
            cred = credentials.ApplicationDefault()
            _firebase_app = firebase_admin.initialize_app(cred, options)
        except Exception:
            _firebase_app = firebase_admin.initialize_app(options=options)

    return _firebase_app


# Hook for injecting mock verifier during unit testing
_custom_token_verifier = None


def set_token_verifier_for_testing(verifier):
    """Allows unit tests to mock Firebase ID token verification without network calls."""
    global _custom_token_verifier
    _custom_token_verifier = verifier


def verify_firebase_id_token(token: str) -> Dict[str, Any]:
    """
    Verifies a Firebase ID token using the Firebase Admin SDK.
    Validates signature, expiration, issuer, and token validity.
    Returns the decoded token claims dictionary containing 'uid', 'email', etc.
    Raises ValueError or AuthError on verification failure.
    """
    if _custom_token_verifier is not None:
        return _custom_token_verifier(token)

    get_firebase_app()
    decoded = auth.verify_id_token(token, check_revoked=False, clock_skew_seconds=10)
    return decoded

