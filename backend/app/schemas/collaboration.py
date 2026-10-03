from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class RelationshipResponse(BaseModel):
    id: str
    source_user_id: str
    target_user_id: str
    relationship_type: str
    status: str
    permission_scope: List[str]
    consent_status: str
    organization: Optional[str] = None
    target_learner_name: Optional[str] = None
    target_learner_email: Optional[str] = None
    target_learner_age_band: Optional[str] = None
    target_learner_support_focus: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    expires_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class CreateInvitationRequest(BaseModel):
    invitee_email: str = Field(..., description="Email address of the invitee")
    relationship_type: str = Field(..., description="'parent', 'teacher', or 'specialist'")
    target_learner_id: Optional[str] = None
    organization: Optional[str] = None
    permission_scope: Optional[List[str]] = None


class InvitationResponse(BaseModel):
    id: str
    invitation_token: str
    inviter_id: str
    inviter_name: Optional[str] = None
    invitee_email: str
    target_learner_id: Optional[str] = None
    relationship_type: str
    permission_scope: List[str]
    status: str
    expires_at: datetime
    created_at: datetime
    accepted_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class AssignmentCreateRequest(BaseModel):
    student_id: str
    lesson_id: str
    title: str = Field(..., max_length=255)
    instructions: Optional[str] = None
    due_at: Optional[datetime] = None


class AssignmentResponse(BaseModel):
    id: str
    teacher_id: str
    teacher_name: Optional[str] = None
    student_id: str
    student_name: Optional[str] = None
    lesson_id: str
    lesson_title: Optional[str] = None
    title: str
    instructions: Optional[str] = None
    status: str
    due_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ReportCreateRequest(BaseModel):
    learner_id: str
    report_type: str = Field(..., description="'parent_summary', 'teacher_summary', or 'specialist_summary'")
    title: Optional[str] = None


class ReportResponse(BaseModel):
    id: str
    creator_id: str
    creator_name: Optional[str] = None
    learner_id: str
    learner_name: Optional[str] = None
    report_type: str
    title: str
    summary_data: Dict[str, Any]
    disclaimer: str
    status: str
    created_at: datetime
    expires_at: Optional[datetime] = None
    pdf_download_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SpecialistAiReviewRequest(BaseModel):
    human_status: str = Field(..., description="'approved', 'modified', or 'rejected'")
    modified_reason: Optional[str] = None
    modified_lesson_id: Optional[str] = None


class AuditAccessEventResponse(BaseModel):
    id: str
    user_id: str
    action: str
    target_user_id: Optional[str] = None
    resource_type: str
    resource_id: Optional[str] = None
    details: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
