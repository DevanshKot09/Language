import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class OnboardingState(Base):
    """
    Tracks learner onboarding progression safely without diagnostic inference.
    """
    __tablename__ = "onboarding_states"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True, nullable=False)
    is_completed = Column(Boolean, nullable=False, default=False)
    current_step = Column(String(50), nullable=False, default="role")
    completed_at = Column(DateTime(timezone=True), nullable=True)

    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user = relationship("User", back_populates="onboarding_state")
