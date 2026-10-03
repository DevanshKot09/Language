import json
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.profile import Profile
from app.models.collaboration import (
    Relationship,
    RelationshipInvitation,
    Assignment,
    Report,
    ReportAccessEvent,
)
from app.models.goal import LearnerGoal
from app.models.learning import Lesson, UserLessonProgress
from app.models.achievement import AchievementDefinition, UserAchievement

SYNTHETIC_STAGING_USERS = [
    # 2 Learners
    {
        "firebase_uid": "staging_uid_learner_a",
        "email": "staging_learner_a@lingua.ai",
        "role": "learner",
        "display_name": "Synthetic Learner A",
        "age_band": "teen",
        "support_focus": "dld_track",
        "guardian_consent_status": "verified",
    },
    {
        "firebase_uid": "staging_uid_learner_b",
        "email": "staging_learner_b@lingua.ai",
        "role": "learner",
        "display_name": "Synthetic Learner B",
        "age_band": "child",
        "support_focus": "dyslexia_track",
        "guardian_consent_status": "pending",
    },
    # 2 Parents
    {
        "firebase_uid": "staging_uid_parent_a",
        "email": "staging_parent_a@lingua.ai",
        "role": "parent",
        "display_name": "Synthetic Parent A",
        "age_band": "adult",
        "support_focus": "dld_track",
        "guardian_consent_status": "not_required",
    },
    {
        "firebase_uid": "staging_uid_parent_b",
        "email": "staging_parent_b@lingua.ai",
        "role": "parent",
        "display_name": "Synthetic Parent B",
        "age_band": "adult",
        "support_focus": "dyslexia_track",
        "guardian_consent_status": "not_required",
    },
    # 2 Teachers
    {
        "firebase_uid": "staging_uid_teacher_a",
        "email": "staging_teacher_a@lingua.ai",
        "role": "teacher",
        "display_name": "Synthetic Teacher A",
        "age_band": "adult",
        "support_focus": "dld_track",
        "guardian_consent_status": "not_required",
    },
    {
        "firebase_uid": "staging_uid_teacher_b",
        "email": "staging_teacher_b@lingua.ai",
        "role": "teacher",
        "display_name": "Synthetic Teacher B",
        "age_band": "adult",
        "support_focus": "dyslexia_track",
        "guardian_consent_status": "not_required",
    },
    # 2 Specialists
    {
        "firebase_uid": "staging_uid_specialist_a",
        "email": "staging_specialist_a@lingua.ai",
        "role": "specialist",
        "display_name": "Synthetic Specialist A",
        "age_band": "adult",
        "support_focus": "dld_track",
        "guardian_consent_status": "not_required",
    },
    {
        "firebase_uid": "staging_uid_specialist_b",
        "email": "staging_specialist_b@lingua.ai",
        "role": "specialist",
        "display_name": "Synthetic Specialist B",
        "age_band": "adult",
        "support_focus": "dyslexia_track",
        "guardian_consent_status": "not_required",
    },
]


