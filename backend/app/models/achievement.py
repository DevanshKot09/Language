import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Integer, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class AchievementDefinition(Base):
    """
    Evidence-informed application milestone definition.
    Celebrates effort, exploration, and practice consistency.
    Non-diagnostic: rewards activity, NOT clinical mastery or deficit reduction.
    """
    __tablename__ = "achievements"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    code = Column(String(64), unique=True, index=True, nullable=False)
    title = Column(String(128), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String(50), nullable=False, index=True)  # learning, practice, skills, goals
    icon_name = Column(String(64), nullable=False, default="emoji_events")
    threshold = Column(Integer, default=1, nullable=False)
    badge_tier = Column(String(32), default="bronze", nullable=False)  # bronze, silver, gold, milestone

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user_achievements = relationship(
        "UserAchievement",
        back_populates="achievement",
        cascade="all, delete-orphan",
    )


class UserAchievement(Base):
    """
    Immutable instance of a learner earning an achievement milestone.
    Enforces uniqueness so achievements are never awarded more than once.
    """
    __tablename__ = "user_achievements"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    achievement_id = Column(String(36), ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False, index=True)
    progress_value = Column(Integer, default=1, nullable=False)
    unlocked_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
    )

    user = relationship("User", back_populates="achievements")
    achievement = relationship("AchievementDefinition", back_populates="user_achievements")
