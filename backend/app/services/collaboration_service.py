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

    # -------------------------------------------------------------
    # SESSION SUMMARY & NOTES (SPECIALIST WORKSPACE)
    # -------------------------------------------------------------
    _SESSION_SUMMARY_STORE: Dict[str, Dict[str, Any]] = {}

    def save_session_summary(
        self,
        specialist_user: User,
        summary_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Saves specialist session observations, progress outcome, and next steps.
        Enforces:
        1. Role authorization (specialist or admin)
        2. Non-diagnostic educational terminology validation
        3. Persistence in Report storage and memory cache
        """
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only verified Specialists can save session summaries.",
            )

        notes = summary_data.get("notes", "")
        lower_notes = notes.lower()
        for banned in [
            "clinical diagnosis",
            "medical prognosis",
            "disorder level",
            "disorder severity",
            "treatment plan",
            "prescription",
            "medication",
        ]:
            if banned in lower_notes:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"Non-diagnostic guideline violation: '{banned}' is prohibited in educational session notes.",
                )

        learner_id = summary_data.get("learner_id", "")
        learner_name = summary_data.get("learner_name", "Learner")
        session_id = summary_data.get("session_id") or f"sess_{uuid.uuid4().hex[:8]}"
        now = datetime.now(timezone.utc)

        creator_name = "Dr. Specialist"
        if specialist_user.profile and specialist_user.profile.display_name:
            creator_name = specialist_user.profile.display_name
        elif specialist_user.email:
            creator_name = specialist_user.email.split("@")[0].title()

        disclaimer = (
            "This session summary documents learning-support observations within LINGUA AI. "
            "It is strictly educational and non-diagnostic."
        )

        response_payload = {
            "id": f"summary_{uuid.uuid4().hex[:8]}",
            "session_id": session_id,
            "creator_id": specialist_user.id,
            "creator_name": creator_name,
            "learner_id": learner_id,
            "learner_name": learner_name,
            "learner_age_band": summary_data.get("learner_age_band", "Child • 10 yrs"),
            "session_date": summary_data.get("session_date", "Today, Oct 17"),
            "session_time": summary_data.get("session_time", "10:30 – 11:02 AM"),
            "session_duration_minutes": int(summary_data.get("session_duration_minutes", 31)),
            "session_type": summary_data.get("session_type", "1-to-1 Live Support"),
            "target_focus": summary_data.get("target_focus", "/r/ Blends"),
            "cards_completed": int(summary_data.get("cards_completed", 8)),
            "pacing_rhythm_percentage": int(summary_data.get("pacing_rhythm_percentage", 88)),
            "audio_reflections_count": int(summary_data.get("audio_reflections_count", 1)),
            "working_areas": summary_data.get("working_areas", ["Phonics & Blends", "Speaking & Pacing", "Reading Aloud"]),
            "notes": notes,
            "outcome": summary_data.get("outcome", "great_progress"),
            "next_practice_focus": summary_data.get("next_practice_focus", "Consonant Clusters (/rk/, /st/) in 2-syllable words"),
            "follow_up_actions": summary_data.get("follow_up_actions", []),
            "next_scheduled_session": summary_data.get("next_scheduled_session", "Friday, Oct 25 • 10:30 AM"),
            "status": "completed",
            "created_at": now,
            "disclaimer": disclaimer,
        }

        # Store in cache indexed by session_id and learner_id
        self._SESSION_SUMMARY_STORE[session_id] = response_payload
        self._SESSION_SUMMARY_STORE[f"learner_{learner_id}"] = response_payload

        # Also persist to database as a Report record if db is available
        try:
            report = Report(
                creator_id=specialist_user.id,
                learner_id=learner_id if (learner_id and not learner_id.startswith("lr-")) else specialist_user.id,
                report_type="specialist_summary",
                title=f"{learner_name} — Session Summary & Notes",
                summary_data=json.dumps(response_payload, default=str),
                disclaimer=disclaimer,
                status="active",
            )
            self.db.add(report)
            self.db.commit()
            response_payload["id"] = report.id
        except Exception:
            self.db.rollback()

        log_security_event(
            "session_summary_saved",
            user_id=specialist_user.id,
            details=f"session_id={session_id} learner={learner_id} outcome={response_payload['outcome']}",
        )

        return response_payload

    def get_session_summary(
        self,
        specialist_user: User,
        session_id: Optional[str] = None,
        learner_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Retrieves the latest session summary for the session or learner.
        """
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only verified Specialists can view session summaries.",
            )

        if session_id and session_id in self._SESSION_SUMMARY_STORE:
            return self._SESSION_SUMMARY_STORE[session_id]

        if learner_id and f"learner_{learner_id}" in self._SESSION_SUMMARY_STORE:
            return self._SESSION_SUMMARY_STORE[f"learner_{learner_id}"]

        # Query database for recent report
        query = self.db.query(Report).filter(Report.report_type == "specialist_summary")
        if learner_id:
            query = query.filter(Report.learner_id == learner_id)
        report = query.order_by(Report.created_at.desc()).first()

        if report:
            try:
                data = json.loads(report.summary_data)
                return data
            except Exception:
                pass

        # Return default Stitch initial state for Aarav Mehta
        now = datetime.now(timezone.utc)
        return {
            "id": "summary_aarav_default",
            "session_id": session_id or "sess_live_001",
            "creator_id": specialist_user.id,
            "creator_name": "Dr. Sarah Jenkins",
            "learner_id": learner_id or "learner-aarav",
            "learner_name": "Aarav Mehta",
            "learner_age_band": "Child • 10 yrs",
            "session_date": "Today, Oct 17",
            "session_time": "10:30 – 11:02 AM",
            "session_duration_minutes": 31,
            "session_type": "1-to-1 Live Support",
            "target_focus": "/r/ Blends",
            "cards_completed": 8,
            "pacing_rhythm_percentage": 88,
            "audio_reflections_count": 1,
            "working_areas": ["Phonics & Blends", "Speaking & Pacing", "Reading Aloud"],
            "notes": "",
            "outcome": "great_progress",
            "next_practice_focus": "Consonant Clusters (/rk/, /st/) in 2-syllable words",
            "follow_up_actions": [
                "Send tailored /r/ practice cards to Parent",
                "Share session highlight with Teacher",
            ],
            "next_scheduled_session": "Friday, Oct 25 • 10:30 AM",
            "status": "draft",
            "created_at": now,
            "disclaimer": "Educational non-diagnostic learning support summary.",
        }

    # -------------------------------------------------------------
    # 10. SPECIALIST PROFILE, NOTIFICATIONS, & CONSENT CIRCLES
    # -------------------------------------------------------------
    _PROFILE_STORE: Dict[str, Dict[str, Any]] = {}
    _NOTIFICATIONS_STORE: Dict[str, List[Dict[str, Any]]] = {}
    _CONSENT_STORE: Dict[str, List[Dict[str, Any]]] = {}

    def get_specialist_profile(self, specialist_user: User) -> Dict[str, Any]:
        """Returns verified specialist professional profile."""
        if specialist_user.role not in ["specialist", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only registered Specialists can access specialist profile.",
            )
        if specialist_user.id in self._PROFILE_STORE:
            return self._PROFILE_STORE[specialist_user.id]

        prof = specialist_user.profile
        raw_name = prof.display_name if (prof and prof.display_name) else "Maya Reynolds, M.S."

        data = {
            "id": specialist_user.id,
            "display_name": raw_name,
            "professional_title": "Learning Support Specialist (CCC-SLP)",
            "is_verified": True,
            "verification_badge": "VERIFIED SPECIALIST • LINGUA SAFE",
            "location": "San Francisco, CA",
            "availability_spots": 3,
            "active_learners_count": 8,
            "rating": 4.9,
            "reviews_count": 42,
            "experience_years": 5,
            "profile_visibility": "Parents & Learners",
            "about_me": "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading...",
            "full_bio": (
                "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic "
                "awareness, speech pacing, and reading fluency. With over 8 years of clinical and "
                "educational practice, I specialize in pediatric speech scaffolding, multi-sensory "
                "phonics exercises, and cross-collaborative support between families and classroom educators."
            ),
            "support_focus_areas": [
                "Reading Fluency",
                "Speech & Pacing",
                "Phonics & Spelling",
                "Vocabulary Growth",
                "Story Expression",
                "Active Listening",
                "Tactile Game Play",
            ],
            "practice_details": {
                "experience": "8+ Years Pediatric Practice",
                "languages": "English (Native), Spanish (Conversational)",
                "age_groups": "Preschool (3–5), Elementary (6–10), Teens (11–16)",
                "supported_formats": "1-on-1 Interactive Audio & Video, Asynchronous Practice Reviews",
            },
            "credentials": [
                {
                    "title": "M.S. in Speech & Hearing Sciences",
                    "subtitle": "University of Washington • Verified",
                    "type": "degree",
                },
                {
                    "title": "Clinical Competence Certificate (CCC-SLP)",
                    "subtitle": "Active National Standing • Current",
                    "type": "license",
                },
                {
                    "title": "Lingua AI Child-Safe & HIPAA Verified",
                    "subtitle": "Annual Review Complete • 2024",
                    "type": "safety",
                },
            ],
            "disclaimer": "Lingua AI provides developmental learning facilitation and educational practice.",
            "privacy_reassurance": (
                "Only details you approve are shared with families. Protected by the Lingua AI Child-Safe Guarantee."
            ),
        }
        self._PROFILE_STORE[specialist_user.id] = data
        return data

    def update_specialist_profile(self, specialist_user: User, data: Dict[str, Any]) -> Dict[str, Any]:
        """Updates specialist profile information in memory/db."""
        current = self.get_specialist_profile(specialist_user)
        for key, value in data.items():
            if value is not None:
                current[key] = value
        self._PROFILE_STORE[specialist_user.id] = current
        return current

    def get_specialist_notifications(
        self,
        specialist_user: User,
        category: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Returns organized specialist notifications matching Stitch visual reference."""
        if specialist_user.id not in self._NOTIFICATIONS_STORE:
            self._NOTIFICATIONS_STORE[specialist_user.id] = [
                {
                    "id": "notif_001",
                    "title": "Live session with Aarav in 30m",
                    "supporting_text": "1-to-1 phonics & consonant clusters practice. Virtual room is primed.",
                    "timestamp": "10:00 AM",
                    "time_group": "Today",
                    "category": "sessions",
                    "badge_label": "INTERACTIVE AUDIO",
                    "badge_type": "interactive_audio",
                    "is_read": False,
                    "action_type": "join_session",
                    "action_label": "Join Session →",
                    "target_id": "sess_live_001",
                    "icon_type": "video",
                },
                {
                    "id": "notif_002",
                    "title": "Priya Mehta accepted support c...",
                    "supporting_text": "Guardian consent verified for Aarav's audio pacing & articulation logs.",
                    "timestamp": "9:15 AM",
                    "time_group": "Today",
                    "category": "learners",
                    "badge_label": "CONSENT LOGGED",
                    "badge_type": "consent_logged",
                    "is_read": False,
                    "action_type": "review_details",
                    "action_label": "Review Details",
                    "target_id": "consent_aarav",
                    "icon_type": "shield",
                },
                {
                    "id": "notif_003",
                    "title": "New note from Mrs. Davies (Tea...",
                    "supporting_text": "“Aarav raised his hand during story circle today! His /r/ sound was so clear.”",
                    "timestamp": "8:45 AM",
                    "time_group": "Today",
                    "category": "messages",
                    "badge_label": "CLASSROOM SYNERGY",
                    "badge_type": "classroom_synergy",
                    "is_read": False,
                    "action_type": "open_chat",
                    "action_label": "↩ Open Chat",
                    "target_id": "conv-aarav",
                    "icon_type": "chat",
                },
                {
                    "id": "notif_004",
                    "title": "Weekly progress summary gene...",
                    "supporting_text": "Sofia K. completed 14 vocabulary speech decks with 92% pronunciation...",
                    "timestamp": "Yesterday, 4:20 PM",
                    "time_group": "Yesterday & Earlier",
                    "category": "learners",
                    "badge_label": None,
                    "badge_type": None,
                    "is_read": True,
                    "action_type": "view_deck",
                    "action_label": "View Learning Deck →",
                    "target_id": "deck_sofia",
                    "icon_type": "analytics",
                },
                {
                    "id": "notif_005",
                    "title": "Availability slot approved",
                    "supporting_text": "New recurring Friday 10:30 AM specialist slot confirmed by curriculum...",
                    "timestamp": "Oct 15",
                    "time_group": "Yesterday & Earlier",
                    "category": "team",
                    "badge_label": None,
                    "badge_type": None,
                    "is_read": True,
                    "action_type": "manage_schedule",
                    "action_label": "Manage Schedule",
                    "target_id": "schedule_main",
                    "icon_type": "calendar",
                },
            ]

        all_items = self._NOTIFICATIONS_STORE[specialist_user.id]
        if category and category.lower() != "all":
            filtered = [i for i in all_items if i.get("category") == category.lower()]
        else:
            filtered = all_items

        unread = len([i for i in all_items if not i.get("is_read", False)])
        today_count = len([i for i in all_items if i.get("time_group") == "Today" and not i.get("is_read", False)])

        return {
            "notifications": filtered,
            "unread_count": unread,
            "today_count": today_count,
            "filter": category or "all",
        }

    def mark_notification_read(self, specialist_user: User, notification_id: str) -> Dict[str, Any]:
        """Marks a single notification as read."""
        items = self._NOTIFICATIONS_STORE.get(specialist_user.id, [])
        for item in items:
            if item.get("id") == notification_id:
                item["is_read"] = True
                return {"message": "Notification marked as read.", "notification": item}
        return {"message": "Notification updated."}

    def mark_all_notifications_read(self, specialist_user: User) -> Dict[str, Any]:
        """Marks all notifications for specialist as read."""
        items = self._NOTIFICATIONS_STORE.get(specialist_user.id, [])
        for item in items:
            item["is_read"] = True
        return {"message": "All notifications marked as read.", "count": len(items)}

    def get_specialist_consent_circles(self, specialist_user: User) -> Dict[str, Any]:
        """Returns permission-based consent circles matching Stitch visual reference."""
        if specialist_user.id not in self._CONSENT_STORE:
            self._CONSENT_STORE[specialist_user.id] = [
                {
                    "id": "circle_aarav",
                    "learner_id": "learner-aarav",
                    "learner_name": "Aarav Mehta",
                    "learner_initials": "AM",
                    "status": "active",
                    "status_label": "✓ Active",
                    "subtitle": "Learner • 10 yrs • Grade 4",
                    "collaboration_circle": [
                        {"name": "Priya Mehta", "role_label": "(Guardian)", "initial": "P", "is_specialist": False},
                        {"name": "Mrs. Davies", "role_label": "(Teacher)", "initial": "D", "is_specialist": False},
                        {"name": "You", "role_label": "(Specialist)", "initial": "★", "is_specialist": True},
                    ],
                    "permission_scopes": [
                        {
                            "key": "practice_audio",
                            "title": "Practice Audio & Speech ...",
                            "is_shared": True,
                            "status_label": "Shared",
                            "icon_type": "mic",
                        },
                        {
                            "key": "weekly_progress",
                            "title": "Weekly Progress & Miles...",
                            "is_shared": True,
                            "status_label": "Shared",
                            "icon_type": "trend",
                        },
                        {
                            "key": "practice_sessions",
                            "title": "1-on-1 Practice Session ...",
                            "is_shared": True,
                            "status_label": "Shared",
                            "icon_type": "chat",
                        },
                        {
                            "key": "phonics_games",
                            "title": "Phonics Games & Word ...",
                            "is_shared": True,
                            "status_label": "Shared",
                            "icon_type": "puzzle",
                        },
                        {
                            "key": "raw_classroom",
                            "title": "Raw Classroom Ambi...",
                            "is_shared": False,
                            "status_label": "Not Shared",
                            "icon_type": "mic_off",
                        },
                    ],
                    "consent_reconfirmed_date": "Oct 12, 2024",
                    "updated_time_ago": "Oct 12, 2024",
                    "avatar_color": "purple",
                },
                {
                    "id": "circle_sophia",
                    "learner_id": "learner-sophia",
                    "learner_name": "Sophia Chen",
                    "learner_initials": "SC",
                    "status": "limited",
                    "status_label": "⇄ Limited",
                    "subtitle": "Teen Learner • 15 yrs • Self-directed",
                    "collaboration_circle": [
                        {"name": "Sophia Chen", "role_label": "(Learner / Self)", "initial": "SC", "is_specialist": False},
                        {"name": "You", "role_label": "(Specialist)", "initial": "★", "is_specialist": True},
                    ],
                    "permission_scopes": [
                        {
                            "key": "reading_fluency",
                            "title": "Reading Fluency & Sum...",
                            "is_shared": True,
                            "status_label": "Shared",
                            "icon_type": "book",
                        },
                        {
                            "key": "raw_practice_audio",
                            "title": "Raw Practice Audi...",
                            "is_shared": False,
                            "status_label": "Learner Private",
                            "icon_type": "mic_off",
                        },
                    ],
                    "consent_reconfirmed_date": None,
                    "updated_time_ago": "3 days ago",
                    "avatar_color": "amber",
                },
            ]

        circles = self._CONSENT_STORE[specialist_user.id]
        active_count = len([c for c in circles if c.get("status") == "active"])
        return {
            "circles": circles,
            "active_count": active_count,
            "privacy_notice": (
                "Learner privacy is our priority. Guardians or adult learners can pause, "
                "reconfigure, or withdraw specialization scopes at any time directly through their profile."
            ),
        }

    def update_consent_circle_scope(
        self,
        specialist_user: User,
        circle_id: str,
        scope_key: str,
        shared: bool,
    ) -> Dict[str, Any]:
        """Toggles a permission scope inside a consent circle."""
        circles = self.get_specialist_consent_circles(specialist_user)["circles"]
        for circle in circles:
            if circle.get("id") == circle_id:
                for s in circle.get("permission_scopes", []):
                    if s.get("key") == scope_key:
                        s["is_shared"] = shared
                        s["status_label"] = "Shared" if shared else "Not Shared"
                        return {"message": "Scope updated.", "circle": circle}
        return {"message": "Scope updated."}

    # -------------------------------------------------------------
    # SPECIALIST AVAILABILITY & APPOINTMENTS (STITCH REFERENCE)
    # -------------------------------------------------------------
    _AVAILABILITY_STORE: Dict[str, Dict[str, Any]] = {}

    def get_specialist_availability(self, specialist_user: User) -> Dict[str, Any]:
        """Returns specialist schedule, session preferences, and daily caps."""
        if specialist_user.id not in self._AVAILABILITY_STORE:
            self._AVAILABILITY_STORE[specialist_user.id] = {
                "specialist_name": "Dr. Maya Lin, M.S. CCC-SLP",
                "specialist_title": "Pediatric Speech & Phoneme Coaching",
                "specialist_badge": "LINGUA SPECIALIST • Active Caseload",
                "available_for_sessions": True,
                "timezone": "Pacific Time (GMT-7)",
                "session_duration_minutes": 45,
                "buffer_minutes": 15,
                "daily_session_cap": 5,
                "advance_notice": "24h Notice",
                "days": [
                    {
                        "day_key": "monday",
                        "day_label": "Monday",
                        "initial": "M",
                        "is_enabled": True,
                        "subtitle": "2 Slots Active",
                        "slots": [
                            {"id": "mon_slot_1", "time_range": "9:00 AM – 12:00 PM", "icon_type": "sun"},
                            {"id": "mon_slot_2", "time_range": "1:30 PM – 5:00 PM", "icon_type": "sparkle"},
                        ],
                    },
                    {
                        "day_key": "tuesday",
                        "day_label": "Tuesday",
                        "initial": "T",
                        "is_enabled": True,
                        "subtitle": "1 Slot Active",
                        "slots": [
                            {"id": "tue_slot_1", "time_range": "10:00 AM – 3:30 PM", "icon_type": "sun"},
                        ],
                    },
                    {
                        "day_key": "wednesday",
                        "day_label": "Wednesday",
                        "initial": "W",
                        "is_enabled": True,
                        "subtitle": "2 Slots Active",
                        "slots": [
                            {"id": "wed_slot_1", "time_range": "9:00 AM – 12:00 PM", "icon_type": "sun"},
                            {"id": "wed_slot_2", "time_range": "1:30 PM – 4:30 PM", "icon_type": "sparkle"},
                        ],
                    },
                    {
                        "day_key": "thursday_friday",
                        "day_label": "Thursday & Friday",
                        "initial": "TF",
                        "is_enabled": True,
                        "subtitle": "Standard Afternoon blocks (1:00 - 5:00 PM)",
                        "slots": [
                            {"id": "tf_slot_1", "time_range": "1:00 PM – 5:00 PM", "icon_type": "sun"},
                        ],
                    },
                    {
                        "day_key": "saturday",
                        "day_label": "Saturday",
                        "initial": "S",
                        "is_enabled": False,
                        "subtitle": "Day off • Dedicated rest & prep",
                        "slots": [],
                    },
                    {
                        "day_key": "sunday",
                        "day_label": "Sunday",
                        "initial": "S",
                        "is_enabled": False,
                        "subtitle": "Day off • Family & recharge",
                        "slots": [],
                    },
                ],
            }
        return self._AVAILABILITY_STORE[specialist_user.id]

    def update_specialist_availability(
        self,
        specialist_user: User,
        update_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Updates specialist availability preferences."""
        current = self.get_specialist_availability(specialist_user)
        for key, val in update_data.items():
            if val is not None:
                current[key] = val
        self._AVAILABILITY_STORE[specialist_user.id] = current
        return current

    # -------------------------------------------------------------
    # SPECIALIST VERIFICATION STATUS (STITCH REFERENCE)
    # -------------------------------------------------------------
    def get_specialist_verification(self, specialist_user: User) -> Dict[str, Any]:
        """Returns verification status, review milestones, and certified credentials."""
        return {
            "verification_status": "verified",
            "status_badge": "PROFILE VERIFIED",
            "headline": "Your profile is verified",
            "description": (
                "Your specialist credentials and child-safety background checks are confirmed. "
                "Families and schools can discover your profile and book sessions."
            ),
            "verification_date_text": "Verified Oct 14, 2024 • Next check: Oct 2025",
            "milestones_completed": 5,
            "milestones_total": 5,
            "milestones": [
                {"key": "profile", "label": "Profile", "is_completed": True, "is_current": False},
                {"key": "details", "label": "Details", "is_completed": True, "is_current": False},
                {"key": "degrees", "label": "Degrees", "is_completed": True, "is_current": False},
                {"key": "review", "label": "Review", "is_completed": True, "is_current": False},
                {"key": "badge", "label": "Badge", "is_completed": True, "is_current": True},
            ],
            "specialist_name": "Maya Reynolds, M.S.",
            "specialist_initials": "MR",
            "specialist_role_subtitle": "Learning Support Specialist (CCC-SLP)",
            "experience_text": "8+ Yrs Pediatric",
            "languages_text": "English, Spanish",
            "approved_domains": [
                "Reading Fluency",
                "Speech & Pacing",
                "Phonics & Spelling",
                "Vocabulary Growth",
            ],
            "verified_documents": [
                {
                    "id": "doc_degree",
                    "title": "M.S. in Speech & Hearing Sciences",
                    "subtitle": "University of Washington • Conferred 2016",
                    "status_label": "Approved",
                    "icon_type": "grad_cap",
                    "is_approved": True,
                },
                {
                    "id": "doc_cert",
                    "title": "Clinical Competence Certification (CCC-SLP)",
                    "subtitle": "National Board Validated • Active Good Standing",
                    "status_label": "Approved",
                    "icon_type": "certificate",
                    "is_approved": True,
                },
                {
                    "id": "doc_clearance",
                    "title": "Child-Safe & Background Clearance",
                    "subtitle": "Comprehensive Youth Safety Check • Passed",
                    "status_label": "Cleared",
                    "icon_type": "shield",
                    "is_approved": True,
                },
            ],
            "compliance_notice": "Encrypted • FERPA Compliant",
        }

    # -------------------------------------------------------------
    # SPECIALIST HELP & SUPPORT (STITCH REFERENCE)
    # -------------------------------------------------------------
    def get_specialist_help(self, specialist_user: User) -> Dict[str, Any]:
        """Returns help topics, FAQs, and support channels."""
        return {
            "categories": [
                {"id": "account", "title": "Account", "subtitle": "Profile & cred...", "icon_type": "person", "color": "purple"},
                {"id": "sessions", "title": "Sessions", "subtitle": "Rooms, audio ...", "icon_type": "video", "color": "teal"},
                {"id": "learners", "title": "Learners", "subtitle": "Rosters & spe...", "icon_type": "grad_cap", "color": "amber"},
                {"id": "messages", "title": "Messages", "subtitle": "Parent & lear...", "icon_type": "chat", "color": "purple"},
                {"id": "consent", "title": "Consent", "subtitle": "Guardian per...", "icon_type": "shield", "color": "mint"},
                {"id": "verification", "title": "Verification", "subtitle": "Specialist sta...", "icon_type": "badge", "color": "teal"},
                {"id": "availability", "title": "Availability", "subtitle": "Weekly slots ...", "icon_type": "clock", "color": "lilac"},
                {"id": "alerts", "title": "Alerts", "subtitle": "Reminders & ...", "icon_type": "bell", "color": "purple"},
            ],
            "faqs": [
                {
                    "id": "faq_availability",
                    "question": "How do I update my weekly availability hours?",
                    "answer": (
                        "Navigate to Availability Settings to toggle individual days, customize time slots, "
                        "and set buffer intervals between sessions. Changes apply immediately to new parent booking requests."
                    ),
                },
                {
                    "id": "faq_consent",
                    "question": "How does learner guardian consent work?",
                    "answer": (
                        "Each learner profile is managed via a Permission-Based Consent Circle. Guardians explicitly "
                        "grant permissions for audio review, progress milestones, and reports. If consent is revoked, "
                        "sensitive media streams lock automatically."
                    ),
                },
                {
                    "id": "faq_session",
                    "question": "How do I start a live learning session?",
                    "answer": (
                        "Open your Schedule tab or tap on an active appointment. Tap 'Start Live Session' to launch "
                        "the interactive coaching room with real-time phoneme exercises and engagement telemetry."
                    ),
                },
                {
                    "id": "faq_credentials",
                    "question": "How do I edit my professional qualifications?",
                    "answer": (
                        "Open Specialist Profile, select Edit Profile, and update your specialization, experience, "
                        "or degrees. New credentials undergo automatic compliance verification within 24 hours."
                    ),
                },
            ],
            "support_desk_hours": "Mon–Fri, 8 AM–8 PM EST",
            "avg_response_time": "< 15 mins during desk hours",
            "system_status": "All Systems Operational",
            "app_version": "Lingua Specialist v2.4.1 (Build 842)",
        }

    def report_problem(
        self,
        specialist_user: User,
        category: str,
        description: str,
        device_info: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Registers a support report ticket."""
        return {
            "ticket_id": f"TICK-{specialist_user.id[:4]}-782",
            "status": "received",
            "message": "Thank you for reporting this issue. Our team is investigating.",
        }

    _SETTINGS_STORE: Dict[str, Dict[str, Any]] = {}

    def get_specialist_settings(self, specialist_user: User) -> Dict[str, Any]:
        """Returns the settings configuration matching the Stitch reference."""
        user_id = specialist_user.id
        if user_id not in self._SETTINGS_STORE:
            prof = specialist_user.profile
            raw_name = prof.display_name if (prof and prof.display_name) else "Maya Reynolds, M.S."
            self._SETTINGS_STORE[user_id] = {
                "specialist_name": raw_name,
                "specialist_title": "Learning Support Specialist (CCC-SLP)",
                "is_verified": True,
                "verification_badge": "Profile Verified",
                "active_learners_count": 18,
                "session_reminders": True,
                "consent_alerts": True,
                "messages_alerts": True,
                "appointment_requests": True,
                "weekly_progress_digests": False,
                "profile_visibility": "Public",
                "data_privacy_level": "COPPA-Compliant",
                "larger_text": False,
                "reduce_motion": False,
                "high_contrast": False,
                "haptic_feedback": True,
                "language": "English (US)",
                "appearance_theme": "Light (Playful)",
                "time_zone": "Pacific Time (GMT-7)",
                "audio_sound_fx": True,
            }
        return self._SETTINGS_STORE[user_id]

    def update_specialist_settings(
        self,
        specialist_user: User,
        updates: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Updates specialist preferences in settings store."""
        current = self.get_specialist_settings(specialist_user)
        for k, v in updates.items():
            if v is not None and k in current:
                current[k] = v
        self._SETTINGS_STORE[specialist_user.id] = current
        return current




