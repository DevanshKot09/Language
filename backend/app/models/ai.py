import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, Integer, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class AiInteraction(Base):
    """
    Privacy-first telemetry record of an AI interaction.
    STRICT DATA MINIMIZATION:
    - Never stores raw prompt text.
    - Never stores raw model generation text.
    - Never stores raw audio or transcripts.
    Stores operational metadata only for safety auditing, latency, and circuit breaking.
    """
    __tablename__ = "ai_interactions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    operation = Column(String(64), nullable=False, index=True)  # recommendation, explanation, feedback, conversation, progress_insight
    provider = Column(String(32), nullable=False)  # gemini, mock
    model = Column(String(64), nullable=False)
    prompt_version = Column(String(32), nullable=False)
    status = Column(String(32), nullable=False, index=True)  # success, error, fallback_used, safety_rejected
    latency_ms = Column(Integer, default=0, nullable=False)
    safety_result = Column(String(32), default="passed", nullable=False)  # passed, rejected

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )

    user = relationship("User")


class Recommendation(Base):
    """
    Structured lesson recommendation record.
    Supports future human/educator override (Step 60 & 90).
    Non-diagnostic: represents practice suggestions, not clinical prescriptions.
    """
    __tablename__ = "recommendations"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    operation = Column(String(64), default="ai_personalized_recommendation", nullable=False)
    reason_code = Column(String(64), nullable=False)
    short_explanation = Column(String(255), nullable=False)
    status = Column(String(32), default="active", nullable=False, index=True)  # active, accepted, dismissed, expired

    # Future Professional / Human Oversight Flags (Step 60 & 90)
    human_reviewed = Column(Boolean, default=False, nullable=False)
    human_status = Column(String(32), default="none", nullable=False)  # none, approved, modified, rejected
    human_reviewer_id = Column(String(36), nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    expires_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    user = relationship("User")
    lesson = relationship("Lesson")
