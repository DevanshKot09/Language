from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class SkillResponse(BaseModel):
    id: str
    code: str
    name: str
    description: str
    track: str
    domain: str
    age_band_applicability: str
    priority: str
    active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
