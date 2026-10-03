from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class AchievementResponse(BaseModel):
    id: str
    code: str
    title: str
    description: str
    category: str
    icon_name: str
    threshold: int
    badge_tier: str
    is_unlocked: bool = False
    unlocked_at: Optional[datetime] = None
    progress_value: int = 0

    model_config = ConfigDict(from_attributes=True)


class AchievementUnlockNotification(BaseModel):
    achievement: AchievementResponse
    message: str
    unlocked_at: datetime
