from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


# 1. Lesson Recommendation Schemas
class RecommendationRequest(BaseModel):
    user_id: str
    track: str = "dld_track"  # dld_track, dyslexia_track, both
    age_band: str = "all"  # child, teen, adult, all
    candidate_lesson_ids: List[str] = Field(default_factory=list)
    recent_completed_lesson_ids: List[str] = Field(default_factory=list)
    current_goals: List[str] = Field(default_factory=list)


class RecommendedLessonItem(BaseModel):
    lesson_id: str
    reason_code: str
    short_explanation: str
    confidence_level: str = "medium"  # high, medium, low (recommendation confidence only, not clinical)


class RecommendationResponse(BaseModel):
    recommendations: List[RecommendedLessonItem]
    fallback_used: bool = False


# 2. Educational Explanation Schemas
class ExplanationRequest(BaseModel):
    lesson_title: str
    exercise_prompt: str
    target_concept: str
    learner_question: str
    age_band: str = "all"
    context_data: Optional[str] = None


class ExplanationResponse(BaseModel):
    explanation: str
    clarity_tip: Optional[str] = None
    fallback_used: bool = False


# 3. Writing / Speaking Feedback Schemas
class EducationalFeedbackRequest(BaseModel):
    activity_type: str = "writing"  # writing, speaking
    prompt: str
    learner_submission: str
    age_band: str = "all"
    track: str = "dld_track"


class EducationalFeedbackResponse(BaseModel):
    clarity_note: str
    learning_tip: str
    encouragement: str
    revision_suggestion: Optional[str] = None
    fallback_used: bool = False


# 4. Constrained Conversation Schemas
class ConversationTurn(BaseModel):
    role: str  # user, assistant
    text: str


class ConversationRequest(BaseModel):
    scenario_id: str
    scenario_title: str
    scenario_context: str
    age_band: str = "all"
    history: List[ConversationTurn] = Field(default_factory=list)
    user_message: str


class ConversationResponse(BaseModel):
    reply: str
    followup_prompt: Optional[str] = None
    is_scenario_complete: bool = False
    fallback_used: bool = False


# 5. Progress Insights Schemas
class ProgressInsightRequest(BaseModel):
    age_band: str = "all"
    track: str = "dld_track"
    completed_lesson_count: int
    practice_attempt_count: int
    active_goals: List[str] = Field(default_factory=list)
    recent_skills: List[str] = Field(default_factory=list)


class ProgressInsightResponse(BaseModel):
    practice_summary: str
    what_went_well: str
    next_practice_area: str
    encouraging_note: str
    fallback_used: bool = False
