import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class Lesson(Base):
    """
    A structured, curriculum-aligned unit of learning practice.
    Connects to an evidence-based skill and track.
    Non-diagnostic: represents practice sequences, not disorder severity.
    """
    __tablename__ = "lessons"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(128), nullable=False)
    description = Column(Text, nullable=False)
    track = Column(String(50), nullable=False, index=True)  # dld_track, dyslexia_track, both_track
    age_band = Column(String(32), default="all", nullable=False, index=True)  # child, teen, adult, all
    difficulty = Column(Integer, default=1, nullable=False, index=True)  # 1 to 4
    sequence_order = Column(Integer, default=1, nullable=False)
    estimated_effort_minutes = Column(Integer, default=5, nullable=False)
    active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    skill = relationship("Skill", back_populates="lessons")
    exercises = relationship(
        "Exercise",
        back_populates="lesson",
        cascade="all, delete-orphan",
        order_by="Exercise.sequence_order",
    )
    progress_records = relationship(
        "UserLessonProgress",
        back_populates="lesson",
        cascade="all, delete-orphan",
    )
    attempts = relationship(
        "ExerciseAttempt",
        back_populates="lesson",
        cascade="all, delete-orphan",
    )


class Exercise(Base):
    """
    An individual practice activity within a lesson.
    Stores structured content decoupled from presentation logic.
    Supports deterministic evaluation across diverse exercise types.
    """
    __tablename__ = "exercises"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    lesson_id = Column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    skill_id = Column(String(36), ForeignKey("skills.id", ondelete="CASCADE"), nullable=False, index=True)
    exercise_type = Column(String(64), nullable=False, index=True)
    # Types: multiple_choice, word_order, matching, sentence_completion, reading_passage, spelling_selection, narrative_sequencing

    prompt = Column(Text, nullable=False)
    instruction = Column(Text, nullable=False)
    content_json = Column(Text, nullable=False)  # JSON structure containing options, passage, pairs, tokens
    correct_answer_json = Column(Text, nullable=False)  # JSON or string representation of target answer
    explanation = Column(Text, nullable=True)  # Pedagogical explanation or learning cue

    difficulty = Column(Integer, default=1, nullable=False)
    age_band = Column(String(32), default="all", nullable=False)
    track = Column(String(50), nullable=False)
    sequence_order = Column(Integer, default=1, nullable=False)

    hints_json = Column(Text, nullable=True)  # JSON array of progressive clues
    feedback_config_json = Column(Text, nullable=True)  # JSON object with encouraging feedback texts
    active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    lesson = relationship("Lesson", back_populates="exercises")
    skill = relationship("Skill", back_populates="exercises")
    attempts = relationship("ExerciseAttempt", back_populates="exercise", cascade="all, delete-orphan")


class ExerciseAttempt(Base):
    """
    An immutable record of a learner's attempt at an exercise.
    Preserves historical learning data without clinical or diagnostic labels.
    """
    __tablename__ = "exercise_attempts"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    exercise_id = Column(String(36), ForeignKey("exercises.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)

    response_json = Column(Text, nullable=False)  # Learner answer (string or JSON serialized)
    is_correct = Column(Boolean, nullable=False)
    partial_score = Column(Float, default=0.0, nullable=False)  # 0.0 to 1.0
    attempt_number = Column(Integer, default=1, nullable=False)
    time_spent_ms = Column(Integer, default=0, nullable=False)
    hint_used = Column(Boolean, default=False, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    user = relationship("User", back_populates="exercise_attempts")
    exercise = relationship("Exercise", back_populates="attempts")
    lesson = relationship("Lesson", back_populates="attempts")


class UserLessonProgress(Base):
    """
    Tracks state of a user's progress through a lesson.
    Enables pausing and resuming without losing completed exercises or attempts.
    """
    __tablename__ = "user_lesson_progress"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)

    current_exercise_index = Column(Integer, default=0, nullable=False)
    status = Column(String(32), default="not_started", nullable=False)  # not_started, in_progress, completed
    score = Column(Float, nullable=True)  # average accuracy across exercises
    completed_at = Column(DateTime(timezone=True), nullable=True)
    last_attempted_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    user = relationship("User", back_populates="lesson_progress")
    lesson = relationship("Lesson", back_populates="progress_records")
