import json
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.collaboration import Relationship, RelationshipInvitation
from app.schemas.collaboration import (
    RelationshipResponse,
    CreateInvitationRequest,
    InvitationResponse,
    AuditAccessEventResponse,
)
from app.services.collaboration_service import CollaborationService

router = APIRouter()


@router.get("", response_model=List[RelationshipResponse])
async def list_relationships(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List relationships connected to the authenticated user.
    If actor role (parent, teacher, specialist), returns target learners.
    If learner role, returns connected support team.
    """
    service = CollaborationService(db)
    if current_user.role == "learner":
        rels = service.repo.list_learner_relationships(current_user.id)
    else:
        rels = service.repo.list_actor_relationships(current_user.id, status="all")

    response = []
    for r in rels:
        target = db.query(User).filter(User.id == r.target_user_id).first()
        target_prof = target.profile if target else None
        scopes = json.loads(r.permission_scope) if r.permission_scope else []
        response.append(
            RelationshipResponse(
                id=r.id,
                source_user_id=r.source_user_id,
                target_user_id=r.target_user_id,
                relationship_type=r.relationship_type,
                status=r.status,
                permission_scope=scopes,
                consent_status=r.consent_status,
                organization=r.organization,
                target_learner_name=target_prof.display_name if target_prof else "Learner",
                target_learner_email=target.email if target else None,
                target_learner_age_band=target_prof.age_band if target_prof else None,
                target_learner_support_focus=target_prof.support_focus if target_prof else None,
                created_at=r.created_at,
                updated_at=r.updated_at,
                expires_at=r.expires_at,
                revoked_at=r.revoked_at,
            )
        )
    return response


@router.post("/invitations", response_model=InvitationResponse, status_code=status.HTTP_201_CREATED)
async def create_invitation(
    request: CreateInvitationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Generate a secure, single-use, time-limited invitation token.
    Enforces inviter authority and data privacy.
    """
    service = CollaborationService(db)
    invitation = service.create_invitation(
        inviter=current_user,
        invitee_email=request.invitee_email,
        relationship_type=request.relationship_type,
        target_learner_id=request.target_learner_id,
        permission_scope=request.permission_scope,
    )
    inviter_prof = current_user.profile
    scopes = json.loads(invitation.permission_scope) if invitation.permission_scope else []

    return InvitationResponse(
        id=invitation.id,
        invitation_token=getattr(invitation, "_raw_token", invitation.invitation_token),
        inviter_id=invitation.inviter_id,
        inviter_name=inviter_prof.display_name if inviter_prof else "Collaborator",
        invitee_email=invitation.invitee_email,
        target_learner_id=invitation.target_learner_id,
        relationship_type=invitation.relationship_type,
        permission_scope=scopes,
        status=invitation.status,
        expires_at=invitation.expires_at,
        created_at=invitation.created_at,
        accepted_at=invitation.accepted_at,
    )


@router.get("/invitations", response_model=List[InvitationResponse])
async def list_invitations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lists invitations sent by or addressed to the current user.
    """
    service = CollaborationService(db)
    sent = service.repo.list_invitations_by_inviter(current_user.id)
    received = service.repo.list_invitations_for_email(current_user.email)
    combined = {i.id: i for i in (sent + received)}.values()

    result = []
    for inv in combined:
        inviter = db.query(User).filter(User.id == inv.inviter_id).first()
        inv_prof = inviter.profile if inviter else None
        scopes = json.loads(inv.permission_scope) if inv.permission_scope else []
        result.append(
            InvitationResponse(
                id=inv.id,
                invitation_token=inv.invitation_token,
                inviter_id=inv.inviter_id,
                inviter_name=inv_prof.display_name if inv_prof else "Collaborator",
                invitee_email=inv.invitee_email,
                target_learner_id=inv.target_learner_id,
                relationship_type=inv.relationship_type,
                permission_scope=scopes,
                status=inv.status,
                expires_at=inv.expires_at,
                created_at=inv.created_at,
                accepted_at=inv.accepted_at,
            )
        )
    return result


@router.post("/invitations/accept", response_model=RelationshipResponse)
async def accept_invitation(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Accept an invitation using its non-guessable token. Activates relationship.
    """
    service = CollaborationService(db)
    rel = service.accept_invitation(token, current_user)
    target = db.query(User).filter(User.id == rel.target_user_id).first()
    target_prof = target.profile if target else None
    scopes = json.loads(rel.permission_scope) if rel.permission_scope else []

    return RelationshipResponse(
        id=rel.id,
        source_user_id=rel.source_user_id,
        target_user_id=rel.target_user_id,
        relationship_type=rel.relationship_type,
        status=rel.status,
        permission_scope=scopes,
        consent_status=rel.consent_status,
        organization=rel.organization,
        target_learner_name=target_prof.display_name if target_prof else "Learner",
        target_learner_email=target.email if target else None,
        target_learner_age_band=target_prof.age_band if target_prof else None,
        target_learner_support_focus=target_prof.support_focus if target_prof else None,
        created_at=rel.created_at,
        updated_at=rel.updated_at,
        expires_at=rel.expires_at,
        revoked_at=rel.revoked_at,
    )


@router.post("/invitations/reject")
async def reject_invitation(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Reject an invitation using its token.
    """
    service = CollaborationService(db)
    inv = service.reject_invitation(token, current_user)
    return {"message": "Invitation rejected.", "status": inv.status}


@router.delete("/{relationship_id}")
async def revoke_relationship(
    relationship_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Immediately revoke an active relationship. Subsequent cross-user requests return 403.
    """
    service = CollaborationService(db)
    rel = service.revoke_relationship(relationship_id, current_user)
    return {
        "message": "Relationship revoked successfully.",
        "relationship_id": rel.id,
        "status": rel.status,
        "revoked_at": rel.revoked_at,
    }


@router.get("/audit", response_model=List[AuditAccessEventResponse])
async def list_audit_events(
    learner_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns audit log of access events for current user or authorized learner.
    """
    service = CollaborationService(db)
    target_id = learner_id or current_user.id
    if target_id != current_user.id:
        service.verify_relationship_access(current_user, target_id)

    events = service.repo.list_access_events_for_learner(target_id)
    return [
        AuditAccessEventResponse(
            id=e.id,
            user_id=e.user_id,
            action=e.action,
            target_user_id=e.target_user_id,
            resource_type=e.resource_type,
            resource_id=e.resource_id,
            details=e.details,
            created_at=e.created_at,
        )
        for e in events
    ]