def seed_staging_synthetic_data(db: Session) -> dict:
    """
    Populates synthetic staging records across all 4 roles.
    Strictly non-diagnostic: zero medical diagnoses, zero severity scores.
    """
    users_by_email = {}
    for user_info in SYNTHETIC_STAGING_USERS:
        existing = db.query(User).filter(User.email == user_info["email"]).first()
        if not existing:
            user = User(
                firebase_uid=user_info["firebase_uid"],
                email=user_info["email"],
                role=user_info["role"],
                status="active",
            )
            db.add(user)
            db.flush()

            profile = Profile(
                user_id=user.id,
                display_name=user_info["display_name"],
                age_band=user_info["age_band"],
                support_focus=user_info["support_focus"],
                guardian_consent_status=user_info["guardian_consent_status"],
            )
            db.add(profile)
            users_by_email[user_info["email"]] = user
        else:
            users_by_email[user_info["email"]] = existing

    db.commit()

    learner_a = users_by_email["staging_learner_a@lingua.ai"]
    learner_b = users_by_email["staging_learner_b@lingua.ai"]
    parent_a = users_by_email["staging_parent_a@lingua.ai"]
    parent_b = users_by_email["staging_parent_b@lingua.ai"]
    teacher_a = users_by_email["staging_teacher_a@lingua.ai"]
    specialist_a = users_by_email["staging_specialist_a@lingua.ai"]

    # 1. Establish Parent A -> Learner A relationship (Active, verified consent)
    rel_pa = db.query(Relationship).filter(
        Relationship.source_user_id == parent_a.id,
        Relationship.target_user_id == learner_a.id,
    ).first()
    if not rel_pa:
        rel_pa = Relationship(
            source_user_id=parent_a.id,
            target_user_id=learner_a.id,
            relationship_type="parent",
            status="active",
            permission_scope=json.dumps(["view_progress", "view_goals", "manage_consent"]),
            consent_status="verified",
            organization="Synthetic Family A",
        )
        db.add(rel_pa)

    # 2. Establish Parent B -> Learner B relationship (Active, pending child consent)
    rel_pb = db.query(Relationship).filter(
        Relationship.source_user_id == parent_b.id,
        Relationship.target_user_id == learner_b.id,
    ).first()
    if not rel_pb:
        rel_pb = Relationship(
            source_user_id=parent_b.id,
            target_user_id=learner_b.id,
            relationship_type="parent",
            status="active",
            permission_scope=json.dumps(["view_progress", "manage_consent"]),
            consent_status="pending",
            organization="Synthetic Family B",
        )
        db.add(rel_pb)

    # 3. Establish Teacher A -> Learner A relationship
    rel_ta = db.query(Relationship).filter(
        Relationship.source_user_id == teacher_a.id,
        Relationship.target_user_id == learner_a.id,
    ).first()
    if not rel_ta:
        rel_ta = Relationship(
            source_user_id=teacher_a.id,
            target_user_id=learner_a.id,
            relationship_type="teacher",
            status="active",
            permission_scope=json.dumps(["view_progress", "manage_assignments"]),
            consent_status="verified",
            organization="Staging Academy",
        )
        db.add(rel_ta)

    # 4. Establish Specialist A -> Learner A relationship
    rel_sa = db.query(Relationship).filter(
        Relationship.source_user_id == specialist_a.id,
        Relationship.target_user_id == learner_a.id,
    ).first()
    if not rel_sa:
        rel_sa = Relationship(
            source_user_id=specialist_a.id,
            target_user_id=learner_a.id,
            relationship_type="specialist",
            status="active",
            permission_scope=json.dumps(["view_progress", "generate_support_report", "review_ai_recommendations"]),
            consent_status="verified",
            organization="Staging Educational Clinic",
        )
        db.add(rel_sa)

    # 5. Seed synthetic goal for Learner A
    existing_goal = db.query(LearnerGoal).filter(LearnerGoal.user_id == learner_a.id).first()
    if not existing_goal:
        goal = LearnerGoal(
            user_id=learner_a.id,
            title="Complete 3 Vocabulary Practice Sessions",
            description="Practice sentence construction with connectors",
            goal_type="complete_lessons",
            target_count=3,
            current_count=1,
            target_frequency="weekly",
            status="active",
        )
        db.add(goal)

    # 6. Seed synthetic assignment from Teacher A to Learner A
    existing_assignment = db.query(Assignment).filter(
        Assignment.teacher_id == teacher_a.id,
        Assignment.student_id == learner_a.id,
    ).first()
    if not existing_assignment:
        # Check if lesson exists
        lesson = db.query(Lesson).first()
        lesson_id = lesson.id if lesson else "lesson-staging-voc-1"
        assignment = Assignment(
            teacher_id=teacher_a.id,
            student_id=learner_a.id,
            lesson_id=lesson_id,
            title="Active Vocabulary Sentence Building Practice",
            instructions="Practice the sentence builders 3 times this week.",
            status="assigned",
            due_at=datetime.now(timezone.utc) + timedelta(days=7),
        )
        db.add(assignment)

    # 7. Seed educational support report from Specialist A for Learner A
    existing_report = db.query(Report).filter(
        Report.creator_id == specialist_a.id,
        Report.learner_id == learner_a.id,
    ).first()
    if not existing_report:
        report = Report(
            creator_id=specialist_a.id,
            learner_id=learner_a.id,
            report_type="specialist_summary",
            title="Phase 14 Staging Educational Support Review",
            summary_data=json.dumps({
                "strengths": ["Consistent practice engagement", "Strong receptive vocabulary"],
                "growth_areas": ["Sentence formulation with complex conjunctions"],
                "recommended_supports": ["Visual sentence-frame cards", "Self-paced oral retelling"],
            }),
            disclaimer="EDUCATIONAL SUPPORT RECORD ONLY: Strictly non-diagnostic. Does not diagnose DLD or Dyslexia.",
            status="active",
        )
        db.add(report)

    db.commit()
    return {
        "status": "seeded",
        "synthetic_users_count": len(SYNTHETIC_STAGING_USERS),
        "relationships_seeded": 4,
    }


def reset_staging_synthetic_data(db: Session) -> dict:
    """
    Cleans up all synthetic staging users and cascading relationships/records.
    Guarantees staging environment hygiene without touching production data.
    """
    synthetic_emails = [u["email"] for u in SYNTHETIC_STAGING_USERS]
    synthetic_users = db.query(User).filter(User.email.in_(synthetic_emails)).all()
    user_ids = [u.id for u in synthetic_users]

    if user_ids:
        # Cascade deletes relationships, profiles, goals, assignments, reports
        db.query(ReportAccessEvent).filter(ReportAccessEvent.user_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(Report).filter(Report.creator_id.in_(user_ids) | Report.learner_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(Assignment).filter(Assignment.teacher_id.in_(user_ids) | Assignment.student_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(RelationshipInvitation).filter(RelationshipInvitation.inviter_id.in_(user_ids) | RelationshipInvitation.target_learner_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(Relationship).filter(Relationship.source_user_id.in_(user_ids) | Relationship.target_user_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(LearnerGoal).filter(LearnerGoal.user_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(UserLessonProgress).filter(UserLessonProgress.user_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(Profile).filter(Profile.user_id.in_(user_ids)).delete(synchronize_session=False)
        db.query(User).filter(User.id.in_(user_ids)).delete(synchronize_session=False)
        db.commit()

    return {"status": "cleared", "records_removed": len(user_ids)}
