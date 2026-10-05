from datetime import datetime, timezone, timedelta
from typing import List, Optional, Dict
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.user import User
from app.models.skill import Skill
from app.models.skill_assessment import SkillAssessment
from app.models.baseline import BaselineSession
from app.models.learning import Lesson, Exercise, ExerciseAttempt, UserLessonProgress
from app.models.goal import LearnerGoal
from app.models.achievement import AchievementDefinition, UserAchievement
from app.repositories.goal_repository import GoalRepository
from app.schemas.progress import (
    ProgressDashboardResponse,
    ProgressSummary,
    SkillProgressResponse,
    ActivityTimelineItem,
    WeeklyActivityDay,
    ProgressTrend,
    TrackProgressSummary,
)
from app.schemas.goal import GoalResponse
from app.ai.orchestrator import ai_orchestrator
from app.ai.schemas import ProgressInsightRequest


def _to_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


class ProgressService:
    @staticmethod
    def get_progress_dashboard(
        db: Session,
        user: User,
        include_ai_insight: bool = True,
    ) -> ProgressDashboardResponse:
        """
        Computes the complete, deterministic progress snapshot for the authenticated learner.
        Derives all metrics strictly from stored application events.
        Maintains independent representation for DLD (spoken language) and Dyslexia (literacy).
        """

        # 2. Activity metrics
        completed_lessons_count = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.status == "completed",
            )
            .count()
        )
        in_progress_lessons_count = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.status == "in_progress",
            )
            .count()
        )

        all_attempts = (
            db.query(ExerciseAttempt)
            .filter(ExerciseAttempt.user_id == user.id)
            .all()
        )
        total_attempts = len(all_attempts)

        # Accuracy and independence calculations
        # Formula: evaluated_correct_score / total_evaluated_attempts
        # Independent rate: attempts correct without hints / total_attempts
        if total_attempts > 0:
            total_correct_score = sum(
                a.partial_score if a.partial_score > 0 else (1.0 if a.is_correct else 0.0)
                for a in all_attempts
            )
            overall_accuracy = total_correct_score / total_attempts

            correct_without_hints = sum(
                1 for a in all_attempts if a.is_correct and not a.hint_used
            )
            independent_rate = round((correct_without_hints / total_attempts) * 100.0, 1)

            total_attempt_time_sec = sum(a.time_spent_ms for a in all_attempts) // 1000
        else:
            overall_accuracy = 0.0
            independent_rate = 100.0
            total_attempt_time_sec = 0

        # Estimated practice time including completed lesson effort
        completed_lesson_effort_min = (
            db.query(func.sum(Lesson.estimated_effort_minutes))
            .join(UserLessonProgress, UserLessonProgress.lesson_id == Lesson.id)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.status == "completed",
            )
            .scalar()
            or 0
        )
        total_practice_time_minutes = (total_attempt_time_sec // 60) + completed_lesson_effort_min

        # 3. Forgiving Streak: distinct active days in the last 7 days
        seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
        recent_active_days = set()
        for a in all_attempts:
            dt = _to_utc(a.created_at)
            if dt and dt >= seven_days_ago:
                recent_active_days.add(dt.date())

        recent_progress = (
            db.query(UserLessonProgress)
            .filter(UserLessonProgress.user_id == user.id)
            .all()
        )
        for p in recent_progress:
            dt = _to_utc(p.last_attempted_at)
            if dt and dt >= seven_days_ago:
                recent_active_days.add(dt.date())

        consistency_streak_days = len(recent_active_days)

        # 4. Goals summary
        user_goals = GoalRepository.get_goals_by_user(db, user.id)
        active_goals = [g for g in user_goals if g.status == "active"]
        completed_goals = [g for g in user_goals if g.status in ("completed", "achieved")]

        # 5. Achievements
        all_achievements = []
        unlocked_achievements = []
        recent_achievements = []

        # 6. Skill Progress (Separation of DLD and Dyslexia)
        all_skills = db.query(Skill).filter(Skill.active == True).all()

        # Pre-fetch baseline assessments for user
        baseline_assessments = {
            sa.skill_id: sa
            for sa in db.query(SkillAssessment)
            .filter(SkillAssessment.user_id == user.id)
            .order_by(SkillAssessment.created_at.desc())
            .all()
        }

        # Pre-fetch attempt stats grouped by skill
        skill_attempts: Dict[str, List[ExerciseAttempt]] = {}
        for a in all_attempts:
            if a.exercise and a.exercise.skill_id:
                skill_attempts.setdefault(a.exercise.skill_id, []).append(a)

        # Pre-fetch completed lesson counts by skill
        completed_lessons_by_skill: Dict[str, int] = {}
        completed_records = (
            db.query(Lesson.skill_id, func.count(UserLessonProgress.id))
            .join(UserLessonProgress, UserLessonProgress.lesson_id == Lesson.id)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.status == "completed",
            )
            .group_by(Lesson.skill_id)
            .all()
        )
        for skill_id, count in completed_records:
            completed_lessons_by_skill[skill_id] = count

        skill_progress_list: List[SkillProgressResponse] = []
        dld_skills: List[SkillProgressResponse] = []
        dyslexia_skills: List[SkillProgressResponse] = []

        for skill in all_skills:
            assessment = baseline_assessments.get(skill.id)
            baseline_band = assessment.band if assessment else None

            attempts = skill_attempts.get(skill.id, [])
            attempt_count = len(attempts)
            lessons_completed = completed_lessons_by_skill.get(skill.id, 0)

            if attempt_count > 0:
                skill_acc = sum(
                    a.partial_score if a.partial_score > 0 else (1.0 if a.is_correct else 0.0)
                    for a in attempts
                ) / attempt_count
                last_practiced = max(a.created_at for a in attempts)
            else:
                skill_acc = assessment.accuracy if assessment else 0.0
                last_practiced = assessment.created_at if assessment else None

            # Compute non-diagnostic descriptive band
            current_band = ProgressService._determine_descriptive_band(
                baseline_band=baseline_band,
                attempt_count=attempt_count,
                accuracy=skill_acc,
                lessons_completed=lessons_completed,
            )

            item = SkillProgressResponse(
                skill_id=skill.id,
                skill_code=skill.code,
                name=skill.name,
                domain=skill.domain,
                track=skill.track,
                baseline_band=baseline_band,
                current_band=current_band,
                attempt_count=attempt_count,
                lesson_completed_count=lessons_completed,
                accuracy=round(skill_acc, 2),
                last_practiced_at=last_practiced,
                priority=skill.priority,
            )
            skill_progress_list.append(item)

            if skill.track == "dld_track":
                dld_skills.append(item)
            elif skill.track == "dyslexia_track":
                dyslexia_skills.append(item)

        # 7. Track summaries
        user_track = user.profile.support_focus if user.profile else "both_track"
        dld_summary = ProgressService._build_track_summary(
            track="dld_track",
            track_name="Spoken Language",
            skills=dld_skills,
            db=db,
            user_id=user.id,
        )
        dyslexia_summary = ProgressService._build_track_summary(
            track="dyslexia_track",
            track_name="Literacy & Reading",
            skills=dyslexia_skills,
            db=db,
            user_id=user.id,
        )

        # 8. Weekly trend
        trend = ProgressService._build_weekly_trend(db, user.id)

        # 9. Activity Timeline
        timeline = ProgressService.get_activity_timeline(db, user.id, limit=15)

        # 10. AI Progress Insight Integration
        ai_summary = None
        ai_details = None
        ai_fallback_used = False

        if include_ai_insight:
            try:
                active_goals_titles = [g.title for g in active_goals[:3]]
                top_skills = [
                    f"{s.name} ({s.current_band})"
                    for s in sorted(skill_progress_list, key=lambda x: x.attempt_count, reverse=True)[:3]
                ]

                req = ProgressInsightRequest(
                    age_band=user.profile.age_band if user.profile else "teen",
                    track=user_track,
                    lesson_count=completed_lessons_count,
                    attempt_count=total_attempts,
                    goals=active_goals_titles,
                    skills=top_skills,
                )
                insight_res = ai_orchestrator.get_progress_insight(req)
                ai_summary = insight_res.summary
                ai_details = insight_res.details
                ai_fallback_used = insight_res.fallback_used
            except Exception:
                ai_fallback_used = True
                ai_summary = (
                    f"You have completed {completed_lessons_count} practice lessons and "
                    f"{total_attempts} activities. Your steady focus is building strong skills!"
                )
                ai_details = [
                    f"Completed {completed_lessons_count} lessons across your curriculum",
                    f"Active in {consistency_streak_days} practice days this week",
                ]

        summary_model = ProgressSummary(
            total_lessons_completed=completed_lessons_count,
            total_lessons_in_progress=in_progress_lessons_count,
            total_exercises_attempted=total_attempts,
            total_practice_time_minutes=total_practice_time_minutes,
            independent_rate=independent_rate,
            consistency_streak_days=consistency_streak_days,
            active_goals_count=len(active_goals),
            completed_goals_count=len(completed_goals),
            achievements_count=len(unlocked_achievements),
        )

        return ProgressDashboardResponse(
            summary=summary_model,
            active_track=user_track,
            dld_track_summary=dld_summary,
            dyslexia_track_summary=dyslexia_summary,
            skills=skill_progress_list,
            dld_skills=dld_skills,
            dyslexia_skills=dyslexia_skills,
            active_goals=[GoalResponse.model_validate(g) for g in active_goals[:5]],
            recent_achievements=recent_achievements,
            timeline=timeline,
            trend=trend,
            ai_insight_summary=ai_summary,
            ai_insight_details=ai_details,
            ai_fallback_used=ai_fallback_used,
        )

    @staticmethod
    def get_activity_timeline(
        db: Session,
        user_id: str,
        limit: int = 20,
    ) -> List[ActivityTimelineItem]:
        """
        Builds a privacy-safe, chronological timeline of observable learning events.
        Excludes raw audio, prompt strings, and sensitive system telemetry.
        """
        events: List[ActivityTimelineItem] = []

        # Baseline sessions
        baselines = (
            db.query(BaselineSession)
            .filter(BaselineSession.user_id == user_id, BaselineSession.status == "completed")
            .order_by(BaselineSession.completed_at.desc())
            .limit(5)
            .all()
        )
        for b in baselines:
            if b.completed_at:
                events.append(
                    ActivityTimelineItem(
                        id=f"baseline-{b.id}",
                        event_type="baseline_completed",
                        title="Skill Snapshot Completed",
                        description=f"Initial practice readiness snapshot completed for {b.track.replace('_', ' ').title()}.",
                        timestamp=b.completed_at,
                        track=b.track,
                        badge_icon="explore",
                    )
                )

        # Lessons completed or started
        lesson_records = (
            db.query(UserLessonProgress)
            .join(Lesson)
            .filter(UserLessonProgress.user_id == user_id)
            .order_by(UserLessonProgress.last_attempted_at.desc())
            .limit(20)
            .all()
        )
        for p in lesson_records:
            if p.completed_at:
                events.append(
                    ActivityTimelineItem(
                        id=f"lesson-complete-{p.id}",
                        event_type="lesson_completed",
                        title="Lesson Completed",
                        description=f"Completed practice lesson: '{p.lesson.title}'.",
                        timestamp=p.completed_at,
                        track=p.lesson.track,
                        badge_icon="check_circle",
                    )
                )
            elif p.created_at:
                events.append(
                    ActivityTimelineItem(
                        id=f"lesson-start-{p.id}",
                        event_type="lesson_started",
                        title="Lesson Started",
                        description=f"Started practice lesson: '{p.lesson.title}'.",
                        timestamp=p.created_at,
                        track=p.lesson.track,
                        badge_icon="play_arrow",
                    )
                )

        # Goals created or completed
        goals = (
            db.query(LearnerGoal)
            .filter(LearnerGoal.user_id == user_id)
            .order_by(LearnerGoal.created_at.desc())
            .limit(10)
            .all()
        )
        for g in goals:
            if g.completed_at:
                events.append(
                    ActivityTimelineItem(
                        id=f"goal-complete-{g.id}",
                        event_type="goal_completed",
                        title="Goal Achieved",
                        description=f"Successfully reached goal: '{g.title}'.",
                        timestamp=g.completed_at,
                        badge_icon="flag",
                    )
                )
            elif g.created_at:
                events.append(
                    ActivityTimelineItem(
                        id=f"goal-create-{g.id}",
                        event_type="goal_created",
                        title="Goal Set",
                        description=f"Set new learning goal: '{g.title}'.",
                        timestamp=g.created_at,
                        badge_icon="outlined_flag",
                    )
                )

        # Achievements earned
        user_achs = (
            db.query(UserAchievement)
            .join(AchievementDefinition)
            .filter(UserAchievement.user_id == user_id)
            .order_by(UserAchievement.unlocked_at.desc())
            .limit(10)
            .all()
        )
        for ua in user_achs:
            events.append(
                ActivityTimelineItem(
                    id=f"achievement-{ua.id}",
                    event_type="achievement_earned",
                    title=f"Milestone: {ua.achievement.title}",
                    description=ua.achievement.description,
                    timestamp=ua.unlocked_at,
                    badge_icon=ua.achievement.icon_name,
                )
            )

        # Sort all events strictly by timestamp descending
        # Sort all events strictly by timestamp descending
        events.sort(
            key=lambda x: _to_utc(x.timestamp) or datetime.min.replace(tzinfo=timezone.utc),
            reverse=True,
        )
        return events[:limit]

    @staticmethod
    def _determine_descriptive_band(
        baseline_band: Optional[str],
        attempt_count: int,
        accuracy: float,
        lessons_completed: int,
    ) -> str:
        """
        Determines educational descriptive learning band.
        Strict non-diagnostic levels: Starting, Developing, Practicing, Consistent.
        """
        if attempt_count >= 5 and accuracy >= 0.85 and lessons_completed >= 1:
            return "consistent"
        elif attempt_count >= 3 and accuracy >= 0.70:
            return "practicing"
        elif attempt_count > 0:
            return "developing"
        elif baseline_band:
            return baseline_band
        return "starting"

    @staticmethod
    def _build_track_summary(
        track: str,
        track_name: str,
        skills: List[SkillProgressResponse],
        db: Session,
        user_id: str,
    ) -> TrackProgressSummary:
        total_lessons = db.query(Lesson).filter(Lesson.track == track, Lesson.active == True).count()
        completed_lessons = (
            db.query(UserLessonProgress)
            .join(Lesson)
            .filter(
                UserLessonProgress.user_id == user_id,
                Lesson.track == track,
                UserLessonProgress.status == "completed",
            )
            .count()
        )
        total_skills = len(skills)
        practiced_skills = sum(1 for s in skills if s.attempt_count > 0 or s.current_band != "starting")
        avg_acc = (
            sum(s.accuracy for s in skills if s.attempt_count > 0) / max(1, sum(1 for s in skills if s.attempt_count > 0))
            if any(s.attempt_count > 0 for s in skills)
            else 0.0
        )

        return TrackProgressSummary(
            track=track,
            track_name=track_name,
            completed_lessons=completed_lessons,
            total_lessons=total_lessons,
            practiced_skills=practiced_skills,
            total_skills=total_skills,
            average_accuracy=round(avg_acc, 2),
        )

    @staticmethod
    def _build_weekly_trend(db: Session, user_id: str) -> ProgressTrend:
        today = datetime.now(timezone.utc).date()
        days_list: List[WeeklyActivityDay] = []
        total_weekly_activities = 0
        total_weekly_minutes = 0

        user_attempts = (
            db.query(ExerciseAttempt)
            .filter(ExerciseAttempt.user_id == user_id)
            .all()
        )
        user_completed_lessons = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.status == "completed",
            )
            .all()
        )

        for i in range(6, -1, -1):
            day_date = today - timedelta(days=i)

            attempts_count = sum(
                1 for a in user_attempts
                if a.created_at and _to_utc(a.created_at).date() == day_date
            )
            completed_lessons_count = sum(
                1 for p in user_completed_lessons
                if p.completed_at and _to_utc(p.completed_at).date() == day_date
            )

            activity_count = attempts_count + completed_lessons_count
            practice_minutes = max(1, activity_count * 2) if activity_count > 0 else 0

            days_list.append(
                WeeklyActivityDay(
                    day_name=day_date.strftime("%a"),
                    date=day_date.isoformat(),
                    activity_count=activity_count,
                    practice_minutes=practice_minutes,
                )
            )
            total_weekly_activities += activity_count
            total_weekly_minutes += practice_minutes

        # Accessible text alternative for screen readers
        if total_weekly_activities > 0:
            accessible_desc = (
                f"In the past 7 days, you completed {total_weekly_activities} learning activities "
                f"across {len([d for d in days_list if d.activity_count > 0])} active days, "
                f"spending approximately {total_weekly_minutes} minutes practicing."
            )
        else:
            accessible_desc = (
                "You have no recorded activities in the past 7 days. "
                "Practice sessions will automatically generate your weekly activity summary."
            )

        return ProgressTrend(
            days=days_list,
            accessible_description=accessible_desc,
        )
