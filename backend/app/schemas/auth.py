from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class FirebaseSyncRequest(BaseModel):
    """
    Payload sent alongside Firebase ID Token to initialize or synchronize
    user domain profile, role, and accessibility preferences in Supabase PostgreSQL.
    """
    role: str = Field(default="learner", description="learner, parent, teacher, specialist")
    age_band: str = Field(default="teen", description="child, teen, adult")
    support_focus: str = Field(default="dld_track", description="dld_track, dyslexia_track, both_track")
    display_name: Optional[str] = None
    terms_acknowledged: bool = Field(default=True, description="Must acknowledge terms of service and privacy policy")
    non_diagnostic_acknowledged: bool = Field(
        default=True,
        description="Must acknowledge that LINGUA AI provides educational practice, not clinical/medical diagnosis",
    )

    @model_validator(mode="after")
    def validate_sync_data(self) -> "FirebaseSyncRequest":
        if not self.terms_acknowledged:
            raise ValueError("You must acknowledge the terms and privacy policy to continue.")
        if not self.non_diagnostic_acknowledged:
            raise ValueError("You must acknowledge that LINGUA AI provides educational support and is not a medical diagnosis.")
        if self.role not in ("learner", "parent", "teacher", "specialist"):
            raise ValueError("Invalid user role selected.")
        if self.age_band not in ("child", "teen", "adult"):
            raise ValueError("Invalid age band selected.")
        if self.support_focus not in ("dld_track", "dyslexia_track", "both_track"):
            raise ValueError("Invalid support focus selected.")
        return self


class UserResponse(BaseModel):
    id: str
    firebase_uid: str
    email: str
    role: str
    status: str
    created_at: datetime
    last_login_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ProfileSummary(BaseModel):
    display_name: str
    age_band: str
    support_focus: str
    guardian_consent_status: str

    model_config = ConfigDict(from_attributes=True)


class AccessibilitySummary(BaseModel):
    font_scale: float
    use_dyslexic_font: bool
    high_contrast: bool
    reduced_motion: bool
    tts_auto_play: bool
    speech_rate: float

    model_config = ConfigDict(from_attributes=True)


class OnboardingSummary(BaseModel):
    is_completed: bool
    current_step: str
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class AuthSessionResponse(BaseModel):
    user: UserResponse
    profile: ProfileSummary
    accessibility: AccessibilitySummary
    onboarding: OnboardingSummary


class LogoutRequest(BaseModel):
    reason: Optional[str] = None
