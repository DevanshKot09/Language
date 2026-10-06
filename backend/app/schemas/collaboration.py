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


class SpecialistConversationResponse(BaseModel):
    id: str
    conversation_type: str = "group"  # "group" or "direct"
    category: str = "teams"  # "teams" or "learners"
    title: str
    subtitle: str
    roles: List[str] = []
    last_message_sender: Optional[str] = None
    last_message_text: str
    last_message_time: str
    unread_count: int = 0
    is_pinned: bool = False
    is_online: bool = False
    consent_status: str = "verified"
    is_locked: bool = False
    lock_reason: Optional[str] = None
    target_learner_id: Optional[str] = None
    target_learner_name: Optional[str] = None
    avatar_type: str = "single"  # "dual", "team_teal", "parent_online", "locked_child", "teacher_book"
    avatar_badge: Optional[str] = None
    participant_names: List[str] = []

    model_config = ConfigDict(from_attributes=True)


class ChatMessageAttachmentResponse(BaseModel):
    id: str
    filename: str
    file_size_label: str
    file_type: str = "pdf"
    category_label: str = "Guided Practice"
    download_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ChatMessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    sender_name: str
    sender_role: str
    sender_role_label: Optional[str] = None
    avatar_url: Optional[str] = None
    avatar_initials: Optional[str] = None
    content: str
    timestamp: str
    date_group: str = "Today"
    is_self: bool = False
    delivery_status: str = "delivered"
    attachment: Optional[ChatMessageAttachmentResponse] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ChatMessageCreateRequest(BaseModel):
    content: str
    attachment_id: Optional[str] = None


class SpecialistSessionSummaryRequest(BaseModel):
    session_id: Optional[str] = None
    learner_id: str
    learner_name: str
    learner_age_band: Optional[str] = "Child • 10 yrs"
    session_date: Optional[str] = "Today, Oct 17"
    session_time: Optional[str] = "10:30 – 11:02 AM"
    session_duration_minutes: Optional[int] = 31
    session_type: Optional[str] = "1-to-1 Live Support"
    target_focus: Optional[str] = "/r/ Blends"
    cards_completed: Optional[int] = 8
    pacing_rhythm_percentage: Optional[int] = 88
    audio_reflections_count: Optional[int] = 1
    working_areas: List[str] = []
    notes: str = Field(..., min_length=1, description="Session observations & notes entered by Specialist")
    outcome: str = Field(..., description="great_progress, good_progress, steady_practice, needs_support")
    next_practice_focus: Optional[str] = None
    follow_up_actions: List[str] = []
    next_scheduled_session: Optional[str] = None


class SpecialistSessionSummaryResponse(BaseModel):
    id: str
    session_id: Optional[str] = None
    creator_id: str
    creator_name: Optional[str] = None
    learner_id: str
    learner_name: str
    learner_age_band: Optional[str] = None
    session_date: str
    session_time: Optional[str] = None
    session_duration_minutes: int
    session_type: str
    target_focus: str
    cards_completed: int
    pacing_rhythm_percentage: int
    audio_reflections_count: int
    working_areas: List[str]
    notes: str
    outcome: str
    next_practice_focus: Optional[str] = None
    follow_up_actions: List[str] = []
    next_scheduled_session: Optional[str] = None
    status: str = "completed"
    created_at: datetime
    disclaimer: str

    model_config = ConfigDict(from_attributes=True)


class SpecialistProfileResponse(BaseModel):
    id: str
    display_name: str = "Maya Reynolds, M.S."
    professional_title: str = "Learning Support Specialist (CCC-SLP)"
    is_verified: bool = True
    verification_badge: str = "VERIFIED SPECIALIST • LINGUA SAFE"
    location: str = "San Francisco, CA"
    availability_spots: int = 3
    active_learners_count: int = 8
    rating: float = 4.9
    reviews_count: int = 42
    experience_years: int = 5
    profile_visibility: str = "Parents & Learners"  # "Parents & Learners", "Directory Only", "Private"
    about_me: str = "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading..."
    full_bio: str = (
        "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic "
        "awareness, speech pacing, and reading fluency. With over 8 years of clinical and "
        "educational practice, I specialize in pediatric speech scaffolding, multi-sensory "
        "phonics exercises, and cross-collaborative support between families and classroom educators."
    )
    support_focus_areas: List[str] = [
        "Reading Fluency",
        "Speech & Pacing",
        "Phonics & Spelling",
        "Vocabulary Growth",
        "Story Expression",
        "Active Listening",
        "Tactile Game Play",
    ]
    practice_details: Dict[str, str] = {
        "experience": "8+ Years Pediatric Practice",
        "languages": "English (Native), Spanish (Conversational)",
        "age_groups": "Preschool (3–5), Elementary (6–10), Teens (11–16)",
        "supported_formats": "1-on-1 Interactive Audio & Video, Asynchronous Practice Reviews",
    }
    credentials: List[Dict[str, str]] = [
        {
            "title": "M.S. in Speech & Hearing Sciences",
            "subtitle": "University of Washington • Verified",
            "type": "degree",
        },
        {
            "title": "Clinical Competence Certificate (CCC-SLP)",
            "subtitle": "Active National Standing • Current",
            "type": "license",
        },
        {
            "title": "Lingua AI Child-Safe & HIPAA Verified",
            "subtitle": "Annual Review Complete • 2024",
            "type": "safety",
        },
    ]
    disclaimer: str = "Lingua AI provides developmental learning facilitation and educational practice."
    privacy_reassurance: str = (
        "Only details you approve are shared with families. Protected by the Lingua AI Child-Safe Guarantee."
    )

    model_config = ConfigDict(from_attributes=True)


class SpecialistProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    professional_title: Optional[str] = None
    location: Optional[str] = None
    availability_spots: Optional[int] = None
    profile_visibility: Optional[str] = None
    about_me: Optional[str] = None
    full_bio: Optional[str] = None
    support_focus_areas: Optional[List[str]] = None


class SpecialistNotificationItem(BaseModel):
    id: str
    title: str
    supporting_text: str
    timestamp: str
    time_group: str = "Today"  # "Today", "Yesterday & Earlier"
    category: str = "sessions"  # "all", "sessions", "learners", "messages", "team"
    badge_label: Optional[str] = None
    badge_type: Optional[str] = None  # "interactive_audio", "consent_logged", "classroom_synergy", "neutral"
    is_read: bool = False
    action_type: Optional[str] = None  # "join_session", "review_details", "open_chat", "view_deck", "manage_schedule"
    action_label: Optional[str] = None
    target_id: Optional[str] = None
    icon_type: str = "video"  # "video", "shield", "chat", "analytics", "calendar"

    model_config = ConfigDict(from_attributes=True)


class SpecialistNotificationsResponse(BaseModel):
    notifications: List[SpecialistNotificationItem] = []
    unread_count: int = 0
    today_count: int = 0
    filter: str = "all"


class CircleMember(BaseModel):
    name: str
    role_label: str  # "(Guardian)", "(Teacher)", "(Specialist)", "(Learner / Self)"
    initial: str
    is_specialist: bool = False


class PermissionScopeItem(BaseModel):
    key: str
    title: str
    is_shared: bool = True
    status_label: str = "Shared"  # "Shared", "Not Shared", "Learner Private"
    icon_type: str = "mic"  # "mic", "trend", "chat", "puzzle", "mic_off", "book"


class SpecialistConsentCircle(BaseModel):
    id: str
    learner_id: str
    learner_name: str
    learner_initials: str
    status: str = "active"  # "active", "limited", "pending", "revoked"
    status_label: str = "Active"  # "✓ Active", "⇄ Limited"
    subtitle: str = "Learner • 10 yrs • Grade 4"
    collaboration_circle: List[CircleMember] = []
    permission_scopes: List[PermissionScopeItem] = []
    consent_reconfirmed_date: Optional[str] = None
    updated_time_ago: Optional[str] = None
    avatar_color: str = "purple"  # "purple", "amber"

    model_config = ConfigDict(from_attributes=True)


class SpecialistConsentCirclesResponse(BaseModel):
    circles: List[SpecialistConsentCircle] = []
    active_count: int = 2
    privacy_notice: str = (
        "Learner privacy is our priority. Guardians or adult learners can pause, "
        "reconfigure, or withdraw specialization scopes at any time directly through their profile."
    )


# ---------------------------------------------------------------------------
# Availability & Appointment Settings Schemas
# ---------------------------------------------------------------------------
class SpecialistTimeSlot(BaseModel):
    id: str
    time_range: str
    icon_type: str = "sun"  # "sun", "sparkle"

    model_config = ConfigDict(from_attributes=True)


class SpecialistDayAvailability(BaseModel):
    day_key: str
    day_label: str
    initial: str
    is_enabled: bool = True
    subtitle: str
    slots: List[SpecialistTimeSlot] = []

    model_config = ConfigDict(from_attributes=True)


class SpecialistAvailabilityResponse(BaseModel):
    specialist_name: str = "Dr. Maya Lin, M.S. CCC-SLP"
    specialist_title: str = "Pediatric Speech & Phoneme Coaching"
    specialist_badge: str = "LINGUA SPECIALIST • Active Caseload"
    available_for_sessions: bool = True
    timezone: str = "Pacific Time (GMT-7)"
    days: List[SpecialistDayAvailability] = []
    session_duration_minutes: int = 45
    buffer_minutes: int = 15
    daily_session_cap: int = 5
    advance_notice: str = "24h Notice"

    model_config = ConfigDict(from_attributes=True)


