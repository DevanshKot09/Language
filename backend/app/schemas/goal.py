from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class GoalCreateRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=255)
    description: Optional[str] = Field(None, max_length=500)
    skill_id: Optional[str] = None
    goal_type: str = Field(
        default="complete_lessons",
        description="complete_lessons, practice_sessions, practice_skill, milestone"
    )
    target_count: int = Field(default=3, ge=1, le=100)
    target_frequency: str = Field(default="weekly", description="daily, weekly, biweekly")
    target_behavior: Optional[str] = None


class GoalUpdateRequest(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = Field(None, max_length=500)
    target_count: Optional[int] = Field(None, ge=1, le=100)
    target_frequency: Optional[str] = None
    target_behavior: Optional[str] = None
    status: Optional[str] = Field(None, description="active, completed, achieved, paused")


class GoalResponse(BaseModel):
    id: str
    user_id: str
    skill_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    goal_type: str = "complete_lessons"
    target_count: int = 3
    current_count: int = 0
    target_frequency: str = "weekly"
    target_behavior: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
