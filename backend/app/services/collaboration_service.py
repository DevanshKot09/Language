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

    # -------------------------------------------------------------
    # SPECIALIST MESSAGES & COLLABORATION CONVERSATIONS
    # -------------------------------------------------------------
    def get_specialist_conversations(
        self,
        specialist_user: User,
        filter_type: Optional[str] = None,
        search: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Retrieves authorized support conversations for the specialist.
        Respects RBAC, active relationships, and guardian consent state.
        Strictly non-diagnostic educational communication.
        """
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only educational and clinical specialists can access specialist conversations.",
            )

        spec_rels = self.repo.list_actor_relationships(specialist_user.id, relationship_type="specialist")
        if not spec_rels:
            return []

        conversations = []
        seen_ids = set()

        for idx, r in enumerate(spec_rels):
            learner = self.db.query(User).filter(User.id == r.target_user_id).first()
            if not learner:
                continue

            prof = learner.profile
            raw_name = prof.display_name if (prof and prof.display_name) else "Learner"
            learner_name = raw_name
            age_band = prof.age_band if prof else "child"
            consent_status = prof.guardian_consent_status if prof else "verified"
            is_child = (age_band in ["child", "teen"])

            # Query connected parents & teachers for this learner
            parent_rels = (
                self.db.query(Relationship)
                .filter(
                    Relationship.target_user_id == learner.id,
                    Relationship.relationship_type == "parent",
                    Relationship.status == "active",
                )
                .all()
            )
            parents = []
            for pr in parent_rels:
                pu = self.db.query(User).filter(User.id == pr.source_user_id).first()
                if pu:
                    p_name = pu.profile.display_name if (pu.profile and pu.profile.display_name) else "Parent"
                    parents.append({"user": pu, "name": p_name})

            teacher_rels = (
                self.db.query(Relationship)
                .filter(
                    Relationship.target_user_id == learner.id,
                    Relationship.relationship_type == "teacher",
                    Relationship.status == "active",
                )
                .all()
            )
            teachers = []
            for tr in teacher_rels:
                tu = self.db.query(User).filter(User.id == tr.source_user_id).first()
                if tu:
                    t_name = tu.profile.display_name if (tu.profile and tu.profile.display_name) else "Teacher"
                    org = tr.organization or "Oakridge Elementary"
                    teachers.append({"user": tu, "name": t_name, "organization": org})

            is_locked = (is_child and consent_status != "verified")
            first_name = learner_name.split()[0]

            # 1. Group / Support Circle Conversation
            group_conv_id = f"group_{learner.id}"
            if group_conv_id not in seen_ids:
                seen_ids.add(group_conv_id)
                if is_locked:
                    conversations.append({
                        "id": group_conv_id,
                        "conversation_type": "group",
                        "category": "teams",
                        "title": f"{first_name}'s Support Circle",
                        "subtitle": "Guardian Consent Pending",
                        "roles": ["Parent", "Teacher", "Specialist"],
                        "last_message_sender": None,
                        "last_message_text": "Audio turns and session notes locked until guardian sign-off.",
                        "last_message_time": "Oct 15",
                        "unread_count": 0,
                        "is_pinned": False,
                        "is_online": False,
                        "consent_status": consent_status,
                        "is_locked": True,
                        "lock_reason": "Audio turns and session notes locked until guardian sign-off.",
                        "target_learner_id": learner.id,
                        "target_learner_name": learner_name,
                        "avatar_type": "locked_child",
                        "avatar_badge": "locked",
                        "participant_names": [p["name"] for p in parents] + [t["name"] for t in teachers],
                    })
                elif is_child:
                    p_label = parents[0]["name"].split()[0] if parents else "Priya M."
                    conversations.append({
                        "id": group_conv_id,
                        "conversation_type": "group",
                        "category": "teams",
                        "title": f"{first_name}'s Support Circle",
                        "subtitle": "Parent · Teacher · Specialist",
                        "roles": ["Parent", "Teacher", "Specialist"],
                        "last_message_sender": f"{p_label}:",
                        "last_message_text": "Can we discuss tomorrow's phonics practice...",
                        "last_message_time": "10:42 AM",
                        "unread_count": 2,
                        "is_pinned": (idx == 0),
                        "is_online": True,
                        "consent_status": "verified",
                        "is_locked": False,
                        "lock_reason": None,
                        "target_learner_id": learner.id,
                        "target_learner_name": learner_name,
                        "avatar_type": "dual",
                        "avatar_badge": "online",
                        "participant_names": [p["name"] for p in parents] + [t["name"] for t in teachers],
                    })
                else:
                    # Adult learner
                    t_label = teachers[0]["name"].split()[0] if teachers else "David W."
                    conversations.append({
                        "id": group_conv_id,
                        "conversation_type": "group",
                        "category": "teams",
                        "title": f"{first_name}'s Learning Circle",
                        "subtitle": "Adult Learner · Teacher · Specialist",
                        "roles": ["Adult Learner", "Teacher", "Specialist"],
                        "last_message_sender": f"{t_label}:",
                        "last_message_text": "Next week's fluency review is ready.",
                        "last_message_time": "Yesterday",
                        "unread_count": 0,
                        "is_pinned": False,
                        "is_online": False,
                        "consent_status": "verified",
                        "is_locked": False,
                        "lock_reason": None,
                        "target_learner_id": learner.id,
                        "target_learner_name": learner_name,
                        "avatar_type": "team_teal",
                        "avatar_badge": "team",
                        "participant_names": [learner_name] + [t["name"] for t in teachers],
                    })

            # 2. Direct parent conversation (if active and not consent locked)
            if not is_locked:
                for p in parents:
                    p_conv_id = f"direct_parent_{p['user'].id}_{learner.id}"
                    if p_conv_id not in seen_ids:
                        seen_ids.add(p_conv_id)
                        conversations.append({
                            "id": p_conv_id,
                            "conversation_type": "direct",
                            "category": "learners",
                            "title": p["name"],
                            "subtitle": f"{first_name}'s Primary Guardian",
                            "roles": ["Parent"],
                            "last_message_sender": None,
                            "last_message_text": f"Thank you for the quick turn summary! {first_name} loved the star activity.",
                            "last_message_time": "Oct 16",
                            "unread_count": 0,
                            "is_pinned": False,
                            "is_online": True,
                            "consent_status": "verified",
                            "is_locked": False,
                            "lock_reason": None,
                            "target_learner_id": learner.id,
                            "target_learner_name": learner_name,
                            "avatar_type": "parent_online",
                            "avatar_badge": "online",
                            "participant_names": [p["name"]],
                        })

                # 3. Direct teacher conversation
                for t in teachers:
                    t_conv_id = f"direct_teacher_{t['user'].id}_{learner.id}"
                    if t_conv_id not in seen_ids:
                        seen_ids.add(t_conv_id)
                        conversations.append({
                            "id": t_conv_id,
                            "conversation_type": "direct",
                            "category": "learners",
                            "title": t["name"],
                            "subtitle": f"Classroom Educator · {t['organization']}",
                            "roles": ["Teacher"],
                            "last_message_sender": None,
                            "last_message_text": "Shared classroom reading observations and notes.",
                            "last_message_time": "Oct 14",
                            "unread_count": 0,
                            "is_pinned": False,
                            "is_online": False,
                            "consent_status": "verified",
                            "is_locked": False,
                            "lock_reason": None,
                            "target_learner_id": learner.id,
                            "target_learner_name": learner_name,
                            "avatar_type": "teacher_book",
                            "avatar_badge": "book",
                            "participant_names": [t["name"]],
                        })

        # Apply filtering
        if filter_type:
            ft = filter_type.strip().lower()
            if ft == "unread":
                conversations = [c for c in conversations if c["unread_count"] > 0]
            elif ft == "teams":
                conversations = [c for c in conversations if c["category"] == "teams"]
            elif ft in ["learners", "learner"]:
                conversations = [c for c in conversations if c["category"] == "learners"]

        # Apply search
        if search and search.strip():
            q = search.strip().lower()
            conversations = [
                c for c in conversations
                if q in c["title"].lower()
                or q in c["subtitle"].lower()
                or (c.get("target_learner_name") and q in c["target_learner_name"].lower())
                or (c.get("last_message_sender") and q in c["last_message_sender"].lower())
                or q in c["last_message_text"].lower()
                or any(q in p.lower() for p in c.get("participant_names", []))
            ]

        # Sort pinned first
        conversations.sort(key=lambda c: 0 if c["is_pinned"] else 1)
        return conversations

    # -------------------------------------------------------------
    # CONVERSATION MESSAGES & SENDING
    # -------------------------------------------------------------
    _MESSAGE_STORE: Dict[str, List[Dict[str, Any]]] = {}

    def _get_initial_messages(self, conversation_id: str) -> List[Dict[str, Any]]:
        if conversation_id not in self._MESSAGE_STORE:
            if "sofia" in conversation_id:
                # Locked state - audio turns and session notes locked until consent verified
                self._MESSAGE_STORE[conversation_id] = [
                    {
                        "id": "msg_sofia_1",
                        "conversation_id": conversation_id,
                        "sender_id": "system",
                        "sender_name": "System Notice",
                        "sender_role": "system",
                        "sender_role_label": "System",
                        "avatar_url": None,
                        "avatar_initials": "SN",
                        "content": "Audio turns and session notes locked until guardian sign-off.",
                        "timestamp": "Oct 15",
                        "date_group": "Oct 15",
                        "is_self": False,
                        "delivery_status": "delivered",
                        "attachment": None,
                    }
                ]
            elif "maya" in conversation_id:
                self._MESSAGE_STORE[conversation_id] = [
                    {
                        "id": "msg_maya_1",
                        "conversation_id": conversation_id,
                        "sender_id": "user_david",
                        "sender_name": "David W.",
                        "sender_role": "teacher",
                        "sender_role_label": "Teacher",
                        "avatar_url": None,
                        "avatar_initials": "DW",
                        "content": "Next week's fluency review is ready for Maya.",
                        "timestamp": "Yesterday",
                        "date_group": "Yesterday",
                        "is_self": False,
                        "delivery_status": "delivered",
                        "attachment": None,
                    }
                ]
            else:
                # Primary Stitch Collaboration Thread (e.g. Aarav Sharma & Child Support Circles)
                self._MESSAGE_STORE[conversation_id] = [
                    {
                        "id": "msg_aarav_1",
                        "conversation_id": conversation_id,
                        "sender_id": "user_priya",
                        "sender_name": "Priya Mehta",
                        "sender_role": "parent",
                        "sender_role_label": "Parent",
                        "avatar_url": None,
                        "avatar_initials": "PM",
                        "content": "Good morning Dr. Maya! Aarav really enjoyed the phonics card game yesterday. He was practicing the /r/ blends during bedtime reading without any prompting! 🪅",
                        "timestamp": "10:38 AM",
                        "date_group": "Yesterday",
                        "is_self": False,
                        "delivery_status": "delivered",
                        "attachment": None,
                    },
                    {
                        "id": "msg_aarav_2",
                        "conversation_id": conversation_id,
                        "sender_id": "user_davies",
                        "sender_name": "Mrs. Davies",
                        "sender_role": "teacher",
                        "sender_role_label": "Teacher • Oakridge",
                        "avatar_url": None,
                        "avatar_initials": "ED",
                        "content": "I noticed the same in class today during reading circle! He was eager to raise his hand. Should we reinforce the same syllable cards this Thursday?",
                        "timestamp": "10:41 AM",
                        "date_group": "Yesterday",
                        "is_self": False,
                        "delivery_status": "delivered",
                        "attachment": None,
                    },
                    {
                        "id": "msg_aarav_3",
                        "conversation_id": conversation_id,
                        "sender_id": "user_specialist",
                        "sender_name": "You (Specialist)",
                        "sender_role": "specialist",
                        "sender_role_label": "You (Specialist)",
                        "avatar_url": None,
                        "avatar_initials": "MS",
                        "content": "That is wonderful progress! Yes Eleanor, continuing with two-syllable /r/ clusters will build strong retention. I've attached the tailored card set we used in our live session.",
                        "timestamp": "10:45 AM",
                        "date_group": "Today",
                        "is_self": True,
                        "delivery_status": "delivered",
                        "attachment": {
                            "id": "att_1",
                            "filename": "Phoneme_Pacing_Cards.pdf",
                            "file_size_label": "2.4 MB",
                            "file_type": "pdf",
                            "category_label": "Guided Practice",
                            "download_url": "/api/v1/specialist/attachments/att_1",
                        },
                    },
                    {
                        "id": "msg_aarav_4",
                        "conversation_id": conversation_id,
                        "sender_id": "user_priya",
                        "sender_name": "Priya Mehta",
                        "sender_role": "parent",
                        "sender_role_label": None,
                        "avatar_url": None,
                        "avatar_initials": "PM",
                        "content": "Downloaded! Will practice this evening before our 10:30 AM session tomorrow. ✨",
                        "timestamp": "10:48 AM",
                        "date_group": "Today",
                        "is_self": False,
                        "delivery_status": "delivered",
                        "attachment": None,
                    },
                ]
        return self._MESSAGE_STORE[conversation_id]

    def get_conversation_messages(
        self,
        specialist_user: User,
        conversation_id: str,
    ) -> List[Dict[str, Any]]:
        # Enforce role
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only verified Specialists or Admins can access support conversations.",
            )

        messages = self._get_initial_messages(conversation_id)
        return messages

    def send_conversation_message(
        self,
        specialist_user: User,
        conversation_id: str,
        content: str,
        attachment_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only verified Specialists or Admins can send messages in support conversations.",
            )

        if not content or not content.strip():
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Message content cannot be empty.",
            )

        # Ensure conversation message list exists
        messages = self._get_initial_messages(conversation_id)

        import uuid
        now = datetime.now(timezone.utc)
        time_str = now.strftime("%I:%M %p").lstrip("0")

        attachment_data = None
        if attachment_id:
            attachment_data = {
                "id": attachment_id,
                "filename": "Specialist_Resource.pdf",
                "file_size_label": "1.8 MB",
                "file_type": "pdf",
                "category_label": "Guided Practice",
                "download_url": f"/api/v1/specialist/attachments/{attachment_id}",
            }

        sender_name = "Specialist"
        if specialist_user.profile and specialist_user.profile.display_name:
            sender_name = specialist_user.profile.display_name

        new_msg = {
            "id": f"msg_{uuid.uuid4().hex[:8]}",
            "conversation_id": conversation_id,
            "sender_id": specialist_user.id,
            "sender_name": sender_name,
            "sender_role": "specialist",
            "sender_role_label": "You (Specialist)",
            "avatar_url": None,
            "avatar_initials": "MS",
            "content": content.strip(),
            "timestamp": time_str,
            "date_group": "Today",
            "is_self": True,
            "delivery_status": "delivered",
            "attachment": attachment_data,
            "created_at": now,
        }

        messages.append(new_msg)
        return new_msg

