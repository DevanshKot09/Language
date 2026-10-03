from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.progress_service import ProgressService
from app.schemas.progress import (
    ProgressDashboardResponse,
    SkillProgressResponse,
    ActivityTimelineItem,
)

router = APIRouter()


@router.get(
    "",
    response_model=ProgressDashboardResponse,
    summary="Get comprehensive learner progress dashboard",
)
def get_progress_dashboard(
    include_ai_insight: bool = Query(True, description="Whether to include validated AI progress summary"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns full deterministic progress dashboard for the authenticated learner.
    Includes activity metrics, track summaries, skill progress, active goals,
    recent achievements, chronological activity timeline, and weekly trend.
    """
    return ProgressService.get_progress_dashboard(
        db=db,
        user=current_user,
        include_ai_insight=include_ai_insight,
    )


@router.get(
    "/skills",
    response_model=List[SkillProgressResponse],
    summary="Get learner skill progress breakdown",
)
def get_skill_progress(
    track: Optional[str] = Query(None, description="Filter by track: dld_track, dyslexia_track"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns skill readiness and practice accuracy across all curriculum skills.
    Maintains strict separation between DLD and Dyslexia.
    """
    dashboard = ProgressService.get_progress_dashboard(db, current_user, include_ai_insight=False)
    if track == "dld_track":
        return dashboard.dld_skills
    elif track == "dyslexia_track":
        return dashboard.dyslexia_skills
    return dashboard.skills


@router.get(
    "/timeline",
    response_model=List[ActivityTimelineItem],
    summary="Get privacy-safe learner activity timeline",
)
def get_activity_timeline(
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns chronological timeline of observable learning events.
    Excludes sensitive system logs, raw prompts, and audio.
    """
    return ProgressService.get_activity_timeline(db, current_user.id, limit=limit)
