import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class Skill(Base):
    """
    Evidence-informed skill definition adhering to the LINGUA AI taxonomy.
    Maintains strict separation between DLD-oriented spoken-language skills
    and Dyslexia-oriented written-language/literacy skills.
    Non-diagnostic: represents areas for practice, NOT disorder evidence.
    """
    __tablename__ = "skills"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    code = Column(String(64), unique=True, index=True, nullable=False)
    name = Column(String(128), nullable=False)
    description = Column(Text, nullable=False)
    track = Column(String(50), nullable=False, index=True)  # dld_track, dyslexia_track, both_track
    domain = Column(String(64), nullable=False, index=True)
    age_band_applicability = Column(String(64), default="all", nullable=False)  # all, child, teen, adult
    priority = Column(String(32), default="ESSENTIAL", nullable=False)  # ESSENTIAL, IMPORTANT, OPTIONAL
    active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    activities = relationship("BaselineActivity", back_populates="skill", cascade="all, delete-orphan")
    assessments = relationship("SkillAssessment", back_populates="skill", cascade="all, delete-orphan")
    goals = relationship("LearnerGoal", back_populates="skill")
    lessons = relationship("Lesson", back_populates="skill", cascade="all, delete-orphan")
    exercises = relationship("Exercise", back_populates="skill", cascade="all, delete-orphan")
