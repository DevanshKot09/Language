import logging
from typing import Optional, List
from app.core.config import settings
from app.ai.provider_interface import IAiProvider
from app.ai.gemini_provider import GeminiAiProvider
from app.ai.mock_provider import MockAiProvider
from app.ai.safety import AiSafetyValidator
from app.ai.prompts import (
    get_recommendation_prompt,
    get_explanation_prompt,
    get_educational_feedback_prompt,
    get_conversation_prompt,
    get_progress_insight_prompt,
)
from app.ai.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    RecommendedLessonItem,
    ExplanationRequest,
    ExplanationResponse,
    EducationalFeedbackRequest,
    EducationalFeedbackResponse,
    ConversationRequest,
    ConversationResponse,
    ProgressInsightRequest,
    ProgressInsightResponse,
)

logger = logging.getLogger(__name__)


class AiOrchestrator:
    """
    Central orchestration and policy service for all AI capabilities in LINGUA AI.
    Applies:
    1. AI Enabled / Child Cloud switches.
    2. Input data minimization.
    3. Provider invocation via IAiProvider.
    4. Strict JSON schema validation.
    5. Post-generation safety and non-diagnostic policy scans.
    6. Deterministic fallback on any failure.
    """

    def __init__(self, provider: Optional[IAiProvider] = None):
        if provider:
            self._provider = provider
        elif settings.AI_PROVIDER == "mock" or not settings.GEMINI_API_KEY:
            self._provider = MockAiProvider()
        else:
            self._provider = GeminiAiProvider()

    @property
    def provider(self) -> IAiProvider:
        return self._provider

    # 1. Lesson Recommendation with Candidate Enforcement
    async def get_recommendations(self, request: RecommendationRequest) -> RecommendationResponse:
        # Check if AI is disabled or candidate set is empty
        if not settings.AI_ENABLED or not request.candidate_lesson_ids:
            return self._fallback_recommendation(request)

        # Check Child Mode gate
        if request.age_band == "child" and not settings.AI_CHILD_CLOUD_ALLOWED:
            return self._fallback_recommendation(request)

        try:
            prompt = get_recommendation_prompt(
                age_band=request.age_band,
                track=request.track,
                candidate_ids=request.candidate_lesson_ids,
                recent_ids=request.recent_completed_lesson_ids,
                goals=request.current_goals,
            )

            result = await self._provider.generate_structured(
                prompt=prompt,
                response_schema=RecommendationResponse,
            )

            # Validate that returned lesson IDs are strictly within candidate set
            validated_recs = []
            for item in result.recommendations:
                if item.lesson_id in request.candidate_lesson_ids:
                    # Validate non-diagnostic safety
                    is_safe, _ = AiSafetyValidator.validate_text(item.short_explanation)
                    if is_safe:
                        validated_recs.append(item)

            if validated_recs:
                return RecommendationResponse(recommendations=validated_recs, fallback_used=False)

            return self._fallback_recommendation(request)
        except Exception as e:
            logger.warning(f"[AiOrchestrator] Recommendation failure: {e}. Using deterministic fallback.")
            return self._fallback_recommendation(request)

    def _fallback_recommendation(self, request: RecommendationRequest) -> RecommendationResponse:
        cand_id = request.candidate_lesson_ids[0] if request.candidate_lesson_ids else "lesson-dld-001"
        return RecommendationResponse(
            recommendations=[
                RecommendedLessonItem(
                    lesson_id=cand_id,
                    reason_code="curriculum_sequence",
                    short_explanation="Next sequential lesson aligned with your current learning goals.",
                    confidence_level="high",
                )
            ],
            fallback_used=True,
        )

    # 2. Educational Explanation
    async def get_explanation(self, request: ExplanationRequest) -> ExplanationResponse:
        if not settings.AI_ENABLED:
            return self._fallback_explanation()

        if request.age_band == "child" and not settings.AI_CHILD_CLOUD_ALLOWED:
            return self._fallback_explanation()

        try:
            prompt = get_explanation_prompt(
                age_band=request.age_band,
                lesson_title=request.lesson_title,
                exercise_prompt=request.exercise_prompt,
                target_concept=request.target_concept,
                learner_question=request.learner_question,
            )

            result = await self._provider.generate_structured(
                prompt=prompt,
                response_schema=ExplanationResponse,
            )

            # Validate safety
            is_safe, reason = AiSafetyValidator.validate_text(result.explanation)
            if not is_safe:
                logger.warning(f"[AiOrchestrator] Explanation rejected by safety policy: {reason}")
                return self._fallback_explanation()

            return result
        except Exception as e:
            logger.warning(f"[AiOrchestrator] Explanation failure: {e}. Using fallback.")
            return self._fallback_explanation()

    def _fallback_explanation(self) -> ExplanationResponse:
        return ExplanationResponse(
            explanation="This activity highlights foundational sentence structure and clear word choices.",
            clarity_tip="Review the example clue in the activity card.",
            fallback_used=True,
        )

    # 3. Writing / Speaking Educational Feedback
    async def get_feedback(self, request: EducationalFeedbackRequest) -> EducationalFeedbackResponse:
        if not settings.AI_ENABLED:
            return self._fallback_feedback(request)

        if request.age_band == "child" and not settings.AI_CHILD_CLOUD_ALLOWED:
            return self._fallback_feedback(request)

        try:
            prompt = get_educational_feedback_prompt(
                activity_type=request.activity_type,
                prompt=request.prompt,
                learner_submission=request.learner_submission,
                age_band=request.age_band,
            )

            result = await self._provider.generate_structured(
                prompt=prompt,
                response_schema=EducationalFeedbackResponse,
            )

            # Validate safety across feedback fields
            is_safe_note, _ = AiSafetyValidator.validate_text(result.clarity_note)
            is_safe_tip, _ = AiSafetyValidator.validate_text(result.learning_tip)
            if not is_safe_note or not is_safe_tip:
                return self._fallback_feedback(request)

            return result
        except Exception as e:
            logger.warning(f"[AiOrchestrator] Feedback failure: {e}. Using fallback.")
            return self._fallback_feedback(request)

    def _fallback_feedback(self, request: EducationalFeedbackRequest) -> EducationalFeedbackResponse:
        return EducationalFeedbackResponse(
            clarity_note="Your response communicates your idea clearly.",
            learning_tip="Notice how complete sentences help your listener understand your message.",
            encouragement="Great effort practicing your language skills!",
            revision_suggestion=None,
            fallback_used=True,
        )

    # 4. Constrained Scenario Conversation
    async def get_conversation_reply(self, request: ConversationRequest) -> ConversationResponse:
        if not settings.AI_ENABLED:
            return self._fallback_conversation()

        if request.age_band == "child" and not settings.AI_CHILD_CLOUD_ALLOWED:
            return self._fallback_conversation()

        try:
            prompt = get_conversation_prompt(
                scenario_title=request.scenario_title,
                scenario_context=request.scenario_context,
                age_band=request.age_band,
                user_message=request.user_message,
            )

            result = await self._provider.generate_structured(
                prompt=prompt,
                response_schema=ConversationResponse,
            )

            is_safe, _ = AiSafetyValidator.validate_text(result.reply)
            if not is_safe:
                return self._fallback_conversation()

            return result
        except Exception as e:
            logger.warning(f"[AiOrchestrator] Conversation failure: {e}. Using fallback.")
            return self._fallback_conversation()

    def _fallback_conversation(self) -> ConversationResponse:
        return ConversationResponse(
            reply="Thank you for sharing that. What is one more detail you would like to add?",
            followup_prompt="Tell me what happens next.",
            is_scenario_complete=False,
            fallback_used=True,
        )

    # 5. Progress Insights
    async def get_progress_insight(self, request: ProgressInsightRequest) -> ProgressInsightResponse:
        if not settings.AI_ENABLED:
            return self._fallback_progress_insight(request)

        try:
            prompt = get_progress_insight_prompt(
                age_band=request.age_band,
                track=request.track,
                lesson_count=request.completed_lesson_count,
                attempt_count=request.practice_attempt_count,
                goals=request.active_goals,
                skills=request.recent_skills,
            )

            result = await self._provider.generate_structured(
                prompt=prompt,
                response_schema=ProgressInsightResponse,
            )

            is_safe, _ = AiSafetyValidator.validate_text(result.what_went_well)
            if not is_safe:
                return self._fallback_progress_insight(request)

            return result
        except Exception as e:
            logger.warning(f"[AiOrchestrator] Progress insight failure: {e}. Using fallback.")
            return self._fallback_progress_insight(request)

    def _fallback_progress_insight(self, request: ProgressInsightRequest) -> ProgressInsightResponse:
        return ProgressInsightResponse(
            practice_summary=f"You have completed {request.completed_lesson_count} lessons with {request.practice_attempt_count} practice activities.",
            what_went_well="You have maintained steady practice toward your goals.",
            next_practice_area="Continue with your recommended daily practice session.",
            encouraging_note="Every practice session builds confidence and skill!",
            fallback_used=True,
        )


# Global singleton instance
ai_orchestrator = AiOrchestrator()
