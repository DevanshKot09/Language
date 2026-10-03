import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class AccessibilityPreferences(Base):
    """
    Stores WCAG 2.2 AA user interface accessibility preferences.
    """
    __tablename__ = "accessibility_preferences"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True, nullable=False)
    font_scale = Column(Float, nullable=False, default=1.0)
    use_dyslexic_font = Column(Boolean, nullable=False, default=False)
    high_contrast = Column(Boolean, nullable=False, default=False)
    reduced_motion = Column(Boolean, nullable=False, default=False)
    tts_auto_play = Column(Boolean, nullable=False, default=False)
    speech_rate = Column(Float, nullable=False, default=1.0)

    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user = relationship("User", back_populates="accessibility_preferences")
