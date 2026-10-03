from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.repositories.skill_repository import SkillRepository
from app.schemas.skill import SkillResponse

router = APIRouter()


@router.get(
    "/",
    response_model=List[SkillResponse],
    summary="List all accessible skills in the LINGUA AI taxonomy",
)
def get_skills(
    track: Optional[str] = None,
    age_band: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns skills mapped to evidence-informed DLD and Dyslexia tracks.
    Separates spoken-language skills from literacy skills.
    """
    return SkillRepository.get_all(db, track=track, age_band=age_band)


@router.get(
    "/{skill_id}",
    response_model=SkillResponse,
    summary="Get skill details by ID",
)
def get_skill(
    skill_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = SkillRepository.get_by_id(db, skill_id)
    if not skill:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Skill not found.")
    return skill
