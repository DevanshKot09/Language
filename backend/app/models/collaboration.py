import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class Relationship(Base):
    """
    Authorized multi-user relationship connecting an actor (Parent, Teacher, Specialist)
    to a target Learner.
    Enforces non-diagnostic, strictly bounded educational collaboration.
    """
    __tablename__ = "relationships"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    source_user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    target_user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    relationship_type = Column(String(32), nullable=False, index=True)  # parent, teacher, specialist
    status = Column(String(32), default="active", nullable=False, index=True)  # pending, active, rejected, revoked, expired
    permission_scope = Column(Text, nullable=False)  # JSON-encoded list of allowed scopes
    consent_status = Column(String(32), default="verified", nullable=False)  # not_required, pending, verified, revoked
    organization = Column(String(128), nullable=True)  # school or clinic identifier

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    expires_at = Column(DateTime(timezone=True), nullable=True)
    revoked_at = Column(DateTime(timezone=True), nullable=True)

    source_user = relationship("User", foreign_keys=[source_user_id])
    target_user = relationship("User", foreign_keys=[target_user_id])

    __table_args__ = (
        UniqueConstraint("source_user_id", "target_user_id", "relationship_type", name="uq_relationship"),
    )


class RelationshipInvitation(Base):
    """
    Single-use, time-limited invitation token for establishing an authorized relationship.
    """
    __tablename__ = "relationship_invitations"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    invitation_token = Column(String(64), unique=True, index=True, nullable=False)
    inviter_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    invitee_email = Column(String(255), nullable=False, index=True)
    target_learner_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    relationship_type = Column(String(32), nullable=False, index=True)  # parent, teacher, specialist
    permission_scope = Column(Text, nullable=False)  # JSON-encoded list
    status = Column(String(32), default="pending", nullable=False, index=True)  # pending, accepted, rejected, revoked, expired
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    accepted_at = Column(DateTime(timezone=True), nullable=True)

    inviter = relationship("User", foreign_keys=[inviter_id])
    target_learner = relationship("User", foreign_keys=[target_learner_id])


class Assignment(Base):
    """
    Controlled educator/specialist assignment linking an authorized learner to an approved lesson.
    Maintains independence from learner personal goals.
    """
    __tablename__ = "assignments"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    teacher_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    instructions = Column(Text, nullable=True)
    status = Column(String(32), default="assigned", nullable=False, index=True)  # assigned, in_progress, completed, overdue
    due_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    teacher = relationship("User", foreign_keys=[teacher_id])
    student = relationship("User", foreign_keys=[student_id])
    lesson = relationship("Lesson", foreign_keys=[lesson_id])


class Report(Base):
    """
    Educational learning-support report summary.
    Factual, traceable to real stored database counts, and non-diagnostic.
    """
    __tablename__ = "reports"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    creator_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    learner_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    report_type = Column(String(32), nullable=False, index=True)  # parent_summary, teacher_summary, specialist_summary
    title = Column(String(255), nullable=False)
    summary_data = Column(Text, nullable=False)  # JSON-encoded metrics & progress snapshot
    disclaimer = Column(Text, nullable=False)
    status = Column(String(32), default="active", nullable=False, index=True)  # active, revoked, deleted
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)

    creator = relationship("User", foreign_keys=[creator_id])
    learner = relationship("User", foreign_keys=[learner_id])


class ReportAccessEvent(Base):
    """
    Audit log for cross-user collaboration and report access events.
    Enforces privacy by recording actor, resource type, action, and minimal metadata.
    """
    __tablename__ = "report_access_events"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    action = Column(String(64), nullable=False, index=True)
    target_user_id = Column(String(36), nullable=True, index=True)
    resource_type = Column(String(64), nullable=False)
    resource_id = Column(String(36), nullable=True)
    details = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", foreign_keys=[user_id])
