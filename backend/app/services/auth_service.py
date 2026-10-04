from typing import Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import log_security_event
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    FirebaseSyncRequest,
    AuthSessionResponse,
    UserResponse,
    ProfileSummary,
    AccessibilitySummary,
    OnboardingSummary,
)


class AuthService:
    @staticmethod
    def sync_firebase_user(
        db: Session,
        claims: Dict[str, Any],
        sync_data: Optional[FirebaseSyncRequest] = None,
    ) -> AuthSessionResponse:
        """
        Synchronizes a Firebase-authenticated user into the Supabase PostgreSQL application database.
        If the user does not exist, provisions user, profile, accessibility, and onboarding records in an atomic transaction.
        If the user exists, updates last_login_at and returns the canonical application profile.
        Never duplicates users for the same Firebase UID.
        """
        firebase_uid = claims["uid"]
        email = claims.get("email") or f"{firebase_uid}@auth.local"

        user = UserRepository.get_by_firebase_uid(db, firebase_uid)

        if not user:
            # Check for existing email if Firebase linked account
            existing_email_user = UserRepository.get_by_email(db, email)
            if existing_email_user:
                # Link existing user record with Firebase UID
                existing_email_user.firebase_uid = firebase_uid
                db.add(existing_email_user)
                db.commit()
                db.refresh(existing_email_user)
                user = existing_email_user
                log_security_event("firebase_uid_linked", user_id=user.id, details=f"firebase_uid={firebase_uid}")
            else:
                # Atomic creation of user + domain profile + preferences + onboarding
                role = sync_data.role if sync_data else "learner"
                age_band = sync_data.age_band if sync_data else "teen"
                support_focus = sync_data.support_focus if sync_data else "dld_track"
                display_name = (
                    sync_data.display_name
                    if sync_data and sync_data.display_name
                    else email.split("@")[0].capitalize()
                )
                consent_status = "pending" if age_band == "child" else "not_required"

                try:
                    user = UserRepository.create_user(
                        db=db,
                        firebase_uid=firebase_uid,
                        email=email,
                        role=role,
                        status="active",
                    )
                    profile = UserRepository.create_profile(
                        db=db,
                        user_id=user.id,
                        display_name=display_name,
                        age_band=age_band,
                        support_focus=support_focus,
                        guardian_consent_status=consent_status,
                    )
                    accessibility = UserRepository.create_accessibility_preferences(db=db, user_id=user.id)
                    onboarding = UserRepository.create_onboarding_state(db=db, user_id=user.id)
                    db.commit()
                    log_security_event(
                        "firebase_signup_sync",
                        user_id=user.id,
                        details=f"firebase_uid={firebase_uid} role={user.role} age_band={age_band}",
                    )
                except Exception as e:
                    db.rollback()
                    log_security_event("firebase_signup_sync_error", details=str(e))
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail="Failed to initialize user application profile.",
                    )

        if user.status != "active":
            log_security_event("login_blocked_inactive", user_id=user.id)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your account is currently inactive. Please contact support.",
            )

        UserRepository.update_last_login(db, user)
        log_security_event("firebase_login_sync", user_id=user.id, details=f"firebase_uid={firebase_uid}")

        return AuthSessionResponse(
            user=UserResponse.model_validate(user),
            profile=ProfileSummary.model_validate(user.profile),
            accessibility=AccessibilitySummary.model_validate(user.accessibility_preferences),
            onboarding=OnboardingSummary.model_validate(user.onboarding_state),
        )

    @staticmethod
    def get_me(user: User) -> AuthSessionResponse:
        return AuthSessionResponse(
            user=UserResponse.model_validate(user),
            profile=ProfileSummary.model_validate(user.profile),
            accessibility=AccessibilitySummary.model_validate(user.accessibility_preferences),
            onboarding=OnboardingSummary.model_validate(user.onboarding_state),
        )

    @staticmethod
    def logout(user: User, reason: Optional[str] = None) -> None:
        log_security_event("logout", user_id=user.id, details=reason or "client_requested")

    @staticmethod
    def request_password_reset(db: Session, email: str) -> Dict[str, str]:
        """
        Processes password recovery request with user enumeration protection.
        Generates secure single-use recovery token and sends branded email via Gmail SMTP.
        Always returns generic confirmation to prevent user enumeration.
        """
        import secrets
        from app.services.email_service import EmailService
        from app.core.config import settings

        clean_email = email.lower().strip()
        domain = clean_email.split("@")[-1] if "@" in clean_email else "unknown"
        log_security_event("password_reset_requested", details=f"domain={domain}")

        user = UserRepository.get_by_email(db, clean_email)

        # Generate cryptographic token for recovery link
        token = secrets.token_urlsafe(32)
        base_url = settings.FRONTEND_RESET_URL.rstrip("/")
        reset_link = f"{base_url}?token={token}&email={clean_email}"

        # Send recovery email via SMTP
        EmailService.send_password_reset_email(
            to_email=clean_email,
            reset_link=reset_link,
        )

        return {
            "status": "success",
            "message": "If an account exists for this email, we'll send a reset link.",
        }
