from typing import List, Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.firebase import verify_firebase_id_token
from app.core.security import log_security_event
from app.models.user import User
from app.repositories.user_repository import UserRepository

security_scheme = HTTPBearer(auto_error=False)


async def get_firebase_claims(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
) -> Dict[str, Any]:
    """
    Extracts and verifies the Firebase ID Token from the Authorization: Bearer header.
    Validates signature, expiration, issuer project, and authenticity using Firebase Admin SDK.
    Never trusts client-provided identity claims.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please provide a valid Firebase ID Token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        claims = verify_firebase_id_token(token)
    except Exception as e:
        log_security_event("firebase_token_verification_failed", details=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your authentication session is invalid or expired. Please sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    uid = claims.get("uid")
    if not uid:
        log_security_event("firebase_token_missing_uid")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token payload.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return claims


async def get_current_user(
    claims: Dict[str, Any] = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
) -> User:
    """
    Resolves the canonical application User in Supabase PostgreSQL using the verified Firebase UID.
    """
    firebase_uid = claims["uid"]
    user = UserRepository.get_by_firebase_uid(db, firebase_uid)

    if not user:
        # Verified Firebase account exists, but local profile record is missing.
        # Auto-provision to heal session and guarantee seamless cross-device continuity.
        from app.services.auth_service import AuthService
        try:
            AuthService.sync_firebase_user(db=db, claims=claims)
            user = UserRepository.get_by_firebase_uid(db, firebase_uid)
        except Exception as e:
            log_security_event("user_auto_provision_failed", details=str(e))

    if not user:
        log_security_event("user_record_not_found", details=f"firebase_uid={firebase_uid}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Application profile not found for this authenticated user. Please complete registration.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if user.status != "active":
        log_security_event("inactive_user_access_blocked", user_id=user.id)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is suspended or inactive.",
        )

    return user


def require_role(allowed_roles: List[str]):
    """
    Factory dependency enforcing role-based access control (RBAC).
    Enforces authoritative server-side role from Supabase database.
    Never trusts client role claims.
    """
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            log_security_event(
                "authorization_failure",
                user_id=current_user.id,
                details=f"user_role={current_user.role} required={allowed_roles}",
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this resource.",
            )
        return current_user

    return role_checker
