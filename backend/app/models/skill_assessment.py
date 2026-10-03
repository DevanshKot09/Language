import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class SkillAssessment(Base):
    """
    Skill snapshot assessment record.
    Uses descriptive learning readiness bands:
    - 'starting': needs initial introductory models and high visual support
    - 'developing': emerging capability; needs guided structured practice
    - 'practicing': solid accuracy; building fluency and automaticity
    - 'consistent': strong independent mastery; ready for advanced contexts
    NO medical or clinical diagnostic categories.
    """
    __tablename__ = "skill_assessments"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="CASCADE"), index=True, nullable=False)
    session_id = Column(String(36), ForeignKey("baseline_sessions.id", ondelete="SET NULL"), index=True, nullable=True)

    assessment_type = Column(String(50), default="baseline", nullable=False)  # baseline, practice, checkpoint
    score = Column(Float, default=0.0, nullable=False)
    accuracy = Column(Float, default=0.0, nullable=False)
    attempt_count = Column(Integer, default=1, nullable=False)
    duration_seconds = Column(Integer, default=0, nullable=False)
    band = Column(String(50), nullable=False)  # starting, developing, practicing, consistent
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
    skill = relationship("Skill", back_populates="assessments")
    session = relationship("BaselineSession", back_populates="assessments")
