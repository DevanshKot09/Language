import json
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.profile import Profile
from app.models.collaboration import (
    Relationship,
    RelationshipInvitation,
    Assignment,
    Report,
)
from app.models.ai import Recommendation
from app.models.learning import Lesson
from app.repositories.collaboration_repository import (
    CollaborationRepository,
    DEFAULT_PARENT_SCOPES,
    DEFAULT_TEACHER_SCOPES,
    DEFAULT_SPECIALIST_SCOPES,
)
from app.core.security import log_security_event


class CollaborationService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = CollaborationRepository(db)

    # -------------------------------------------------------------
    # AUTHORIZATION CHECK
    # -------------------------------------------------------------
    def verify_relationship_access(
        self,
        actor: User,
        target_learner_id: str,
        required_scope: Optional[str] = None,
    ) -> Optional[Relationship]:
        """
        Enforces server-side relationship authorization.
        Rule: NO automatic access based solely on role.
        Access requires an explicit, active, non-expired relationship.
        """
        if actor.id == target_learner_id:
            # Self-access
            return None

        # Verify target learner exists
        learner = self.db.query(User).filter(User.id == target_learner_id).first()
        if not learner:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Learner record not found.",
            )

        # Check active relationship
        rel = self.repo.get_active_relationship(
            source_user_id=actor.id,
            target_user_id=target_learner_id,
        )
        if not rel or rel.status != "active":
            log_security_event(
                "unauthorized_cross_user_access",
                user_id=actor.id,
                details=f"target_learner={target_learner_id} actor_role={actor.role}",
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have an active authorized relationship with this learner.",
            )

        # Child consent guardrail (Step 7 & 8)
        learner_profile = self.db.query(Profile).filter(Profile.user_id == target_learner_id).first()
        if learner_profile and learner_profile.age_band == "child":
            if learner_profile.guardian_consent_status != "verified" and rel.relationship_type != "parent":
                status_str = learner_profile.guardian_consent_status or "pending"
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Parent / guardian consent is {status_str} for this child learner.",
                )

        # Granular permission scope check (Step 6)
        if required_scope:
            allowed_scopes = json.loads(rel.permission_scope) if rel.permission_scope else []
            if required_scope not in allowed_scopes:
                log_security_event(
                    "permission_scope_denied",
                    user_id=actor.id,
                    details=f"scope_required={required_scope} scopes_held={allowed_scopes}",
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Your relationship does not have permission to '{required_scope}'.",
                )

        # Log audit access
        self.repo.log_access_event(
            user_id=actor.id,
            action="learner_data_viewed",
            resource_type="learner_data",
            resource_id=target_learner_id,
            target_user_id=target_learner_id,
            details=f"scope={required_scope or 'general'}",
        )
        return rel

    # -------------------------------------------------------------
    # INVITATIONS
    # -------------------------------------------------------------
    def create_invitation(
        self,
        inviter: User,
        invitee_email: str,
        relationship_type: str,
        target_learner_id: Optional[str] = None,
        permission_scope: Optional[List[str]] = None,
    ) -> RelationshipInvitation:
        # Validate role permissions to invite
        if inviter.role not in ["parent", "teacher", "specialist", "learner", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your account role cannot send relationship invitations.",
            )

        # If professional is inviting, target_learner_id is optional (can invite by email)
        # If learner is inviting a specialist/teacher, target_learner_id is inviter.id
        learner_id = target_learner_id
        if inviter.role == "learner":
            learner_id = inviter.id

        return self.repo.create_invitation(
            inviter_id=inviter.id,
            invitee_email=invitee_email,
            relationship_type=relationship_type,
            target_learner_id=learner_id,
            permission_scope=permission_scope,
        )

    def accept_invitation(self, token: str, accepting_user: User) -> Relationship:
        invitation = self.repo.get_invitation_by_token(token)
        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found or invalid token.",
            )
        try:
            return self.repo.accept_invitation(invitation, accepting_user)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )

    def reject_invitation(self, token: str, rejecting_user: User) -> RelationshipInvitation:
        invitation = self.repo.get_invitation_by_token(token)
        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found.",
            )
        return self.repo.reject_invitation(invitation, rejecting_user.id)

    def revoke_relationship(self, relationship_id: str, revoker: User) -> Relationship:
        rel = self.repo.get_relationship(relationship_id)
        if not rel:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Relationship not found.",
            )
        if rel.source_user_id != revoker.id and rel.target_user_id != revoker.id and revoker.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to revoke this relationship.",
            )
        return self.repo.revoke_relationship(rel, revoker.id)

    # -------------------------------------------------------------
    # ROLES LISTS (Parent children, Teacher students, Specialist caseload)
    # -------------------------------------------------------------
    def get_parent_children(self, parent_user: User) -> List[Dict[str, Any]]:
        rels = self.repo.list_actor_relationships(parent_user.id, relationship_type="parent")
        result = []
        for r in rels:
            learner = self.db.query(User).filter(User.id == r.target_user_id).first()
            if learner:
                prof = learner.profile
                scopes = json.loads(r.permission_scope) if r.permission_scope else []
                result.append({
                    "relationship_id": r.id,
                    "learner_id": learner.id,
                    "display_name": prof.display_name if prof else "Learner",
                    "age_band": prof.age_band if prof else "teen",
                    "support_focus": prof.support_focus if prof else "dld_track",
                    "guardian_consent_status": prof.guardian_consent_status if prof else "verified",
                    "status": r.status,
                    "permission_scope": scopes,
                    "created_at": r.created_at,
                })
        return result

    def get_teacher_students(self, teacher_user: User) -> List[Dict[str, Any]]:
        rels = self.repo.list_actor_relationships(teacher_user.id, relationship_type="teacher")
        result = []
        for r in rels:
            student = self.db.query(User).filter(User.id == r.target_user_id).first()
            if student:
                prof = student.profile
                assignments = self.repo.list_student_assignments(student.id)
                teacher_assignments = [a for a in assignments if a.teacher_id == teacher_user.id]
                completed_count = sum(1 for a in teacher_assignments if a.status == "completed")
                scopes = json.loads(r.permission_scope) if r.permission_scope else []

                result.append({
                    "relationship_id": r.id,
                    "student_id": student.id,
                    "display_name": prof.display_name if prof else "Student",
                    "age_band": prof.age_band if prof else "teen",
                    "support_focus": prof.support_focus if prof else "dld_track",
                    "assignments_total": len(teacher_assignments),
                    "assignments_completed": completed_count,
                    "permission_scope": scopes,
                    "status": r.status,
                })
        return result

    def get_specialist_caseload(self, specialist_user: User) -> List[Dict[str, Any]]:
        rels = self.repo.list_actor_relationships(specialist_user.id, relationship_type="specialist")
        result = []
        for r in rels:
            learner = self.db.query(User).filter(User.id == r.target_user_id).first()
            if learner:
                prof = learner.profile
                scopes = json.loads(r.permission_scope) if r.permission_scope else []
                # Check pending AI recommendations for this learner
                pending_recs = (
                    self.db.query(Recommendation)
                    .filter(
                        Recommendation.user_id == learner.id,
                        Recommendation.human_reviewed == False,  # noqa
                    )
                    .count()
                )

                result.append({
                    "relationship_id": r.id,
                    "learner_id": learner.id,
                    "display_name": prof.display_name if prof else "Learner",
                    "age_band": prof.age_band if prof else "teen",
                    "support_focus": prof.support_focus if prof else "dld_track",
                    "baseline_status": prof.baseline_status if prof else "not_started",
                    "pending_ai_recommendations": pending_recs,
                    "permission_scope": scopes,
                    "organization": r.organization,
                    "status": r.status,
                    "created_at": r.created_at,
                })
        return result

    # -------------------------------------------------------------
    # ASSIGNMENTS
    # -------------------------------------------------------------
    def create_assignment(
        self,
        teacher: User,
        student_id: str,
        lesson_id: str,
        title: str,
        instructions: Optional[str] = None,
        due_at: Optional[datetime] = None,
    ) -> Assignment:
        # Verify teacher has active relationship with student & 'create_assignment' scope
        self.verify_relationship_access(teacher, student_id, required_scope="create_assignment")

        lesson = self.db.query(Lesson).filter(Lesson.id == lesson_id).first()
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson not found.",
            )

        return self.repo.create_assignment(
            teacher_id=teacher.id,
            student_id=student_id,
            lesson_id=lesson_id,
            title=title,
            instructions=instructions,
            due_at=due_at,
        )

    # -------------------------------------------------------------
    # SPECIALIST AI RECOMMENDATION REVIEW & OVERRIDE
    # -------------------------------------------------------------
    def review_ai_recommendation(
        self,
        specialist: User,
        learner_id: str,
        recommendation_id: str,
        human_status: str,
        modified_reason: Optional[str] = None,
        modified_lesson_id: Optional[str] = None,
    ) -> Recommendation:
        """
        Specialist human oversight of an AI recommendation (Step 15, 16, 36, 37).
        Permitted statuses: 'approved', 'modified', 'rejected'.
        Crucial: Human override does NOT mutate underlying learner progress metrics!
        """
        if human_status not in ["approved", "modified", "rejected"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid human_status. Allowed values: 'approved', 'modified', 'rejected'.",
            )

        # Verify relationship & permission
        self.verify_relationship_access(specialist, learner_id, required_scope="review_ai_recommendations")

        rec = (
            self.db.query(Recommendation)
            .filter(
                Recommendation.id == recommendation_id,
                Recommendation.user_id == learner_id,
            )
            .first()
        )
        if not rec:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recommendation not found for this learner.",
            )

        rec.human_reviewed = True
        rec.human_status = human_status
        rec.human_reviewer_id = specialist.id

        if human_status == "modified" and modified_lesson_id:
            lesson_exists = self.db.query(Lesson).filter(Lesson.id == modified_lesson_id).first()
            if lesson_exists:
                rec.lesson_id = modified_lesson_id
            if modified_reason:
                rec.short_explanation = f"[Specialist note: {modified_reason}]"

        self.db.commit()
        self.db.refresh(rec)

        self.repo.log_access_event(
            user_id=specialist.id,
            action="ai_recommendation_reviewed",
            resource_type="recommendation",
            resource_id=rec.id,
            target_user_id=learner_id,
            details=f"status={human_status}",
        )
        log_security_event(
            "ai_recommendation_reviewed",
            user_id=specialist.id,
            details=f"rec_id={rec.id} learner={learner_id} status={human_status}",
        )
        return rec
