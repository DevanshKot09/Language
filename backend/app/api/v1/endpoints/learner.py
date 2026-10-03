from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.baseline_service import BaselineService
from app.repositories.goal_repository import GoalRepository
from app.schemas.baseline import SkillSnapshotResponse
from app.schemas.goal import GoalCreateRequest, GoalResponse

router = APIRouter()


@router.get(
    "/skill-snapshot",
    response_model=SkillSnapshotResponse,
    summary="Get current learner Skill Snapshot",
)
def get_learner_skill_snapshot(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns non-diagnostic skill snapshot aggregating readiness bands
    for DLD and Dyslexia tracks.
    """
    return BaselineService.get_skill_snapshot(db, current_user)


@router.get(
    "/goals",
    response_model=List[GoalResponse],
    summary="List active learning goals for the learner",
)
def get_learner_goals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns goals owned by the authenticated learner.
    """
    return GoalRepository.get_goals_by_user(db, current_user.id)


@router.post(
    "/goals",
    response_model=GoalResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new learner goal",
)
def create_learner_goal(
    request: GoalCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Creates a new learner practice goal associated with the authenticated learner.
    """
    return GoalRepository.create_goal(
        db=db,
        user_id=current_user.id,
        title=request.title,
        skill_id=request.skill_id,
        target_frequency=request.target_frequency,
        target_behavior=request.target_behavior,
    )
