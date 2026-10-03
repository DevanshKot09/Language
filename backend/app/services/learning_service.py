import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.skill import Skill
from app.models.learning import Lesson, Exercise, ExerciseAttempt, UserLessonProgress
from app.schemas.learning import (
    ExerciseResponse,
    ExerciseAttemptRequest,
    ExerciseAttemptResponse,
    LessonSummaryResponse,
    LessonDetailResponse,
    LessonProgressResponse,
    PracticeHubResponse,
    SkillProgressItem,
    LearningPathNodeResponse,
    LearningPathResponse,
)
from app.services.evaluator import ExerciseEvaluator
from app.repositories.goal_repository import GoalRepository
from app.services.achievement_service import AchievementService


class LearningService:
    """
    Evidence-informed, non-diagnostic Activity & Practice Engine Service.
    Enforces learner data ownership, deterministic progression, and age-adaptive feedback.
    """

    @classmethod
    def list_lessons(
        cls,
        db: Session,
        user: User,
        track: Optional[str] = None,
        skill_id: Optional[str] = None,
        age_band: Optional[str] = None,
        difficulty: Optional[int] = None,
    ) -> List[LessonSummaryResponse]:
        query = db.query(Lesson).filter(Lesson.active == True)

        if track and track != "all":
            query = query.filter((Lesson.track == track) | (Lesson.track == "both_track"))

        if skill_id:
            query = query.filter(Lesson.skill_id == skill_id)

        if age_band and age_band != "all":
            query = query.filter((Lesson.age_band == age_band) | (Lesson.age_band == "all"))

        if difficulty:
            query = query.filter(Lesson.difficulty == difficulty)

        lessons = query.order_by(Lesson.sequence_order.asc(), Lesson.difficulty.asc()).all()

        if not lessons:
            return []

        # Batch load user progress for all queried lessons to eliminate N+1 queries
        lesson_ids = [l.id for l in lessons]
        progress_records = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id.in_(lesson_ids),
            )
            .all()
        )
        progress_map: Dict[str, UserLessonProgress] = {p.lesson_id: p for p in progress_records}

        summaries = []
        for l in lessons:
            prog = progress_map.get(l.id)
            total_ex = len(l.exercises)
            user_status = prog.status if prog else "not_started"
            current_idx = prog.current_exercise_index if prog else 0
            completed_ex = total_ex if user_status == "completed" else current_idx

            summaries.append(
                LessonSummaryResponse(
                    id=l.id,
                    skill_id=l.skill_id,
                    skill_name=l.skill.name if l.skill else None,
                    title=l.title,
                    description=l.description,
                    track=l.track,
                    age_band=l.age_band,
                    difficulty=l.difficulty,
                    sequence_order=l.sequence_order,
                    estimated_effort_minutes=l.estimated_effort_minutes,
                    total_exercises=total_ex,
                    user_status=user_status,
                    current_exercise_index=current_idx,
                    completed_exercises=min(completed_ex, total_ex),
                )
            )

        return summaries

    @classmethod
    def get_lesson_detail(cls, db: Session, lesson_id: str, user: User) -> LessonDetailResponse:
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson not found.",
            )
        if not lesson.active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This lesson is currently inactive.",
            )

        prog = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id == lesson_id,
            )
            .first()
        )
        user_status = prog.status if prog else "not_started"
        current_idx = prog.current_exercise_index if prog else 0

        exercises_data = []
        for ex in sorted(lesson.exercises, key=lambda x: x.sequence_order):
            if not ex.active:
                continue

            content = cls._safe_json_loads(ex.content_json)
            hints = cls._safe_json_loads(ex.hints_json)

            exercises_data.append(
                ExerciseResponse(
                    id=ex.id,
                    lesson_id=ex.lesson_id,
                    skill_id=ex.skill_id,
                    exercise_type=ex.exercise_type,
                    prompt=ex.prompt,
                    instruction=ex.instruction,
                    content=content,
                    difficulty=ex.difficulty,
                    age_band=ex.age_band,
                    track=ex.track,
                    sequence_order=ex.sequence_order,
                    hints=hints if isinstance(hints, list) else None,
                    explanation=ex.explanation,
                )
            )

        return LessonDetailResponse(
            id=lesson.id,
            skill_id=lesson.skill_id,
            skill_name=lesson.skill.name if lesson.skill else None,
            title=lesson.title,
            description=lesson.description,
            track=lesson.track,
            age_band=lesson.age_band,
            difficulty=lesson.difficulty,
            sequence_order=lesson.sequence_order,
            estimated_effort_minutes=lesson.estimated_effort_minutes,
            total_exercises=len(exercises_data),
            user_status=user_status,
            current_exercise_index=current_idx,
            exercises=exercises_data,
        )

    @classmethod
    def start_or_resume_lesson(cls, db: Session, lesson_id: str, user: User) -> LessonProgressResponse:
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.active == True).first()
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson not found or inactive.",
            )

        prog = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id == lesson_id,
            )
            .first()
        )

        now = datetime.now(timezone.utc)
        if not prog:
            prog = UserLessonProgress(
                user_id=user.id,
                lesson_id=lesson.id,
                current_exercise_index=0,
                status="in_progress",
                last_attempted_at=now,
            )
            db.add(prog)
            db.commit()
            db.refresh(prog)
        else:
            if prog.status == "not_started":
                prog.status = "in_progress"
            prog.last_attempted_at = now
            db.commit()
            db.refresh(prog)

        total_ex = len(lesson.exercises)
        completed_ex = total_ex if prog.status == "completed" else prog.current_exercise_index

        return LessonProgressResponse(
            lesson_id=prog.lesson_id,
            current_exercise_index=prog.current_exercise_index,
            status=prog.status,
            score=prog.score,
            completed_at=prog.completed_at.isoformat() if prog.completed_at else None,
            total_exercises=total_ex,
            completed_exercises=min(completed_ex, total_ex),
        )

    @classmethod
    def get_lesson_state(cls, db: Session, lesson_id: str, user: User) -> LessonProgressResponse:
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
        if not lesson:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found.")

        prog = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id == lesson_id,
            )
            .first()
        )

        total_ex = len(lesson.exercises)
        if not prog:
            return LessonProgressResponse(
                lesson_id=lesson_id,
                current_exercise_index=0,
                status="not_started",
                score=None,
                completed_at=None,
                total_exercises=total_ex,
                completed_exercises=0,
            )

        completed_ex = total_ex if prog.status == "completed" else prog.current_exercise_index
        return LessonProgressResponse(
            lesson_id=prog.lesson_id,
            current_exercise_index=prog.current_exercise_index,
            status=prog.status,
            score=prog.score,
            completed_at=prog.completed_at.isoformat() if prog.completed_at else None,
            total_exercises=total_ex,
            completed_exercises=min(completed_ex, total_ex),
        )

    @classmethod
    def record_exercise_attempt(
        cls,
        db: Session,
        exercise_id: str,
        user: User,
        request: ExerciseAttemptRequest,
    ) -> ExerciseAttemptResponse:
        exercise = db.query(Exercise).filter(Exercise.id == exercise_id, Exercise.active == True).first()
        if not exercise:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise not found or inactive.",
            )

        lesson = exercise.lesson
        if not lesson or not lesson.active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Lesson associated with this exercise is unavailable.",
            )

        # Retrieve user age band for encouraging feedback customization
        user_age_band = user.profile.age_band if user.profile else "all"

        # Deterministic evaluation
        eval_result = ExerciseEvaluator.evaluate(
            exercise_type=exercise.exercise_type,
            user_response=request.response,
            correct_answer_raw=exercise.correct_answer_json,
            explanation=exercise.explanation,
            feedback_config_raw=exercise.feedback_config_json,
            age_band=user_age_band,
        )

        # Serialize learner response safely
        resp_serialized = (
            json.dumps(request.response)
            if isinstance(request.response, (dict, list))
            else str(request.response)
        )

        # Record attempt
        attempt = ExerciseAttempt(
            user_id=user.id,
            exercise_id=exercise.id,
            lesson_id=lesson.id,
            response_json=resp_serialized,
            is_correct=eval_result.is_correct,
            partial_score=eval_result.partial_score,
            attempt_number=request.attempt_number,
            time_spent_ms=request.time_spent_ms,
            hint_used=request.hint_used,
            created_at=datetime.now(timezone.utc),
        )
        db.add(attempt)

        # Update user lesson progress
        prog = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id == lesson.id,
            )
            .first()
        )
        now = datetime.now(timezone.utc)
        if not prog:
            prog = UserLessonProgress(
                user_id=user.id,
                lesson_id=lesson.id,
                current_exercise_index=0,
                status="in_progress",
                last_attempted_at=now,
            )
            db.add(prog)

        prog.last_attempted_at = now
        total_exercises = len(lesson.exercises)

        # If exercise is correct or partial credit, advance if currently on this exercise
        exercise_idx = exercise.sequence_order - 1  # 0-indexed position
        lesson_completed = False
        next_idx = prog.current_exercise_index

        if eval_result.is_correct:
            if exercise_idx >= prog.current_exercise_index:
                next_idx = exercise_idx + 1
                prog.current_exercise_index = next_idx

            if prog.current_exercise_index >= total_exercises:
                prog.status = "completed"
                prog.completed_at = now
                lesson_completed = True
        elif prog.status == "completed":
            lesson_completed = True

        db.commit()
        db.refresh(attempt)

        # Phase 10: Deterministic Goal & Achievement Evaluation
        try:
            GoalRepository.increment_goals_for_event(db, user.id, "exercise_attempted", skill_id=exercise.skill_id)
            if lesson_completed:
                GoalRepository.increment_goals_for_event(db, user.id, "lesson_completed", skill_id=exercise.skill_id)
                AchievementService.evaluate_and_unlock(db, user.id)
        except Exception:
            pass  # Ensure educational flow is never blocked

        return ExerciseAttemptResponse(
            attempt_id=attempt.id,
            status=eval_result.status,
            is_correct=eval_result.is_correct,
            partial_score=eval_result.partial_score,
            feedback_message=eval_result.feedback_message,
            explanation=eval_result.explanation,
            current_exercise_index=prog.current_exercise_index,
            next_exercise_index=next_idx if next_idx < total_exercises else None,
            lesson_completed=lesson_completed,
        )

    @classmethod
    def complete_lesson(cls, db: Session, lesson_id: str, user: User) -> LessonProgressResponse:
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
        if not lesson:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found.")

        prog = (
            db.query(UserLessonProgress)
            .filter(
                UserLessonProgress.user_id == user.id,
                UserLessonProgress.lesson_id == lesson_id,
            )
            .first()
        )
        now = datetime.now(timezone.utc)
        total_ex = len(lesson.exercises)

        if not prog:
            prog = UserLessonProgress(
                user_id=user.id,
                lesson_id=lesson_id,
                current_exercise_index=total_ex,
                status="completed",
                completed_at=now,
                last_attempted_at=now,
            )
            db.add(prog)
        else:
            prog.status = "completed"
            prog.completed_at = now
            prog.current_exercise_index = total_ex
            prog.last_attempted_at = now

        db.commit()
        db.refresh(prog)

        # Phase 10: Deterministic Goal & Achievement Evaluation
        try:
            GoalRepository.increment_goals_for_event(db, user.id, "lesson_completed", skill_id=lesson.skill_id)
            AchievementService.evaluate_and_unlock(db, user.id)
        except Exception:
            pass  # Non-blocking educational resilience

        return LessonProgressResponse(
            lesson_id=prog.lesson_id,
            current_exercise_index=prog.current_exercise_index,
            status=prog.status,
            score=prog.score,
            completed_at=prog.completed_at.isoformat() if prog.completed_at else None,
            total_exercises=total_ex,
            completed_exercises=total_ex,
        )

    @classmethod
    def get_practice_hub(cls, db: Session, user: User) -> PracticeHubResponse:
        """
        Gathers recommended practice, ongoing sessions, and completed milestones.
        Uses deterministic rule-based selection adhering to learner track & age band.
        """
        user_track = user.profile.support_focus if user.profile else "both_track"
        user_age = user.profile.age_band if user.profile else "all"

        all_summaries = cls.list_lessons(db, user, track=user_track, age_band=user_age)

        recommended = [l for l in all_summaries if l.user_status == "not_started"]
        in_progress = [l for l in all_summaries if l.user_status == "in_progress"]
        completed = [l for l in all_summaries if l.user_status == "completed"]

        # Aggregate skills progress summary
        skills = db.query(Skill).filter(Skill.active == True).all()
        skills_summary = []
        for s in skills:
            skill_lessons = [l for l in all_summaries if l.skill_id == s.id]
            comp_count = sum(1 for l in skill_lessons if l.user_status == "completed")
            tot_count = len(skill_lessons)

            if tot_count == 0:
                mastery = "Starting"
            elif comp_count == tot_count:
                mastery = "Consistent"
            elif comp_count > 0:
                mastery = "Practicing"
            else:
                mastery = "Developing"

            skills_summary.append(
                SkillProgressItem(
                    skill_id=s.id,
                    skill_code=s.code,
                    skill_name=s.name,
                    track=s.track,
                    completed_lessons=comp_count,
                    total_lessons=tot_count,
                    mastery_status=mastery,
                )
            )

        return PracticeHubResponse(
            recommended_lessons=recommended[:6],
            in_progress_lessons=in_progress,
            completed_lessons=completed,
            skills_summary=skills_summary,
        )

    @classmethod
    def get_learning_path(cls, db: Session, user: User) -> LearningPathResponse:
        """
        Produces a personalized sequential learning path connecting real lesson data.
        Rule-Based Learning Selection: foundational -> advancing -> connected.
        """
        user_track = user.profile.support_focus if user.profile else "both_track"
        user_age = user.profile.age_band if user.profile else "all"

        lessons = cls.list_lessons(db, user, track=user_track, age_band=user_age)
        if not lessons:
            # Fallback to all lessons if user track produced none
            lessons = cls.list_lessons(db, user)

        nodes = []
        has_found_active = False

        for idx, l in enumerate(lessons, start=1):
            if l.user_status == "completed":
                status_str = "completed"
                is_comp = True
                is_act = False
            elif l.user_status == "in_progress":
                status_str = "active"
                is_comp = False
                is_act = True
                has_found_active = True
            elif not has_found_active:
                # First uncompleted lesson becomes the active goal
                status_str = "active"
                is_comp = False
                is_act = True
                has_found_active = True
            else:
                # Following lessons are unlocked or upcoming
                status_str = "unlocked" if len(nodes) > 0 and nodes[-1].is_completed else "upcoming"
                is_comp = False
                is_act = False

            nodes.append(
                LearningPathNodeResponse(
                    step_number=idx,
                    lesson_id=l.id,
                    title=l.title,
                    track=l.track,
                    skill_name=l.skill_name or "Foundational Skill",
                    status=status_str,
                    is_completed=is_comp,
                    is_active=is_act,
                    difficulty=l.difficulty,
                )
            )

        return LearningPathResponse(
            track=user_track,
            nodes=nodes,
        )

    @staticmethod
    def _safe_json_loads(val: Any) -> Any:
        if isinstance(val, (dict, list)):
            return val
        if isinstance(val, str):
            try:
                return json.loads(val)
            except Exception:
                return val
        return val
