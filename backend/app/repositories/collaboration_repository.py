import json
import secrets
import hashlib
from datetime import datetime, timezone, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc

from app.models.collaboration import (
    Relationship,
    RelationshipInvitation,
    Assignment,
    Report,
    ReportAccessEvent,
)
from app.models.user import User
from app.models.profile import Profile
from app.core.security import log_security_event


DEFAULT_PARENT_SCOPES = [
    "view_profile_summary",
    "view_progress",
    "view_goals",
    "view_activity",
    "view_home_practice",
    "generate_report",
]

DEFAULT_TEACHER_SCOPES = [
    "view_progress",
    "view_assigned_work",
    "view_completion",
    "create_assignment",
    "view_skill_summary",
    "generate_report",
]

DEFAULT_SPECIALIST_SCOPES = [
    "view_profile",
    "view_skill_history",
    "view_baseline",
    "view_goals",
    "create_goal",
    "modify_support_plan",
    "view_ai_recommendations",
    "review_ai_recommendations",
    "generate_support_report",
]


class CollaborationRepository:
    def __init__(self, db: Session):
        self.db = db

    # -------------------------------------------------------------
    # RELATIONSHIPS
    # -------------------------------------------------------------
    def get_relationship(self, relationship_id: str) -> Optional[Relationship]:
        return self.db.query(Relationship).filter(Relationship.id == relationship_id).first()

    def get_active_relationship(
        self,
        source_user_id: str,
        target_user_id: str,
        relationship_type: Optional[str] = None,
    ) -> Optional[Relationship]:
        query = self.db.query(Relationship).filter(
            Relationship.source_user_id == source_user_id,
            Relationship.target_user_id == target_user_id,
            Relationship.status == "active",
        )
        if relationship_type:
            query = query.filter(Relationship.relationship_type == relationship_type)
        rel = query.first()
        if rel and rel.expires_at:
            now = datetime.now(timezone.utc)
            exp = rel.expires_at if rel.expires_at.tzinfo else rel.expires_at.replace(tzinfo=timezone.utc)
            if exp < now:
                rel.status = "expired"
                self.db.commit()
                return None
        return rel

    def list_actor_relationships(
        self,
        source_user_id: str,
        relationship_type: Optional[str] = None,
        status: str = "active",
    ) -> List[Relationship]:
        query = self.db.query(Relationship).filter(
            Relationship.source_user_id == source_user_id,
        )
        if status != "all":
            query = query.filter(Relationship.status == status)
        if relationship_type:
            query = query.filter(Relationship.relationship_type == relationship_type)
        return query.order_by(desc(Relationship.created_at)).all()

    def list_learner_relationships(self, target_user_id: str) -> List[Relationship]:
        return (
            self.db.query(Relationship)
            .filter(
                Relationship.target_user_id == target_user_id,
                Relationship.status.in_(["active", "pending"]),
            )
            .order_by(desc(Relationship.created_at))
            .all()
        )

    def create_or_activate_relationship(
        self,
        source_user_id: str,
        target_user_id: str,
        relationship_type: str,
        permission_scope: Optional[List[str]] = None,
        organization: Optional[str] = None,
        consent_status: str = "verified",
        expires_days: Optional[int] = None,
    ) -> Relationship:
        existing = (
            self.db.query(Relationship)
            .filter(
                Relationship.source_user_id == source_user_id,
                Relationship.target_user_id == target_user_id,
                Relationship.relationship_type == relationship_type,
            )
            .first()
        )

        scopes = permission_scope
        if not scopes:
            if relationship_type == "parent":
                scopes = DEFAULT_PARENT_SCOPES
            elif relationship_type == "teacher":
                scopes = DEFAULT_TEACHER_SCOPES
            else:
                scopes = DEFAULT_SPECIALIST_SCOPES

        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(days=expires_days) if expires_days else None

        if existing:
            existing.status = "active"
            existing.permission_scope = json.dumps(scopes)
            existing.consent_status = consent_status
            existing.organization = organization or existing.organization
            existing.updated_at = now
            existing.expires_at = expires_at
            existing.revoked_at = None
            self.db.commit()
            self.db.refresh(existing)
            self.log_access_event(
                user_id=source_user_id,
                action="relationship_reactivated",
                resource_type="relationship",
                resource_id=existing.id,
                target_user_id=target_user_id,
                details=f"type={relationship_type}",
            )
            return existing

        new_rel = Relationship(
            source_user_id=source_user_id,
            target_user_id=target_user_id,
            relationship_type=relationship_type,
            status="active",
            permission_scope=json.dumps(scopes),
            consent_status=consent_status,
            organization=organization,
            created_at=now,
            updated_at=now,
            expires_at=expires_at,
        )
        self.db.add(new_rel)
        self.db.commit()
        self.db.refresh(new_rel)

        self.log_access_event(
            user_id=source_user_id,
            action="relationship_created",
            resource_type="relationship",
            resource_id=new_rel.id,
            target_user_id=target_user_id,
            details=f"type={relationship_type}",
        )
        return new_rel

    def revoke_relationship(self, relationship: Relationship, revoking_user_id: str) -> Relationship:
        now = datetime.now(timezone.utc)
        relationship.status = "revoked"
        relationship.revoked_at = now
        relationship.updated_at = now
        self.db.commit()
        self.db.refresh(relationship)

        self.log_access_event(
            user_id=revoking_user_id,
            action="relationship_revoked",
            resource_type="relationship",
            resource_id=relationship.id,
            target_user_id=relationship.target_user_id,
            details=f"revoked_by={revoking_user_id}",
        )
        log_security_event(
            "relationship_revoked",
            user_id=revoking_user_id,
            details=f"rel_id={relationship.id} target={relationship.target_user_id}",
        )
        return relationship

    # -------------------------------------------------------------
    # INVITATIONS
    # -------------------------------------------------------------
    def create_invitation(
        self,
        inviter_id: str,
        invitee_email: str,
        relationship_type: str,
        target_learner_id: Optional[str] = None,
        permission_scope: Optional[List[str]] = None,
        expires_hours: int = 72,
    ) -> RelationshipInvitation:
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(hours=expires_hours)

        scopes = permission_scope
        if not scopes:
            if relationship_type == "parent":
                scopes = DEFAULT_PARENT_SCOPES
            elif relationship_type == "teacher":
                scopes = DEFAULT_TEACHER_SCOPES
            else:
                scopes = DEFAULT_SPECIALIST_SCOPES

        invitation = RelationshipInvitation(
            invitation_token=token_hash,
            inviter_id=inviter_id,
            invitee_email=invitee_email.lower().strip(),
            target_learner_id=target_learner_id,
            relationship_type=relationship_type,
            permission_scope=json.dumps(scopes),
            status="pending",
            expires_at=expires_at,
            created_at=now,
        )
        self.db.add(invitation)
        self.db.commit()
        self.db.refresh(invitation)
        invitation._raw_token = token

        self.log_access_event(
            user_id=inviter_id,
            action="relationship_invited",
            resource_type="invitation",
            resource_id=invitation.id,
            target_user_id=target_learner_id,
            details=f"email={invitee_email} type={relationship_type}",
        )
        return invitation

    def get_invitation_by_token(self, token: str) -> Optional[RelationshipInvitation]:
        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        return (
            self.db.query(RelationshipInvitation)
            .filter(
                (RelationshipInvitation.invitation_token == token_hash)
                | (RelationshipInvitation.invitation_token == token)
            )
            .first()
        )

    def list_invitations_for_email(self, email: str) -> List[RelationshipInvitation]:
        return (
            self.db.query(RelationshipInvitation)
            .filter(
                RelationshipInvitation.invitee_email == email.lower().strip(),
                RelationshipInvitation.status == "pending",
            )
            .all()
        )

    def list_invitations_by_inviter(self, inviter_id: str) -> List[RelationshipInvitation]:
        return (
            self.db.query(RelationshipInvitation)
            .filter(RelationshipInvitation.inviter_id == inviter_id)
            .order_by(desc(RelationshipInvitation.created_at))
            .all()
        )

    def accept_invitation(
        self,
        invitation: RelationshipInvitation,
        accepting_user: User,
    ) -> Relationship:
        now = datetime.now(timezone.utc)
        inv_expires = invitation.expires_at if invitation.expires_at.tzinfo else invitation.expires_at.replace(tzinfo=timezone.utc)
        if inv_expires < now:
            invitation.status = "expired"
            self.db.commit()
            raise ValueError("This invitation has expired.")

        if invitation.status != "pending":
            raise ValueError(f"Invitation is already {invitation.status}.")

        inviter = self.db.query(User).filter(User.id == invitation.inviter_id).first()
        if not inviter:
            raise ValueError("Inviting user record not found.")

        # Determine actor and learner:
        # Case A: Professional/Parent invited a Learner -> Inviter is source, Accepting user is target learner
        # Case B: Learner/Parent invited a Specialist/Teacher -> Accepting user is source, Target learner is target
        if invitation.target_learner_id:
            target_learner_id = invitation.target_learner_id
            source_user_id = accepting_user.id if accepting_user.id != target_learner_id else inviter.id
        else:
            # Inviter is the adult role, accepting user is the learner
            source_user_id = inviter.id
            target_learner_id = accepting_user.id

        scopes = json.loads(invitation.permission_scope) if invitation.permission_scope else None

        relationship = self.create_or_activate_relationship(
            source_user_id=source_user_id,
            target_user_id=target_learner_id,
            relationship_type=invitation.relationship_type,
            permission_scope=scopes,
            consent_status="verified",
        )

        invitation.status = "accepted"
        invitation.accepted_at = now
        self.db.commit()

        self.log_access_event(
            user_id=accepting_user.id,
            action="relationship_accepted",
            resource_type="invitation",
            resource_id=invitation.id,
            target_user_id=target_learner_id,
            details=f"accepted_by={accepting_user.id}",
        )
        return relationship

    def reject_invitation(
        self,
        invitation: RelationshipInvitation,
        rejecting_user_id: str,
    ) -> RelationshipInvitation:
        invitation.status = "rejected"
        self.db.commit()
        self.db.refresh(invitation)

        self.log_access_event(
            user_id=rejecting_user_id,
            action="relationship_rejected",
            resource_type="invitation",
            resource_id=invitation.id,
            details=f"rejected_by={rejecting_user_id}",
        )
        return invitation

    # -------------------------------------------------------------
    # ASSIGNMENTS (Teacher / Educator)
    # -------------------------------------------------------------
    def create_assignment(
        self,
        teacher_id: str,
        student_id: str,
        lesson_id: str,
        title: str,
        instructions: Optional[str] = None,
        due_at: Optional[datetime] = None,
    ) -> Assignment:
        now = datetime.now(timezone.utc)
        assignment = Assignment(
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_id=lesson_id,
            title=title,
            instructions=instructions,
            status="assigned",
            due_at=due_at,
            created_at=now,
            updated_at=now,
        )
        self.db.add(assignment)
        self.db.commit()
        self.db.refresh(assignment)

        self.log_access_event(
            user_id=teacher_id,
            action="assignment_created",
            resource_type="assignment",
            resource_id=assignment.id,
            target_user_id=student_id,
            details=f"lesson={lesson_id}",
        )
        return assignment

    def get_assignment(self, assignment_id: str) -> Optional[Assignment]:
        return self.db.query(Assignment).filter(Assignment.id == assignment_id).first()

    def list_teacher_assignments(self, teacher_id: str) -> List[Assignment]:
        return (
            self.db.query(Assignment)
            .filter(Assignment.teacher_id == teacher_id)
            .order_by(desc(Assignment.created_at))
            .all()
        )

    def list_student_assignments(self, student_id: str) -> List[Assignment]:
        return (
            self.db.query(Assignment)
            .filter(Assignment.student_id == student_id)
            .order_by(desc(Assignment.created_at))
            .all()
        )

    def complete_assignment(self, assignment_id: str, student_id: str) -> Optional[Assignment]:
        assignment = (
            self.db.query(Assignment)
            .filter(Assignment.id == assignment_id, Assignment.student_id == student_id)
            .first()
        )
        if assignment:
            now = datetime.now(timezone.utc)
            assignment.status = "completed"
            assignment.completed_at = now
            assignment.updated_at = now
            self.db.commit()
            self.db.refresh(assignment)
        return assignment

    # -------------------------------------------------------------
    # REPORTS & AUDIT LOGS
    # -------------------------------------------------------------
    def create_report(
        self,
        creator_id: str,
        learner_id: str,
        report_type: str,
        title: str,
        summary_data: Dict[str, Any],
        disclaimer: str,
        expires_days: int = 90,
    ) -> Report:
        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(days=expires_days)
        report = Report(
            creator_id=creator_id,
            learner_id=learner_id,
            report_type=report_type,
            title=title,
            summary_data=json.dumps(summary_data),
            disclaimer=disclaimer,
            status="active",
            created_at=now,
            expires_at=expires_at,
        )
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)

        self.log_access_event(
            user_id=creator_id,
            action="report_generated",
            resource_type="report",
            resource_id=report.id,
            target_user_id=learner_id,
            details=f"type={report_type}",
        )
        return report

    def get_report(self, report_id: str) -> Optional[Report]:
        return self.db.query(Report).filter(Report.id == report_id).first()

    def list_reports_for_creator(self, creator_id: str) -> List[Report]:
        return (
            self.db.query(Report)
            .filter(Report.creator_id == creator_id, Report.status == "active")
            .order_by(desc(Report.created_at))
            .all()
        )

    def list_reports_for_learner(self, learner_id: str) -> List[Report]:
        return (
            self.db.query(Report)
            .filter(Report.learner_id == learner_id, Report.status == "active")
            .order_by(desc(Report.created_at))
            .all()
        )

    def log_access_event(
        self,
        user_id: str,
        action: str,
        resource_type: str,
        resource_id: Optional[str] = None,
        target_user_id: Optional[str] = None,
        details: Optional[str] = None,
    ) -> ReportAccessEvent:
        event = ReportAccessEvent(
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            target_user_id=target_user_id,
            details=details,
            created_at=datetime.now(timezone.utc),
        )
        self.db.add(event)
        self.db.commit()
        return event

    def list_access_events_for_learner(
        self,
        learner_id: str,
        limit: int = 50,
    ) -> List[ReportAccessEvent]:
        return (
            self.db.query(ReportAccessEvent)
            .filter(
                or_(
                    ReportAccessEvent.target_user_id == learner_id,
                    ReportAccessEvent.user_id == learner_id,
                )
            )
            .order_by(desc(ReportAccessEvent.created_at))
            .limit(limit)
            .all()
        )
