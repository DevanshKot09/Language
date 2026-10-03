import logging
from typing import Optional
from app.core.config import settings

# Dedicated security audit logger (separate from ordinary application logs)
security_logger = logging.getLogger("lingua_ai.security_audit")
security_logger.setLevel(logging.INFO)
if not security_logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter(
        '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "event": "SECURITY_AUDIT", "message": "%(message)s"}'
    )
    handler.setFormatter(formatter)
    security_logger.addHandler(handler)


def log_security_event(event_type: str, user_id: Optional[str] = None, details: Optional[str] = None) -> None:
    """
    Logs security audit events following data minimization.
    NEVER logs plain passwords, raw tokens, or sensitive health data.
    """
    if settings.LOG_SECURITY_EVENTS:
        safe_user = user_id or "anonymous"
        safe_details = details or "none"
        security_logger.info(f"event_type={event_type} user_id={safe_user} details={safe_details}")
