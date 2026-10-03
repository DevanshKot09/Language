from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.baseline_service import BaselineService
from app.schemas.baseline import (
    BaselineSessionResponse,
    BaselineResponseRequest,
    BaselineResponseResult,
    SkillSnapshotResponse,
)

router = APIRouter()


@router.post(
    "/sessions",
    response_model=BaselineSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Get or start an initial, non-diagnostic skill baseline session",
)
def create_or_get_baseline_session(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Initializes or retrieves an ongoing skill baseline session.
    Determines activities deterministically based on learner support focus and age band.
    """
    return BaselineService.get_or_create_session(db, current_user)


@router.get(
    "/sessions/{session_id}",
    response_model=BaselineSessionResponse,
    summary="Retrieve baseline session details and remaining activities",
)
def get_baseline_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Enforces learner data ownership. Only returns session data owned by the authenticated learner.
    """
    return BaselineService.get_session(db, session_id, current_user)


@router.post(
    "/sessions/{session_id}/responses",
    response_model=BaselineResponseResult,
    summary="Submit an answer to an activity in an active baseline session",
)
def submit_baseline_response(
    session_id: str,
    request: BaselineResponseRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Records response, calculates accuracy deterministically without diagnostic scoring,
    and updates session completion count.
    """
    return BaselineService.record_response(db, session_id, current_user, request)


@router.post(
    "/sessions/{session_id}/complete",
    response_model=SkillSnapshotResponse,
    summary="Finalize baseline session and generate descriptive Skill Snapshot",
)
def complete_baseline_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Aggregates baseline performance into descriptive learning readiness bands
    (Starting, Developing, Practicing, Consistent). Never produces clinical diagnosis or scores.
    """
    return BaselineService.complete_session(db, session_id, current_user)
