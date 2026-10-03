import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class LearnerGoal(Base):
    """
    Foundational learner goal definition.
    Allows learners, caregivers, and educators to define supportive learning intentions.
    """
    __tablename__ = "learner_goals"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="SET NULL"), index=True, nullable=True)

    title = Column(String(255), nullable=False)
    description = Column(String(500), nullable=True)
    goal_type = Column(String(50), default="complete_lessons", nullable=False)  # complete_lessons, practice_sessions, practice_skill, milestone
    target_count = Column(Integer, default=3, nullable=False)
    current_count = Column(Integer, default=0, nullable=False)
    target_frequency = Column(String(50), default="weekly", nullable=False)  # daily, weekly, biweekly
    target_behavior = Column(String(255), nullable=True)
    status = Column(String(50), default="active", nullable=False)  # active, completed, achieved, paused

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    completed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="goals")
    skill = relationship("Skill", back_populates="goals")
