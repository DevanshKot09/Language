from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, get_firebase_claims
from app.models.user import User
from app.schemas.auth import (
    FirebaseSyncRequest,
    LogoutRequest,
    AuthSessionResponse,
)
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "/sync",
    response_model=AuthSessionResponse,
    status_code=status.HTTP_200_OK,
    summary="Synchronize Firebase authenticated user into Supabase PostgreSQL",
)
def sync_user(
    sync_data: Optional[FirebaseSyncRequest] = None,
    claims: Dict[str, Any] = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
):
    """
    Called by Flutter client immediately after Firebase sign-in or sign-up.
    Verifies Firebase ID token, creates or updates application user in Supabase,
    and returns full profile, accessibility preferences, and onboarding state.
    """
    return AuthService.sync_firebase_user(db=db, claims=claims, sync_data=sync_data)


@router.get(
    "/me",
    response_model=AuthSessionResponse,
    summary="Get authenticated user identity, profile, preferences, and onboarding state",
)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Returns application domain state for the authenticated Firebase user.
    """
    return AuthService.get_me(current_user)


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Log application session logout event",
)
def logout(
    request: Optional[LogoutRequest] = None,
    current_user: User = Depends(get_current_user),
):
    """
    Audits user sign-out on the application server.
    Client-side Firebase auth token invalidation is handled by Firebase SDK.
    """
    reason = request.reason if request else None
    AuthService.logout(current_user, reason)
    return {"status": "success", "message": "Successfully logged out."}
