import json
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, field_validator


class BaselineActivityResponse(BaseModel):
    id: str
    skill_id: str
    track: str
    domain: str
    age_band: str
    activity_type: str
    instruction: str
    prompt: str
    options: List[str]
    hint: Optional[str] = None
    difficulty: int

    @field_validator("options", mode="before")
    def parse_options(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except Exception:
                return [v]
        return v

    model_config = ConfigDict(from_attributes=True)


class BaselineSessionResponse(BaseModel):
    id: str
    user_id: str
    track: str
    status: str
    total_activities: int
    completed_activities: int
    started_at: datetime
    completed_at: Optional[datetime] = None
    activities: List[BaselineActivityResponse] = []

    model_config = ConfigDict(from_attributes=True)


class BaselineResponseRequest(BaseModel):
    activity_id: str
    selected_option: str
    time_taken_ms: int = 0


class BaselineResponseResult(BaseModel):
    activity_id: str
    is_correct: bool
    correct_answer: str
    completed_activities: int
    total_activities: int
    is_session_complete: bool


class SkillSnapshotItem(BaseModel):
    skill_id: str
    skill_code: str
    skill_name: str
    track: str
    domain: str
    band: str  # Starting, Developing, Practicing, Consistent
    score: float
    accuracy: float
    description: str

    model_config = ConfigDict(from_attributes=True)


class SkillSnapshotResponse(BaseModel):
    user_id: str
    baseline_status: str
    completed_at: Optional[datetime] = None
    skills: List[SkillSnapshotItem] = []
    strength_areas: List[str] = []
    priority_practice_areas: List[str] = []
    non_diagnostic_notice: str = (
        "Informational Practice Snapshot: Skills are categorized by learning readiness "
        "(Starting, Developing, Practicing, Consistent) to shape your daily practice path. "
        "This is an educational guide, not a medical or clinical assessment."
    )
