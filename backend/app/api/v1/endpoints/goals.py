from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.goal import LearnerGoal
from app.models.skill import Skill
from app.repositories.goal_repository import GoalRepository
from app.schemas.goal import GoalCreateRequest, GoalUpdateRequest, GoalResponse

router = APIRouter()


@router.get(
    "",
    response_model=List[GoalResponse],
    summary="List goals owned by the authenticated learner",
)
def list_goals(
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by status (active, completed)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns goals owned exclusively by the authenticated learner.
    """
    return GoalRepository.get_goals_by_user(db, current_user.id, status=status_filter)


@router.post(
    "",
    response_model=GoalResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new learning goal",
)
def create_goal(
    request: GoalCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Creates a new learner practice goal.
    Validates target > 0, skill existence (if provided), and binds to authenticated user.
    """
    if request.target_count <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Target count must be greater than zero.",
        )

    if request.skill_id:
        skill = db.query(Skill).filter(Skill.id == request.skill_id).first()
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Referenced skill does not exist.",
            )

    return GoalRepository.create_goal(
        db=db,
        user_id=current_user.id,
        title=request.title,
        skill_id=request.skill_id,
        description=request.description,
        goal_type=request.goal_type,
        target_count=request.target_count,
        target_frequency=request.target_frequency,
        target_behavior=request.target_behavior,
    )


@router.get(
    "/{goal_id}",
    response_model=GoalResponse,
    summary="Get goal details with ownership verification",
)
def get_goal(
    goal_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns specific goal if owned by authenticated learner.
    Returns 403 Forbidden if owned by another user.
    """
    goal = db.query(LearnerGoal).filter(LearnerGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found.",
        )
    if goal.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You do not have permission to access this goal.",
        )
    return goal


@router.put(
    "/{goal_id}",
    response_model=GoalResponse,
    summary="Update an existing goal",
)
def update_goal(
    goal_id: str,
    request: GoalUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Updates an existing goal. Enforces strict learner ownership (403 if belonging to another user).
    """
    goal = db.query(LearnerGoal).filter(LearnerGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found.",
        )
    if goal.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot modify goals belonging to another learner.",
        )

    updated = GoalRepository.update_goal(
        db=db,
        goal_id=goal_id,
        user_id=current_user.id,
        title=request.title,
        description=request.description,
        target_count=request.target_count,
        target_frequency=request.target_frequency,
        target_behavior=request.target_behavior,
        status=request.status,
    )
    return updated


@router.delete(
    "/{goal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a learner goal",
)
def delete_goal(
    goal_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Deletes a goal. Enforces strict learner ownership (403 if belonging to another user).
    """
    goal = db.query(LearnerGoal).filter(LearnerGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found.",
        )
    if goal.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot delete goals belonging to another learner.",
        )

    GoalRepository.delete_goal(db, goal_id, current_user.id)
    return None
