from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class ProfileResponse(BaseModel):
    id: str
    user_id: str
    display_name: str
    age_band: str
    support_focus: str
    guardian_consent_status: str
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    age_band: Optional[str] = Field(None, description="child, teen, adult")
    support_focus: Optional[str] = Field(None, description="dld_track, dyslexia_track, both_track")
    guardian_consent_status: Optional[str] = Field(None, description="not_required, pending, verified")


class AccessibilityPreferencesResponse(BaseModel):
    font_scale: float
    use_dyslexic_font: bool
    high_contrast: bool
    reduced_motion: bool
    tts_auto_play: bool
    speech_rate: float
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AccessibilityPreferencesUpdate(BaseModel):
    font_scale: Optional[float] = Field(None, ge=0.8, le=2.0)
    use_dyslexic_font: Optional[bool] = None
    high_contrast: Optional[bool] = None
    reduced_motion: Optional[bool] = None
    tts_auto_play: Optional[bool] = None
    speech_rate: Optional[float] = Field(None, ge=0.5, le=2.0)


class OnboardingResponse(BaseModel):
    is_completed: bool
    current_step: str
    completed_at: Optional[datetime] = None
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class OnboardingUpdateRequest(BaseModel):
    is_completed: Optional[bool] = None
    current_step: Optional[str] = None
    role: Optional[str] = None
    age_band: Optional[str] = None
    support_focus: Optional[str] = None
