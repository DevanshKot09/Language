from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.learning_service import LearningService
from app.schemas.learning import (
    LessonSummaryResponse,
    LessonDetailResponse,
    LessonProgressResponse,
    ExerciseAttemptRequest,
    ExerciseAttemptResponse,
    PracticeHubResponse,
    LearningPathResponse,
)

router = APIRouter()


@router.get(
    "/lessons",
    response_model=List[LessonSummaryResponse],
    summary="List available learning practice lessons with user progress",
)
def get_lessons(
    track: Optional[str] = Query(None, description="Filter by track (dld_track, dyslexia_track, both_track)"),
    skill_id: Optional[str] = Query(None, description="Filter by skill UUID"),
    age_band: Optional[str] = Query(None, description="Filter by age band (child, teen, adult)"),
    difficulty: Optional[int] = Query(None, description="Filter by difficulty level (1-4)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns curated, curriculum-aligned lessons with the current learner's completion status.
    Eliminates N+1 database queries through batch progress aggregation.
    """
    return LearningService.list_lessons(
        db=db,
        user=current_user,
        track=track,
        skill_id=skill_id,
        age_band=age_band,
        difficulty=difficulty,
    )


@router.get(
    "/lessons/{lesson_id}",
    response_model=LessonDetailResponse,
    summary="Get full lesson details with exercises",
)
def get_lesson(
    lesson_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns a lesson and its ordered exercises ready for the lesson player.
    Hides answers to preserve non-punitive pedagogical evaluation.
    """
    return LearningService.get_lesson_detail(db, lesson_id, current_user)


@router.post(
    "/lessons/{lesson_id}/start",
    response_model=LessonProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Start or resume a practice lesson",
)
def start_or_resume_lesson(
    lesson_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Initializes or retrieves ongoing progress. Persists learner position so sessions are resumable.
    """
    return LearningService.start_or_resume_lesson(db, lesson_id, current_user)


@router.get(
    "/lessons/{lesson_id}/state",
    response_model=LessonProgressResponse,
    summary="Get current user progress on a lesson",
)
def get_lesson_state(
    lesson_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Enforces learner ownership and returns current progress state.
    """
    return LearningService.get_lesson_state(db, lesson_id, current_user)


@router.post(
    "/exercises/{exercise_id}/attempt",
    response_model=ExerciseAttemptResponse,
    summary="Submit an exercise response for deterministic evaluation",
)
def submit_exercise_attempt(
    exercise_id: str,
    request: ExerciseAttemptRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Evaluates response deterministically.
    Records attempt, updates lesson progress, and returns encouraging non-diagnostic feedback.
    """
    return LearningService.record_exercise_attempt(db, exercise_id, current_user, request)


@router.post(
    "/lessons/{lesson_id}/complete",
    response_model=LessonProgressResponse,
    summary="Mark lesson complete and finalize progress",
)
def complete_lesson(
    lesson_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Marks lesson completed, updates timestamps, and registers progress milestone.
    """
    return LearningService.complete_lesson(db, lesson_id, current_user)


@router.get(
    "/practice",
    response_model=PracticeHubResponse,
    summary="Retrieve Practice Hub overview data",
)
def get_practice_hub(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Gathers recommended lessons, in-progress practice, completed milestones,
    and skill practice summaries according to the learner's profile.
    """
    return LearningService.get_practice_hub(db, current_user)


@router.get(
    "/learning-path",
    response_model=LearningPathResponse,
    summary="Retrieve sequential personalized learning path with real lesson nodes",
)
def get_learning_path(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns rule-based learning path with live progression status across real curriculum lessons.
    """
    return LearningService.get_learning_path(db, current_user)
