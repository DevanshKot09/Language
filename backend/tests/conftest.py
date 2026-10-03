import os
import sys

# Ensure backend root is on python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["ENVIRONMENT"] = "test"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
import app.models  # noqa: F401
from app.core.seeds import seed_skills_and_activities
from app.core.firebase import set_token_verifier_for_testing
from app.main import app

TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def mock_firebase_token_verifier(token: str):
    """
    Deterministic mock Firebase ID Token verifier for test isolation.
    Does not make external Google Cloud network calls.
    """
    if token.startswith("valid_token_"):
        uid = token.replace("valid_token_", "")
        return {
            "uid": uid,
            "email": f"{uid}@lingua.ai",
            "aud": "lingual-ai",
            "iss": "https://securetoken.google.com/lingual-ai",
            "sub": uid,
        }
    elif token == "expired_token":
        raise ValueError("Firebase ID token has expired")
    elif token == "invalid_token":
        raise ValueError("Firebase ID token is invalid or malformed")
    else:
        # Default mock token
        return {
            "uid": "test-firebase-uid-default",
            "email": "learner@lingua.ai",
            "aud": "lingual-ai",
            "iss": "https://securetoken.google.com/lingual-ai",
            "sub": "test-firebase-uid-default",
        }


@pytest.fixture(scope="session", autouse=True)
def setup_mock_firebase():
    set_token_verifier_for_testing(mock_firebase_token_verifier)
    yield
    set_token_verifier_for_testing(None)


@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database schema for each test."""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        seed_skills_and_activities(db)
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)



@pytest.fixture(scope="function")
def client(db_session):
    """Override get_db with isolated test database session."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
