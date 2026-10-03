from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.achievement_service import AchievementService
from app.schemas.achievement import AchievementResponse

router = APIRouter()


@router.get(
    "",
    response_model=List[AchievementResponse],
    summary="List all milestone achievements with user progress and unlocked status",
)
def get_achievements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns all non-punitive system achievements enriched with the user's progress.
    Evaluates new eligible achievements deterministically.
    """
    # Trigger deterministic evaluation
    AchievementService.evaluate_and_unlock(db, current_user.id)
    return AchievementService.get_all_achievements_for_user(db, current_user.id)
