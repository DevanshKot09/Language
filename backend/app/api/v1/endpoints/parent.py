from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_role
from app.models.user import User
from app.models.learning import Lesson
from app.schemas.progress import ProgressDashboardResponse
from app.services.collaboration_service import CollaborationService
from app.services.progress_service import ProgressService

router = APIRouter()


@router.get("/children", response_model=List[Dict[str, Any]])
async def get_parent_children(
    current_user: User = Depends(require_role(["parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns list of children connected to the authenticated parent.
    Enforces that parents only see authorized relationships.
    """
    service = CollaborationService(db)
    return service.get_parent_children(current_user)


@router.get("/children/{learner_id}/progress", response_model=ProgressDashboardResponse)
async def get_child_progress(
    learner_id: str,
    current_user: User = Depends(require_role(["parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns deterministic progress snapshot for an authorized child.
    Enforces relationship existence and 'view_progress' scope.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=learner_id,
        required_scope="view_progress",
    )

    child = db.query(User).filter(User.id == learner_id).first()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found.")

    return ProgressService.get_progress_dashboard(db, child)


@router.get("/children/{learner_id}/home-practice")
async def get_child_home_practice(
    learner_id: str,
    current_user: User = Depends(require_role(["parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Discovers approved home practice lessons for an authorized child.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=learner_id,
        required_scope="view_home_practice",
    )

    child = db.query(User).filter(User.id == learner_id).first()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found.")

    prof = child.profile
    track = prof.support_focus if prof else "dld_track"
    age = prof.age_band if prof else "child"

    # Query approved practice lessons matching child configuration
    query = db.query(Lesson).filter(Lesson.active == True)  # noqa
    if track == "dld_track":
        query = query.filter(Lesson.track.in_(["dld_track", "both_track"]))
    elif track == "dyslexia_track":
        query = query.filter(Lesson.track.in_(["dyslexia_track", "both_track"]))

    lessons = query.limit(5).all()
    return [
        {
            "id": l.id,
            "title": l.title,
            "description": l.description,
            "support_track": l.track,
            "age_band": l.age_band,
            "suggested_for_home": True,
        }
        for l in lessons
    ]


import uuid
from pydantic import BaseModel
from app.models.profile import Profile


class CreateChildProfileRequest(BaseModel):
    display_name: str
    age_band: str = "child"  # child, teen, adult
    support_focus: str = "dld_track"  # dld_track, dyslexia_track, both_track


class AppointSpecialistRequest(BaseModel):
    child_id: str
    specialist_id: Optional[str] = None
    specialist_email: Optional[str] = None
    notes: Optional[str] = None


@router.post("/children", response_model=Dict[str, Any], status_code=status.HTTP_201_CREATED)
async def create_child_profile(
    request: CreateChildProfileRequest,
    current_user: User = Depends(require_role(["parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Creates an authorized child profile linked to the parent.
    Enables instant setup of child learners from the parent dashboard.
    """
    collab_service = CollaborationService(db)

    child_id = str(uuid.uuid4())
    child_email = f"learner_{child_id[:8]}@lingual.internal"

    child_user = User(
        id=child_id,
        email=child_email,
        firebase_uid=f"parent_created_{child_id}",
        role="learner",
        status="active",
    )
    db.add(child_user)

    child_profile = Profile(
        user_id=child_id,
        display_name=request.display_name.strip(),
        age_band=request.age_band,
        support_focus=request.support_focus,
        guardian_consent_status="verified",
        baseline_status="not_started",
    )
    db.add(child_profile)
    db.commit()

    rel = collab_service.repo.create_or_activate_relationship(
        source_user_id=current_user.id,
        target_user_id=child_id,
        relationship_type="parent",
        consent_status="verified",
    )

    return {
        "relationship_id": rel.id,
        "learner_id": child_id,
        "display_name": child_profile.display_name,
        "age_band": child_profile.age_band,
        "support_focus": child_profile.support_focus,
        "status": "active",
    }


@router.post("/appoint-specialist", response_model=Dict[str, Any])
async def appoint_specialist(
    request: AppointSpecialistRequest,
    current_user: User = Depends(require_role(["parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Connects a chosen specialist doctor to an authorized child.
    Establishes an active specialist relationship with verified parental consent.
    """
    collab_service = CollaborationService(db)

    # 1. Verify child belongs to parent
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=request.child_id,
        required_scope="view_progress",
    )

    # 2. Find specialist
    specialist = None
    if request.specialist_id:
        specialist = db.query(User).filter(User.id == request.specialist_id, User.role == "specialist").first()
    elif request.specialist_email:
        specialist = db.query(User).filter(User.email == request.specialist_email.strip().lower(), User.role == "specialist").first()

    if not specialist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Specialist / doctor not found. Please choose an available registered specialist.",
        )

    # 3. Create active relationship: Specialist (source) -> Child (target)
    prof = specialist.profile
    rel = collab_service.repo.create_or_activate_relationship(
        source_user_id=specialist.id,
        target_user_id=request.child_id,
        relationship_type="specialist",
        consent_status="verified",
        organization="Clinical Speech & Language Support",
    )

    raw_name = prof.display_name if (prof and prof.display_name) else specialist.email.split("@")[0].title()
    doc_name = f"Dr. {raw_name}" if not raw_name.lower().startswith("dr") else raw_name

    return {
        "status": "success",
        "message": f"Successfully appointed {doc_name} for your child.",
        "relationship_id": rel.id,
        "specialist_id": specialist.id,
        "specialist_name": doc_name,
        "specialist_email": specialist.email,
        "organization": "Clinical Speech & Language Support",
    }
