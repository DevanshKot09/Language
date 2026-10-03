import logging
from typing import Type, TypeVar, Optional, Dict, Any
from pydantic import BaseModel
from app.ai.provider_interface import IAiProvider
from app.ai.schemas import (
    RecommendationResponse,
    RecommendedLessonItem,
    ExplanationResponse,
    EducationalFeedbackResponse,
    ConversationResponse,
    ProgressInsightResponse,
)

logger = logging.getLogger(__name__)
T = TypeVar("T", bound=BaseModel)


class MockAiProvider(IAiProvider):
    """
    Mock AI Provider for deterministic unit testing, offline development,
    and fast reliable execution without external network dependence.
    """

    def __init__(self, custom_responses: Optional[Dict[str, Any]] = None):
        self._custom_responses = custom_responses or {}

    @property
    def provider_name(self) -> str:
        return "mock"

    async def generate_structured(
        self,
        prompt: str,
        response_schema: Type[T],
        temperature: float = 0.2,
    ) -> T:
        schema_name = response_schema.__name__

        if schema_name in self._custom_responses:
            return response_schema.model_validate(self._custom_responses[schema_name])

        if schema_name == "RecommendationResponse":
            # Extract candidate if available
            cand = "lesson-dld-001"
            return response_schema.model_validate({
                "recommendations": [
                    {
                        "lesson_id": cand,
                        "reason_code": "prerequisite_aligned",
                        "short_explanation": "Strengthens current vocabulary and phrase building skills.",
                        "confidence_level": "high",
                    }
                ],
                "fallback_used": False,
            })

        elif schema_name == "ExplanationResponse":
            return response_schema.model_validate({
                "explanation": "This word connects two contrasting ideas in a sentence smoothly.",
                "clarity_tip": "Notice how the second clause shares additional detail.",
                "fallback_used": False,
            })

        elif schema_name == "EducationalFeedbackResponse":
            return response_schema.model_validate({
                "clarity_note": "Great clear explanation of your ideas.",
                "learning_tip": "Try joining two shorter thoughts with 'because' to show cause.",
                "encouragement": "Fantastic effort and expression!",
                "revision_suggestion": "I liked science class because we explored planets.",
                "fallback_used": False,
            })

        elif schema_name == "ConversationResponse":
            return response_schema.model_validate({
                "reply": "That sounds like a great start! What would you like to prepare next?",
                "followup_prompt": "Tell me one more detail about your plan.",
                "is_scenario_complete": False,
                "fallback_used": False,
            })

        elif schema_name == "ProgressInsightResponse":
            return response_schema.model_validate({
                "practice_summary": "You have completed your scheduled practice sessions with steady effort.",
                "what_went_well": "Consistent engagement across reading and oral language tasks.",
                "next_practice_area": "Complex sentence construction",
                "encouraging_note": "Keep up the wonderful curiosity and practice!",
                "fallback_used": False,
            })

        raise ValueError(f"Mock response not defined for schema: {schema_name}")
