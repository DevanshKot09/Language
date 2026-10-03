import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    firebase_uid = Column(String(128), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    role = Column(String(50), nullable=False, default="learner")
    status = Column(String(50), nullable=False, default="active")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    # 1-to-1 relationships with domain profile, preferences, and onboarding state
    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    accessibility_preferences = relationship(
        "AccessibilityPreferences",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    onboarding_state = relationship(
        "OnboardingState",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    exercise_attempts = relationship("ExerciseAttempt", back_populates="user", cascade="all, delete-orphan")
    lesson_progress = relationship("UserLessonProgress", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("LearnerGoal", back_populates="user", cascade="all, delete-orphan")
    achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")

