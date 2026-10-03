from fastapi import APIRouter, Depends, HTTPException, status
from app.core.config import settings
from app.api.deps import get_current_user
from app.models.user import User
from app.ai.orchestrator import ai_orchestrator
from app.ai.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    ExplanationRequest,
    ExplanationResponse,
    EducationalFeedbackRequest,
    EducationalFeedbackResponse,
    ConversationRequest,
    ConversationResponse,
    ProgressInsightRequest,
    ProgressInsightResponse,
)

router = APIRouter()


@router.get("/status")
async def get_ai_status(current_user: User = Depends(get_current_user)):
    """
    Returns runtime AI capability status, active provider, and child data protection gate.
    """
    return {
        "ai_enabled": settings.AI_ENABLED,
        "provider": ai_orchestrator.provider.provider_name,
        "model": settings.AI_MODEL,
        "child_cloud_allowed": settings.AI_CHILD_CLOUD_ALLOWED,
        "safety_guardrails": "enforced",
        "diagnostic_processing": "prohibited",
    }


@router.post("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(
    request: RecommendationRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Personalized lesson recommendations constrained strictly to server-provided candidate IDs.
    """
    if request.user_id != current_user.id:
        request.user_id = current_user.id

    return await ai_orchestrator.get_recommendations(request)


@router.post("/explanations", response_model=ExplanationResponse)
async def get_explanation(
    request: ExplanationRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Educational explanations for concepts and exercise questions.
    """
    return await ai_orchestrator.get_explanation(request)


@router.post("/feedback", response_model=EducationalFeedbackResponse)
async def get_feedback(
    request: EducationalFeedbackRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Educational feedback on learner writing or speech recognition transcript.
    """
    return await ai_orchestrator.get_feedback(request)


@router.post("/conversation", response_model=ConversationResponse)
async def get_conversation_reply(
    request: ConversationRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Constrained educational scenario practice conversation.
    """
    return await ai_orchestrator.get_conversation_reply(request)


@router.post("/progress-insight", response_model=ProgressInsightResponse)
async def get_progress_insight(
    request: ProgressInsightRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Educational progress summaries based on actual completed activity numbers.
    """
    return await ai_orchestrator.get_progress_insight(request)