class SpecialistAvailabilityUpdateRequest(BaseModel):
    available_for_sessions: Optional[bool] = None
    timezone: Optional[str] = None
    days: Optional[List[SpecialistDayAvailability]] = None
    session_duration_minutes: Optional[int] = None
    buffer_minutes: Optional[int] = None
    daily_session_cap: Optional[int] = None
    advance_notice: Optional[str] = None


# ---------------------------------------------------------------------------
# Specialist Verification Status Schemas
# ---------------------------------------------------------------------------
class SpecialistMilestoneItem(BaseModel):
    key: str
    label: str
    is_completed: bool = True
    is_current: bool = False

    model_config = ConfigDict(from_attributes=True)


class SpecialistVerifiedDocument(BaseModel):
    id: str
    title: str
    subtitle: str
    status_label: str = "Approved"
    icon_type: str = "grad_cap"  # "grad_cap", "certificate", "shield"
    is_approved: bool = True

    model_config = ConfigDict(from_attributes=True)


class SpecialistVerificationResponse(BaseModel):
    verification_status: str = "verified"  # "verified", "pending", "action_required"
    status_badge: str = "PROFILE VERIFIED"
    headline: str = "Your profile is verified"
    description: str = (
        "Your specialist credentials and child-safety background checks are confirmed. "
        "Families and schools can discover your profile and book sessions."
    )
    verification_date_text: str = "Verified Oct 14, 2024 • Next check: Oct 2025"
    milestones_completed: int = 5
    milestones_total: int = 5
    milestones: List[SpecialistMilestoneItem] = []
    specialist_name: str = "Maya Reynolds, M.S."
    specialist_initials: str = "MR"
    specialist_role_subtitle: str = "Learning Support Specialist (CCC-SLP)"
    experience_text: str = "8+ Yrs Pediatric"
    languages_text: str = "English, Spanish"
    approved_domains: List[str] = [
        "Reading Fluency",
        "Speech & Pacing",
        "Phonics & Spelling",
        "Vocabulary Growth",
    ]
    verified_documents: List[SpecialistVerifiedDocument] = []
    compliance_notice: str = "Encrypted • FERPA Compliant"

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Specialist Help & Support Schemas
# ---------------------------------------------------------------------------
class HelpCategoryItem(BaseModel):
    id: str
    title: str
    subtitle: str
    icon_type: str  # "person", "video", "grad_cap", "chat", "shield", "badge", "clock", "bell"
    color: str = "purple"  # "purple", "teal", "amber", "mint", "lilac"

    model_config = ConfigDict(from_attributes=True)


class FaqItem(BaseModel):
    id: str
    question: str
    answer: str

    model_config = ConfigDict(from_attributes=True)


class SpecialistHelpResponse(BaseModel):
    categories: List[HelpCategoryItem] = []
    faqs: List[FaqItem] = []
    support_desk_hours: str = "Mon–Fri, 8 AM–8 PM EST"
    avg_response_time: str = "< 15 mins during desk hours"
    system_status: str = "All Systems Operational"
    app_version: str = "Lingua Specialist v2.4.1 (Build 842)"

    model_config = ConfigDict(from_attributes=True)


class ReportProblemRequest(BaseModel):
    category: str
    description: str
    device_info: Optional[str] = None


# ---------------------------------------------------------------------------
# Specialist Settings Schemas (Stitch Settings Reference)
# ---------------------------------------------------------------------------
class SpecialistSettingsResponse(BaseModel):
    specialist_name: str = "Maya Reynolds, M.S."
    specialist_title: str = "Learning Support Specialist (CCC-SLP)"
    is_verified: bool = True
    verification_badge: str = "Profile Verified"
    active_learners_count: int = 18

    # Live Notifications
    session_reminders: bool = True
    consent_alerts: bool = True
    messages_alerts: bool = True
    appointment_requests: bool = True
    weekly_progress_digests: bool = False

    # Child Safety & Consent
    profile_visibility: str = "Public"
    data_privacy_level: str = "COPPA-Compliant"

    # Accessibility & Comfort
    larger_text: bool = False
    reduce_motion: bool = False
    high_contrast: bool = False
    haptic_feedback: bool = True

    # Specialist Studio
    language: str = "English (US)"
    appearance_theme: str = "Light (Playful)"
    time_zone: str = "Pacific Time (GMT-7)"
    audio_sound_fx: bool = True

    model_config = ConfigDict(from_attributes=True)


class SpecialistSettingsUpdateRequest(BaseModel):
    session_reminders: Optional[bool] = None
    consent_alerts: Optional[bool] = None
    messages_alerts: Optional[bool] = None
    appointment_requests: Optional[bool] = None
    weekly_progress_digests: Optional[bool] = None
    profile_visibility: Optional[str] = None
    larger_text: Optional[bool] = None
    reduce_motion: Optional[bool] = None
    high_contrast: Optional[bool] = None
    haptic_feedback: Optional[bool] = None
    language: Optional[str] = None
    appearance_theme: Optional[str] = None
    time_zone: Optional[str] = None
    audio_sound_fx: Optional[bool] = None


