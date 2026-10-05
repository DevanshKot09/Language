from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_role, get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.ai import Recommendation
from app.schemas.collaboration import (
    SpecialistAiReviewRequest,
    SpecialistConversationResponse,
    ChatMessageResponse,
    ChatMessageCreateRequest,
)
from app.schemas.progress import ProgressDashboardResponse
from app.schemas.goal import GoalCreateRequest, GoalResponse
from app.services.collaboration_service import CollaborationService
from app.services.progress_service import ProgressService
from app.repositories.goal_repository import GoalRepository

router = APIRouter()


@router.get("", response_model=List[Dict[str, Any]])
async def list_available_specialists(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns list of registered educational and clinical specialists
    available for parent appointment and collaboration.
    """
    specialists = (
        db.query(User)
        .filter(User.role == "specialist", User.status == "active")
        .all()
    )
    result = []
    for s in specialists:
        prof = s.profile
        raw_name = prof.display_name if (prof and prof.display_name) else s.email.split("@")[0].title()
        doc_name = f"Dr. {raw_name}" if not raw_name.lower().startswith("dr") else raw_name
        focus = prof.support_focus if prof else "dld_track"
        result.append({
            "id": s.id,
            "display_name": doc_name,
            "email": s.email,
            "organization": "Speech & Literacy Clinical Practice",
            "support_focus": focus,
        })
    return result


@router.get("/caseload", response_model=List[Dict[str, Any]])
async def get_specialist_caseload(
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns caseload of authorized learners.
    Specialists can only see learners with an active relationship.
    """
    service = CollaborationService(db)
    return service.get_specialist_caseload(current_user)


@router.get("/learners/{learner_id}", response_model=Dict[str, Any])
async def get_specialist_learner_detail(
    learner_id: str,
    current_user: User = Depends(require_role(["specialist", "teacher", "parent", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns full learning support dossier for a caseload learner.
    Includes profile configuration, baseline summary, skill history, and goals.
    Strictly non-diagnostic educational information.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=learner_id,
        required_scope="view_profile",
    )

    learner = db.query(User).filter(User.id == learner_id).first()
    if not learner:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learner not found.")

    prof = learner.profile
    progress = ProgressService.get_progress_dashboard(db, learner, include_ai_insight=False)

    # List AI recommendations pending review
    pending_recs = (
        db.query(Recommendation)
        .filter(Recommendation.user_id == learner.id)
        .order_by(Recommendation.created_at.desc())
        .limit(10)
        .all()
    )

    return {
        "learner_id": learner.id,
        "display_name": prof.display_name if prof else "Learner",
        "age_band": prof.age_band if prof else "teen",
        "support_focus": prof.support_focus if prof else "dld_track",
        "baseline_status": prof.baseline_status if prof else "not_started",
        "progress_summary": progress.summary.model_dump(),
        "skills": [s.model_dump() for s in progress.skills],
        "goals": [g.model_dump() for g in progress.goals],
        "achievements": [a.model_dump() for a in progress.achievements],
        "ai_recommendations": [
            {
                "id": r.id,
                "lesson_id": r.lesson_id,
                "lesson_title": r.lesson.title if r.lesson else "Lesson",
                "reason_code": r.reason_code,
                "short_explanation": r.short_explanation,
                "status": r.status,
                "human_reviewed": r.human_reviewed,
                "human_status": r.human_status,
                "created_at": r.created_at,
            }
            for r in pending_recs
        ],
    }


@router.post("/learners/{learner_id}/goals", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
async def create_specialist_goal(
    learner_id: str,
    request: GoalCreateRequest,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Create a professional learning-support goal for an authorized learner.
    Enforces 'create_goal' scope. Preserves distinction between learner and specialist goals.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=learner_id,
        required_scope="create_goal",
    )

    learner = db.query(User).filter(User.id == learner_id).first()
    if not learner:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learner not found.")

    desc = f"[Specialist Support Goal] {request.description or ''}".strip()
    goal = GoalRepository.create_goal(
        db=db,
        user_id=learner_id,
        title=request.title,
        description=desc,
        goal_type=request.goal_type,
        target_count=request.target_count,
        skill_id=request.skill_id,
    )
    return GoalResponse.model_validate(goal)


@router.get("/learners/{learner_id}/ai-recommendations")
async def get_learner_ai_recommendations(
    learner_id: str,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Lists AI recommendations for a caseload learner for professional review.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=learner_id,
        required_scope="view_ai_recommendations",
    )

    recs = (
        db.query(Recommendation)
        .filter(Recommendation.user_id == learner_id)
        .order_by(Recommendation.created_at.desc())
        .all()
    )
    return [
        {
            "id": r.id,
            "lesson_id": r.lesson_id,
            "lesson_title": r.lesson.title if r.lesson else "Lesson",
            "reason_code": r.reason_code,
            "short_explanation": r.short_explanation,
            "status": r.status,
            "human_reviewed": r.human_reviewed,
            "human_status": r.human_status,
            "created_at": r.created_at,
        }
        for r in recs
    ]


@router.put("/ai-recommendations/{rec_id}")
async def review_ai_recommendation(
    rec_id: str,
    request: SpecialistAiReviewRequest,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Specialist human oversight of an AI recommendation (Step 15, 16, 36, 37).
    Human actions: 'approved', 'modified', 'rejected'.
    Does not mutate underlying progress data.
    """
    rec = db.query(Recommendation).filter(Recommendation.id == rec_id).first()
    if not rec:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recommendation not found.")

    service = CollaborationService(db)
    updated = service.review_ai_recommendation(
        specialist=current_user,
        learner_id=rec.user_id,
        recommendation_id=rec.id,
        human_status=request.human_status,
        modified_reason=request.modified_reason,
        modified_lesson_id=request.modified_lesson_id,
    )
    return {
        "message": f"Recommendation successfully marked as {updated.human_status}.",
        "recommendation_id": updated.id,
        "human_status": updated.human_status,
        "human_reviewed": updated.human_reviewed,
        "human_reviewer_id": updated.human_reviewer_id,
    }


@router.get("/conversations", response_model=List[SpecialistConversationResponse])
async def get_specialist_conversations(
    filter: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns authorized communication threads and collaboration groups for the specialist.
    Enforces server-side RBAC and guardian consent rules.
    Strictly non-diagnostic educational collaboration.
    """
    service = CollaborationService(db)
    return service.get_specialist_conversations(
        specialist_user=current_user,
        filter_type=filter,
        search=search,
    )


@router.get("/conversations/{conversation_id}/messages", response_model=List[ChatMessageResponse])
async def get_conversation_messages(
    conversation_id: str,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns verified collaboration messages for the conversation thread.
    Enforces specialist authorization and privacy rules.
    """
    service = CollaborationService(db)
    return service.get_conversation_messages(
        specialist_user=current_user,
        conversation_id=conversation_id,
    )


@router.post("/conversations/{conversation_id}/messages", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
async def send_conversation_message(
    conversation_id: str,
    request: ChatMessageCreateRequest,
    current_user: User = Depends(require_role(["specialist", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Sends a new support guidance message into the conversation thread.
    Enforces specialist role and non-empty content validation.
    """
    service = CollaborationService(db)
    return service.send_conversation_message(
        specialist_user=current_user,
        conversation_id=conversation_id,
        content=request.content,
        attachment_id=request.attachment_id,
    )

