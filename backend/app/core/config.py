import os
from typing import Optional
from dotenv import load_dotenv
from pydantic import BaseModel

# Automatically load environment variables from backend/.env if present
_env_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.env"))
if os.path.exists(_env_file):
    load_dotenv(_env_file)
elif os.path.exists(".env"):
    load_dotenv(".env")


class Settings(BaseModel):
    PROJECT_NAME: str = "LINGUA AI Backend Service"
    PROJECT_DESCRIPTION: str = "Evidence-informed language and literacy support API (DLD & Dyslexia). Non-diagnostic educational service."
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "true").lower() in ("true", "1", "yes")

    # Firebase Authentication
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "lingual-ai")
    FIREBASE_CREDENTIALS_PATH: Optional[str] = os.getenv("FIREBASE_CREDENTIALS_PATH", None)
    FIREBASE_AUTH_EMULATOR_HOST: Optional[str] = os.getenv("FIREBASE_AUTH_EMULATOR_HOST", None)

    # Database: Supabase PostgreSQL as production source of truth
    # Canonical configuration: DATABASE_URL (or fallback SUPABASE_DATABASE_URL)
    # Default to local SQLite fallback if unset for offline unit tests
    DATABASE_URL: str = os.getenv(
        "SUPABASE_DATABASE_URL",
        os.getenv("DATABASE_URL", "sqlite:///./lingua_ai.db"),
    )

    # Security Auditing
    LOG_SECURITY_EVENTS: bool = True

    # Phase 9: AI Layer Configuration
    AI_ENABLED: bool = os.getenv("AI_ENABLED", "true").lower() in ("true", "1", "yes")
    AI_PROVIDER: str = os.getenv("AI_PROVIDER", "gemini")  # gemini, mock
    AI_MODEL: str = os.getenv("AI_MODEL", "gemini-2.5-flash")
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY", None)
    AI_REQUEST_TIMEOUT: int = int(os.getenv("AI_REQUEST_TIMEOUT", "15"))
    AI_MAX_OUTPUT_TOKENS: int = int(os.getenv("AI_MAX_OUTPUT_TOKENS", "1024"))
    AI_DAILY_REQUEST_LIMIT: int = int(os.getenv("AI_DAILY_REQUEST_LIMIT", "100"))
    AI_CHILD_CLOUD_ALLOWED: bool = os.getenv("AI_CHILD_CLOUD_ALLOWED", "false").lower() in ("true", "1", "yes")

    # Phase 12: Production Hardening & Security Configuration
    ALLOWED_ORIGINS: str = os.getenv("ALLOWED_ORIGINS", "*")
    ENABLE_SECURITY_HEADERS: bool = os.getenv("ENABLE_SECURITY_HEADERS", "true").lower() in ("true", "1", "yes")
    MAX_REQUEST_BODY_BYTES: int = int(os.getenv("MAX_REQUEST_BODY_BYTES", str(5 * 1024 * 1024)))  # 5 MB
    FIREBASE_APP_CHECK_REQUIRED: bool = os.getenv("FIREBASE_APP_CHECK_REQUIRED", "false").lower() in ("true", "1", "yes")
    RATE_LIMIT_ENABLED: bool = os.getenv("RATE_LIMIT_ENABLED", "true").lower() in ("true", "1", "yes")
    RATE_LIMIT_INVITATIONS_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_INVITATIONS_PER_MINUTE", "20"))
    RATE_LIMIT_REPORTS_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_REPORTS_PER_MINUTE", "15"))
    RATE_LIMIT_AI_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_AI_PER_MINUTE", "40"))


settings = Settings()
