import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class BaselineSession(Base):
    """
    Session record for a learner's initial, non-diagnostic skill snapshot.
    Determines recommended initial practice targets.
    Does NOT diagnose or compute medical risk scores.
    """
    __tablename__ = "baseline_sessions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    track = Column(String(50), nullable=False)  # dld_track, dyslexia_track, both_track
    status = Column(String(50), default="in_progress", nullable=False)  # in_progress, paused, completed
    total_activities = Column(Integer, default=6, nullable=False)
    completed_activities = Column(Integer, default=0, nullable=False)

    started_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User")
    responses = relationship("BaselineResponse", back_populates="session", cascade="all, delete-orphan")
    assessments = relationship("SkillAssessment", back_populates="session")


class BaselineActivity(Base):
    """
    Reusable structured question/activity item for skill baselining.
    Deterministic selection based on track, skill domain, and age band.
    """
    __tablename__ = "baseline_activities"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="CASCADE"), index=True, nullable=False)
    track = Column(String(50), nullable=False, index=True)
    domain = Column(String(64), nullable=False, index=True)
    age_band = Column(String(50), default="all", nullable=False)  # child, teen, adult, all
    activity_type = Column(String(64), nullable=False)  # vocabulary_choice, grammar_agreement, phonological_sound, phonics_mapping, decoding, reading_comprehension
    instruction = Column(Text, nullable=False)
    prompt = Column(Text, nullable=False)
    options_json = Column(Text, nullable=False)  # JSON-encoded list of options
    correct_answer = Column(String(255), nullable=False)
    hint = Column(Text, nullable=True)
    difficulty = Column(Integer, default=1, nullable=False)
    active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    skill = relationship("Skill", back_populates="activities")
    responses = relationship("BaselineResponse", back_populates="activity")


class BaselineResponse(Base):
    """
    Individual response submitted during a baseline session.
    Stores only minimal fields needed to compute practice bands.
    Never stores audio recordings or unnecessary personal data.
    """
    __tablename__ = "baseline_responses"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    session_id = Column(String(36), ForeignKey("baseline_sessions.id", ondelete="CASCADE"), index=True, nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    activity_id = Column(String(36), ForeignKey("baseline_activities.id", ondelete="CASCADE"), index=True, nullable=False)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="CASCADE"), index=True, nullable=False)

    selected_option = Column(String(255), nullable=False)
    is_correct = Column(Boolean, nullable=False)
    time_taken_ms = Column(Integer, default=0, nullable=False)
    attempt_count = Column(Integer, default=1, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    session = relationship("BaselineSession", back_populates="responses")
    activity = relationship("BaselineActivity", back_populates="responses")
    skill = relationship("Skill")
