from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ConfigDict


class ExerciseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_id: str
    skill_id: str
    exercise_type: str
    prompt: str
    instruction: str
    content: Any  # Deserialized content (options, pairs, tokens, passage)
    difficulty: int
    age_band: str
    track: str
    sequence_order: int
    hints: Optional[List[str]] = None
    explanation: Optional[str] = None


class ExerciseAttemptRequest(BaseModel):
    response: Any = Field(..., description="Learner answer: string, token array, or dictionary of matching pairs")
    attempt_number: int = Field(default=1, ge=1)
    time_spent_ms: int = Field(default=0, ge=0)
    hint_used: bool = Field(default=False)


class ExerciseAttemptResponse(BaseModel):
    attempt_id: str
    status: str  # correct, partially_correct, incorrect
    is_correct: bool
    partial_score: float
    feedback_message: str
    explanation: Optional[str] = None
    current_exercise_index: int
    next_exercise_index: Optional[int] = None
    lesson_completed: bool


class LessonSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    skill_id: str
    skill_name: Optional[str] = None
    title: str
    description: str
    track: str
    age_band: str
    difficulty: int
    sequence_order: int
    estimated_effort_minutes: int
    total_exercises: int
    user_status: str  # not_started, in_progress, completed
    current_exercise_index: int
    completed_exercises: int


class LessonDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    skill_id: str
    skill_name: Optional[str] = None
    title: str
    description: str
    track: str
    age_band: str
    difficulty: int
    sequence_order: int
    estimated_effort_minutes: int
    total_exercises: int
    user_status: str
    current_exercise_index: int
    exercises: List[ExerciseResponse]



class LessonProgressResponse(BaseModel):
    lesson_id: str
    current_exercise_index: int
    status: str
    score: Optional[float] = None
    completed_at: Optional[str] = None
    total_exercises: int
    completed_exercises: int


class SkillProgressItem(BaseModel):
    skill_id: str
    skill_code: str
    skill_name: str
    track: str
    completed_lessons: int
    total_lessons: int
    mastery_status: str  # Starting, Developing, Practicing, Consistent


class PracticeHubResponse(BaseModel):
    recommended_lessons: List[LessonSummaryResponse]
    in_progress_lessons: List[LessonSummaryResponse]
    completed_lessons: List[LessonSummaryResponse]
    skills_summary: List[SkillProgressItem]


class LearningPathNodeResponse(BaseModel):
    step_number: int
    lesson_id: str
    title: str
    track: str
    skill_name: str
    status: str  # completed, active, unlocked, upcoming
    is_completed: bool
    is_active: bool
    difficulty: int


class LearningPathResponse(BaseModel):
    track: str
    nodes: List[LearningPathNodeResponse]
