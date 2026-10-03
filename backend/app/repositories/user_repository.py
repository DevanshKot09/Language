from datetime import datetime, timezone
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.profile import Profile
from app.models.accessibility import AccessibilityPreferences
from app.models.onboarding import OnboardingState


class UserRepository:
    @staticmethod
    def get_by_id(db: Session, user_id: str) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_by_firebase_uid(db: Session, firebase_uid: str) -> Optional[User]:
        return db.query(User).filter(User.firebase_uid == firebase_uid).first()

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        return db.query(User).filter(User.email == email.lower().strip()).first()

    @staticmethod
    def create_user(
        db: Session,
        firebase_uid: str,
        email: str,
        role: str = "learner",
        status: str = "active",
    ) -> User:
        user = User(
            firebase_uid=firebase_uid,
            email=email.lower().strip(),
            role=role,
            status=status,
        )
        db.add(user)
        db.flush()
        return user

    @staticmethod
    def update_last_login(db: Session, user: User) -> None:
        user.last_login_at = datetime.now(timezone.utc)
        db.add(user)
        db.commit()

    @staticmethod
    def create_profile(
        db: Session,
        user_id: str,
        display_name: str,
        age_band: str = "teen",
        support_focus: str = "dld_track",
        guardian_consent_status: str = "not_required",
    ) -> Profile:
        profile = Profile(
            user_id=user_id,
            display_name=display_name,
            age_band=age_band,
            support_focus=support_focus,
            guardian_consent_status=guardian_consent_status,
        )
        db.add(profile)
        db.flush()
        return profile

    @staticmethod
    def create_accessibility_preferences(db: Session, user_id: str) -> AccessibilityPreferences:
        prefs = AccessibilityPreferences(user_id=user_id)
        db.add(prefs)
        db.flush()
        return prefs

    @staticmethod
    def create_onboarding_state(db: Session, user_id: str) -> OnboardingState:
        state = OnboardingState(user_id=user_id)
        db.add(state)
        db.flush()
        return state

    @staticmethod
    def update_profile(db: Session, profile: Profile, updates: Dict[str, Any]) -> Profile:
        for key, value in updates.items():
            if value is not None and hasattr(profile, key):
                setattr(profile, key, value)
        profile.updated_at = datetime.now(timezone.utc)
        db.add(profile)
        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def update_onboarding_state(db: Session, onboarding: OnboardingState, updates: Dict[str, Any]) -> OnboardingState:
        for key, value in updates.items():
            if value is not None and hasattr(onboarding, key):
                setattr(onboarding, key, value)
        if updates.get("is_completed") is True and onboarding.completed_at is None:
            onboarding.completed_at = datetime.now(timezone.utc)
        onboarding.updated_at = datetime.now(timezone.utc)
        db.add(onboarding)
        db.commit()
        db.refresh(onboarding)
        return onboarding

    @staticmethod
    def update_accessibility_preferences(
        db: Session,
        prefs: AccessibilityPreferences,
        updates: Dict[str, Any],
    ) -> AccessibilityPreferences:
        for key, value in updates.items():
            if value is not None and hasattr(prefs, key):
                setattr(prefs, key, value)
        prefs.updated_at = datetime.now(timezone.utc)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)
        return prefs
