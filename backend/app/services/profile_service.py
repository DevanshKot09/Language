from typing import Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.profile import (
    ProfileResponse,
    ProfileUpdateRequest,
    AccessibilityPreferencesResponse,
    AccessibilityPreferencesUpdate,
    OnboardingResponse,
    OnboardingUpdateRequest,
)


class ProfileService:
    @staticmethod
    def get_user_profile(user: User) -> ProfileResponse:
        if not user.profile:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
        return ProfileResponse.model_validate(user.profile)

    @staticmethod
    def update_profile(db: Session, user: User, update_data: ProfileUpdateRequest) -> ProfileResponse:
        if not user.profile:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")

        updates = update_data.model_dump(exclude_unset=True)

        # Validate non-diagnostic boundary choices
        if "age_band" in updates and updates["age_band"] not in ("child", "teen", "adult"):
            raise HTTPException(status_code=400, detail="Invalid age band.")
        if "support_focus" in updates and updates["support_focus"] not in ("dld_track", "dyslexia_track", "both_track"):
            raise HTTPException(status_code=400, detail="Invalid support focus track.")
        if "guardian_consent_status" in updates and updates["guardian_consent_status"] not in ("not_required", "pending", "verified"):
            raise HTTPException(status_code=400, detail="Invalid guardian consent status.")

        updated = UserRepository.update_profile(db, user.profile, updates)
        return ProfileResponse.model_validate(updated)

    @staticmethod
    def update_onboarding_state(db: Session, user: User, update_data: OnboardingUpdateRequest) -> OnboardingResponse:
        if not user.onboarding_state:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Onboarding state not found.")

        updates = update_data.model_dump(exclude_unset=True)

        # If role or age or track were selected during onboarding, synchronize with user and profile
        if "role" in updates and updates["role"]:
            user.role = updates.pop("role")
            db.add(user)
        if "age_band" in updates and updates["age_band"] and user.profile:
            user.profile.age_band = updates.pop("age_band")
            if user.profile.age_band == "child" and user.profile.guardian_consent_status == "not_required":
                user.profile.guardian_consent_status = "pending"
            db.add(user.profile)
        if "support_focus" in updates and updates["support_focus"] and user.profile:
            user.profile.support_focus = updates.pop("support_focus")
            db.add(user.profile)

        updated = UserRepository.update_onboarding_state(db, user.onboarding_state, updates)
        return OnboardingResponse.model_validate(updated)

    @staticmethod
    def update_accessibility_preferences(
        db: Session,
        user: User,
        update_data: AccessibilityPreferencesUpdate,
    ) -> AccessibilityPreferencesResponse:
        if not user.accessibility_preferences:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Preferences not found.")

        updates = update_data.model_dump(exclude_unset=True)
        updated = UserRepository.update_accessibility_preferences(db, user.accessibility_preferences, updates)
        return AccessibilityPreferencesResponse.model_validate(updated)
