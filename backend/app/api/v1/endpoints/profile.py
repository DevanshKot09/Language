from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.profile import (
    ProfileResponse,
    ProfileUpdateRequest,
    AccessibilityPreferencesResponse,
    AccessibilityPreferencesUpdate,
    OnboardingResponse,
    OnboardingUpdateRequest,
)
from app.services.profile_service import ProfileService

router = APIRouter()


@router.get(
    "/",
    response_model=ProfileResponse,
    summary="Get current user profile",
)
def get_profile(current_user: User = Depends(get_current_user)):
    return ProfileService.get_user_profile(current_user)


@router.put(
    "/",
    response_model=ProfileResponse,
    summary="Update current user profile (display name, age band, support focus)",
)
def update_profile(
    request: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return ProfileService.update_profile(db, current_user, request)


@router.put(
    "/onboarding",
    response_model=OnboardingResponse,
    summary="Update onboarding progress and completion status",
)
def update_onboarding(
    request: OnboardingUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return ProfileService.update_onboarding_state(db, current_user, request)


@router.put(
    "/accessibility",
    response_model=AccessibilityPreferencesResponse,
    summary="Update accessibility preferences",
)
def update_accessibility(
    request: AccessibilityPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return ProfileService.update_accessibility_preferences(db, current_user, request)
