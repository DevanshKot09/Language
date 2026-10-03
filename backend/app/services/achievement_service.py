from datetime import datetime, timezone, timedelta
from typing import List, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.achievement import AchievementDefinition, UserAchievement
from app.models.learning import UserLessonProgress, ExerciseAttempt
from app.models.goal import LearnerGoal
from app.schemas.achievement import AchievementResponse


class AchievementService:
    @staticmethod
    def get_all_achievements_for_user(
        db: Session,
        user_id: str,
    ) -> List[AchievementResponse]:
        """
        Returns all system achievements enriched with the user's unlock status and progress.
        """
        all_defs = (
            db.query(AchievementDefinition)
            .order_by(AchievementDefinition.threshold.asc())
            .all()
        )
        unlocked = {
            ua.achievement_id: ua
            for ua in db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
        }

        # Calculate current user metrics for progress display
        metrics = AchievementService._compute_user_metrics(db, user_id)

        responses = []
        for d in all_defs:
            is_unlocked = d.id in unlocked
            ua = unlocked.get(d.id)
            progress_val = metrics.get(d.code, 0)
            if is_unlocked:
                progress_val = max(progress_val, d.threshold)

            responses.append(
                AchievementResponse(
                    id=d.id,
                    code=d.code,
                    title=d.title,
                    description=d.description,
                    category=d.category,
                    icon_name=d.icon_name,
                    threshold=d.threshold,
                    badge_tier=d.badge_tier,
                    is_unlocked=is_unlocked,
                    unlocked_at=ua.unlocked_at if ua else None,
                    progress_value=min(progress_val, d.threshold),
                )
            )

        return responses

    @staticmethod
    def evaluate_and_unlock(
        db: Session,
        user_id: str,
    ) -> List[AchievementResponse]:
        """
        Deterministically evaluates all achievement rules against stored user activity.
        Unlocks new achievements if eligible. Idempotent and never duplicates unlocks.
        """
        all_defs = db.query(AchievementDefinition).all()
        already_unlocked = {
            ua.achievement_id
            for ua in db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
        }

        metrics = AchievementService._compute_user_metrics(db, user_id)
        newly_unlocked = []

        now = datetime.now(timezone.utc)
        for d in all_defs:
            if d.id in already_unlocked:
                continue

            current_val = metrics.get(d.code, 0)
            if current_val >= d.threshold:
                user_ach = UserAchievement(
                    user_id=user_id,
                    achievement_id=d.id,
                    progress_value=current_val,
                    unlocked_at=now,
                )
                db.add(user_ach)
                db.flush()

                newly_unlocked.append(
                    AchievementResponse(
                        id=d.id,
                        code=d.code,
                        title=d.title,
                        description=d.description,
                        category=d.category,
                        icon_name=d.icon_name,
                        threshold=d.threshold,
                        badge_tier=d.badge_tier,
                        is_unlocked=True,
                        unlocked_at=now,
                        progress_value=current_val,
                    )
                )

        if newly_unlocked:
            db.commit()

        return newly_unlocked

    @staticmethod
    def _compute_user_metrics(db: Session, user_id: str) -> dict:
        """
        Calculates authoritative counts from actual application events.
        """
        # 1. Total lessons completed
        completed_lessons = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.status == "completed",
            )
            .count()
        )

        # 2. Distinct skills practiced (from exercise attempts)
        distinct_skills_count = (
            db.query(ExerciseAttempt.exercise_id)
            .join(ExerciseAttempt.exercise)
            .filter(ExerciseAttempt.user_id == user_id)
            .with_entities(func.count(func.distinct(ExerciseAttempt.exercise.has())))
        )
        # More direct query: distinct skill_ids across user's exercise attempts
        distinct_skills = (
            db.query(func.count(func.distinct(UserLessonProgress.lesson_id)))
            .filter(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.status.in_(["in_progress", "completed"]),
            )
            .scalar()
            or 0
        )
        # Attempt-based distinct skills:
        skills_from_attempts = (
            db.query(func.count(func.distinct(UserLessonProgress.lesson_id)))
            .filter(UserLessonProgress.user_id == user_id)
            .scalar()
            or 0
        )

        # 3. Completed goals
        completed_goals = (
            db.query(LearnerGoal)
            .filter(
                LearnerGoal.user_id == user_id,
                LearnerGoal.status.in_(["completed", "achieved"]),
            )
            .count()
        )

        # 4. Consistent practice days in last 7 days
        seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
        user_attempts = (
            db.query(ExerciseAttempt)
            .filter(ExerciseAttempt.user_id == user_id)
            .all()
        )
        distinct_days = set()
        for a in user_attempts:
            if a.created_at:
                dt = a.created_at if a.created_at.tzinfo else a.created_at.replace(tzinfo=timezone.utc)
                if dt >= seven_days_ago:
                    distinct_days.add(dt.date())

        recent_lessons = (
            db.query(UserLessonProgress)
            .filter(UserLessonProgress.user_id == user_id)
            .all()
        )
        for l in recent_lessons:
            if l.last_attempted_at:
                dt = l.last_attempted_at if l.last_attempted_at.tzinfo else l.last_attempted_at.replace(tzinfo=timezone.utc)
                if dt >= seven_days_ago:
                    distinct_days.add(dt.date())

        return {
            "first_lesson": completed_lessons,
            "five_lessons": completed_lessons,
            "ten_lessons": completed_lessons,
            "twenty_five_lessons": completed_lessons,
            "three_skills_practiced": max(distinct_skills, skills_from_attempts),
            "first_goal_completed": completed_goals,
            "three_goals_completed": completed_goals,
            "consistent_practice_3d": len(distinct_days),
        }
