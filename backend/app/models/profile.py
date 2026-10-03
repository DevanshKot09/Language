import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class Profile(Base):
    """
    User product profile.
    Separates identity/authentication from learning attributes.
    Preserves non-diagnostic boundaries: age_band and support_focus are learning
    configurations, NOT clinical diagnoses.
    """
    __tablename__ = "profiles"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True, nullable=False)
    display_name = Column(String(100), nullable=False, default="Learner")
    age_band = Column(String(50), nullable=False, default="teen")  # child, teen, adult
    support_focus = Column(String(50), nullable=False, default="dld_track")  # dld_track, dyslexia_track, both_track
    guardian_consent_status = Column(String(50), nullable=False, default="not_required")  # not_required, pending, verified

    # Phase 4 Learner Profile extensions
    baseline_status = Column(String(50), default="not_started", nullable=False)  # not_started, in_progress, completed
    preferred_learning_mode = Column(String(50), default="multimodal", nullable=False)  # visual, audio, multimodal
    primary_learning_goal = Column(String(255), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user = relationship("User", back_populates="profile")
