import 'package:flutter/foundation.dart';

@immutable
class RelationshipItem {
  final String id;
  final String sourceUserId;
  final String targetUserId;
  final String relationshipType; // parent, teacher, specialist
  final String status; // active, pending, rejected, revoked, expired
  final List<String> permissionScope;
  final String consentStatus;
  final String? organization;
  final String targetLearnerName;
  final String? targetLearnerEmail;
  final String? targetLearnerAgeBand;
  final String? targetLearnerSupportFocus;
  final DateTime createdAt;

  const RelationshipItem({
    required this.id,
    required this.sourceUserId,
    required this.targetUserId,
    required this.relationshipType,
    required this.status,
    required this.permissionScope,
    required this.consentStatus,
    this.organization,
    required this.targetLearnerName,
    this.targetLearnerEmail,
    this.targetLearnerAgeBand,
    this.targetLearnerSupportFocus,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRevoked => status == 'revoked';

  factory RelationshipItem.fromJson(Map<String, dynamic> json) {
    return RelationshipItem(
      id: json['id'] as String? ?? '',
      sourceUserId: json['source_user_id'] as String? ?? '',
      targetUserId: json['target_user_id'] as String? ?? '',
      relationshipType: json['relationship_type'] as String? ?? 'parent',
      status: json['status'] as String? ?? 'active',
      permissionScope: (json['permission_scope'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      consentStatus: json['consent_status'] as String? ?? 'verified',
      organization: json['organization'] as String?,
      targetLearnerName: json['target_learner_name'] as String? ?? 'Learner',
      targetLearnerEmail: json['target_learner_email'] as String?,
      targetLearnerAgeBand: json['target_learner_age_band'] as String?,
      targetLearnerSupportFocus: json['target_learner_support_focus'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class InvitationItem {
  final String id;
  final String invitationToken;
  final String inviterId;
  final String inviterName;
  final String inviteeEmail;
  final String? targetLearnerId;
  final String relationshipType;
  final List<String> permissionScope;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const InvitationItem({
    required this.id,
    required this.invitationToken,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeEmail,
    this.targetLearnerId,
    required this.relationshipType,
    required this.permissionScope,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory InvitationItem.fromJson(Map<String, dynamic> json) {
    return InvitationItem(
      id: json['id'] as String? ?? '',
      invitationToken: json['invitation_token'] as String? ?? '',
      inviterId: json['inviter_id'] as String? ?? '',
      inviterName: json['inviter_name'] as String? ?? 'Collaborator',
      inviteeEmail: json['invitee_email'] as String? ?? '',
      targetLearnerId: json['target_learner_id'] as String?,
      relationshipType: json['relationship_type'] as String? ?? 'parent',
      permissionScope: (json['permission_scope'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'pending',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class AssignmentItem {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String lessonId;
  final String lessonTitle;
  final String title;
  final String? instructions;
  final String status; // assigned, in_progress, completed, overdue
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const AssignmentItem({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.lessonId,
    required this.lessonTitle,
    required this.title,
    this.instructions,
    required this.status,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'assigned';

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? 'Teacher',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? 'Student',
      lessonId: json['lesson_id'] as String? ?? '',
      lessonTitle: json['lesson_title'] as String? ?? 'Lesson',
      title: json['title'] as String? ?? 'Assignment',
      instructions: json['instructions'] as String?,
      status: json['status'] as String? ?? 'assigned',
      dueAt: json['due_at'] != null ? DateTime.tryParse(json['due_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class ReportItem {
  final String id;
  final String creatorId;
  final String creatorName;
  final String learnerId;
  final String learnerName;
  final String reportType; // parent_summary, teacher_summary, specialist_summary
  final String title;
  final Map<String, dynamic> summaryData;
  final String disclaimer;
  final String status;
  final DateTime createdAt;
  final String? pdfDownloadUrl;

  const ReportItem({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.learnerId,
    required this.learnerName,
    required this.reportType,
    required this.title,
    required this.summaryData,
    required this.disclaimer,
    required this.status,
    required this.createdAt,
    this.pdfDownloadUrl,
  });

  bool get isReady => status == 'ready';

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      creatorName: json['creator_name'] as String? ?? 'Creator',
      learnerId: json['learner_id'] as String? ?? '',
      learnerName: json['learner_name'] as String? ?? 'Learner',
      reportType: json['report_type'] as String? ?? 'parent_summary',
      title: json['title'] as String? ?? 'Learning Report',
      summaryData: (json['summary_data'] as Map<String, dynamic>?) ?? const {},
      disclaimer: json['disclaimer'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pdfDownloadUrl: json['pdf_download_url'] as String?,
    );
  }
}

@immutable
class ParentChildItem {
  final String relationshipId;
  final String learnerId;
  final String displayName;
  final String ageBand;
  final String supportFocus;
  final String guardianConsentStatus;
  final String status;
  final List<String> permissionScope;

  const ParentChildItem({
    required this.relationshipId,
    required this.learnerId,
    required this.displayName,
    required this.ageBand,
    required this.supportFocus,
    required this.guardianConsentStatus,
    required this.status,
    required this.permissionScope,
  });

  factory ParentChildItem.fromJson(Map<String, dynamic> json) {
    return ParentChildItem(
      relationshipId: json['relationship_id'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Learner',
      ageBand: json['age_band'] as String? ?? 'teen',
      supportFocus: json['support_focus'] as String? ?? 'dld_track',
      guardianConsentStatus: json['guardian_consent_status'] as String? ?? 'verified',
      status: json['status'] as String? ?? 'active',
      permissionScope: (json['permission_scope'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

@immutable
class TeacherStudentItem {
  final String relationshipId;
  final String studentId;
  final String displayName;
  final String ageBand;
  final String supportFocus;
  final int assignmentsTotal;
  final int assignmentsCompleted;
  final String status;

  const TeacherStudentItem({
    required this.relationshipId,
    required this.studentId,
    required this.displayName,
    required this.ageBand,
    required this.supportFocus,
    required this.assignmentsTotal,
    required this.assignmentsCompleted,
    required this.status,
  });

  factory TeacherStudentItem.fromJson(Map<String, dynamic> json) {
    return TeacherStudentItem(
      relationshipId: json['relationship_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Student',
      ageBand: json['age_band'] as String? ?? 'teen',
      supportFocus: json['support_focus'] as String? ?? 'dld_track',
      assignmentsTotal: (json['assignments_total'] as num?)?.toInt() ?? 0,
      assignmentsCompleted: (json['assignments_completed'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

@immutable
class SpecialistCaseloadItem {
  final String relationshipId;
  final String learnerId;
  final String displayName;
  final String ageBand;
  final String supportFocus;
  final String baselineStatus;
  final int pendingAiRecommendations;
  final String? organization;
  final String status;

  const SpecialistCaseloadItem({
    required this.relationshipId,
    required this.learnerId,
    required this.displayName,
    required this.ageBand,
    required this.supportFocus,
    required this.baselineStatus,
    required this.pendingAiRecommendations,
    this.organization,
    required this.status,
  });

  factory SpecialistCaseloadItem.fromJson(Map<String, dynamic> json) {
    return SpecialistCaseloadItem(
      relationshipId: json['relationship_id'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Learner',
      ageBand: json['age_band'] as String? ?? 'teen',
      supportFocus: json['support_focus'] as String? ?? 'dld_track',
      baselineStatus: json['baseline_status'] as String? ?? 'not_started',
      pendingAiRecommendations: (json['pending_ai_recommendations'] as num?)?.toInt() ?? 0,
      organization: json['organization'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

/// Status of a scheduled specialist support session.
enum ScheduleSessionStatus { upcoming, confirmed, completed, cancelled, requestPending }

/// A single support session on the Specialist schedule.
///
/// Parsed from the FastAPI scheduling payload. Only minimum learner
/// identification is carried (name + age band); reports stay in the
/// Learner Profile flow.
@immutable
class SpecialistScheduleSession {
  final String id;
  final String learnerId;
  final String learnerName;
  final String ageBand;
  final String sessionType;
  final String? focus;
  final DateTime startsAt;
  final int durationMinutes;
  final ScheduleSessionStatus status;
  final String? requestedVia;

  const SpecialistScheduleSession({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    required this.ageBand,
    required this.sessionType,
    this.focus,
    required this.startsAt,
    required this.durationMinutes,
    required this.status,
    this.requestedVia,
  });

  static ScheduleSessionStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'completed':
        return ScheduleSessionStatus.completed;
      case 'cancelled':
        return ScheduleSessionStatus.cancelled;
      case 'confirmed':
        return ScheduleSessionStatus.confirmed;
      case 'request_pending':
      case 'pending':
        return ScheduleSessionStatus.requestPending;
      default:
        return ScheduleSessionStatus.upcoming;
    }
  }

  factory SpecialistScheduleSession.fromJson(Map<String, dynamic> json) {
    return SpecialistScheduleSession(
      id: json['id'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      learnerName: json['learner_name'] as String? ?? 'Learner',
      ageBand: json['age_band'] as String? ?? 'child',
      sessionType: json['session_type'] as String? ?? 'Support Session',
      focus: json['focus'] as String?,
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      status: _parseStatus(json['status'] as String?),
      requestedVia: json['requested_via'] as String?,
    );
  }
}

/// Model representing a support/collaboration conversation item
/// for the Specialist Messages & Collaboration screen.
@immutable
class SpecialistConversationItem {
  final String id;
  final String conversationType; // "group" or "direct"
  final String category; // "teams" or "learners"
  final String title;
  final String subtitle;
  final List<String> roles;
  final String? lastMessageSender;
  final String lastMessageText;
  final String lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isOnline;
  final String consentStatus;
  final bool isLocked;
  final String? lockReason;
  final String? targetLearnerId;
  final String? targetLearnerName;
  final String avatarType; // "dual", "team_teal", "parent_online", "locked_child", "teacher_book"
  final String? avatarBadge;
  final List<String> participantNames;

  const SpecialistConversationItem({
    required this.id,
    this.conversationType = 'group',
    this.category = 'teams',
    required this.title,
    required this.subtitle,
    this.roles = const [],
    this.lastMessageSender,
    required this.lastMessageText,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isOnline = false,
    this.consentStatus = 'verified',
    this.isLocked = false,
    this.lockReason,
    this.targetLearnerId,
    this.targetLearnerName,
    this.avatarType = 'single',
    this.avatarBadge,
    this.participantNames = const [],
  });

  bool get hasUnread => unreadCount > 0;
  bool get isTeam => conversationType == 'group' || category == 'teams';

  factory SpecialistConversationItem.fromJson(Map<String, dynamic> json) {
    return SpecialistConversationItem(
      id: json['id'] as String? ?? '',
      conversationType: json['conversation_type'] as String? ?? 'group',
      category: json['category'] as String? ?? 'teams',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lastMessageSender: json['last_message_sender'] as String?,
      lastMessageText: json['last_message_text'] as String? ?? '',
      lastMessageTime: json['last_message_time'] as String? ?? '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      consentStatus: json['consent_status'] as String? ?? 'verified',
      isLocked: json['is_locked'] as bool? ?? false,
      lockReason: json['lock_reason'] as String?,
      targetLearnerId: json['target_learner_id'] as String?,
      targetLearnerName: json['target_learner_name'] as String?,
      avatarType: json['avatar_type'] as String? ?? 'single',
      avatarBadge: json['avatar_badge'] as String?,
      participantNames: (json['participant_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// Represents an educational document or guided practice attachment inside a chat message.
@immutable
class ChatMessageAttachmentItem {
  final String id;
  final String filename;
  final String fileSizeLabel;
  final String fileType; // "pdf", "image", "doc"
  final String categoryLabel; // e.g. "Guided Practice"
  final String? downloadUrl;

  const ChatMessageAttachmentItem({
    required this.id,
    required this.filename,
    required this.fileSizeLabel,
    this.fileType = 'pdf',
    this.categoryLabel = 'Guided Practice',
    this.downloadUrl,
  });

  factory ChatMessageAttachmentItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageAttachmentItem(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      fileSizeLabel: json['file_size_label'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'pdf',
      categoryLabel: json['category_label'] as String? ?? 'Guided Practice',
      downloadUrl: json['download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'file_size_label': fileSizeLabel,
        'file_type': fileType,
        'category_label': categoryLabel,
        'download_url': downloadUrl,
      };
}

/// Represents a message in a support/collaboration thread for the Chat Thread screen.
@immutable
class ChatMessageItem {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole; // "specialist", "parent", "teacher", "learner", "system"
  final String? senderRoleLabel; // e.g. "Parent", "Teacher • Oakridge", "You (Specialist)"
  final String? avatarUrl;
  final String? avatarInitials;
  final String content;
  final String timestamp; // e.g. "10:38 AM"
  final String dateGroup; // "Yesterday", "Today", "Oct 15"
  final bool isSelf;
  final String deliveryStatus; // "sending", "sent", "delivered", "read", "failed"
  final ChatMessageAttachmentItem? attachment;
  final DateTime? createdAt;

  const ChatMessageItem({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.senderRoleLabel,
    this.avatarUrl,
    this.avatarInitials,
    required this.content,
    required this.timestamp,
    this.dateGroup = 'Today',
    this.isSelf = false,
    this.deliveryStatus = 'delivered',
    this.attachment,
    this.createdAt,
  });

  ChatMessageItem copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderRoleLabel,
    String? avatarUrl,
    String? avatarInitials,
    String? content,
    String? timestamp,
    String? dateGroup,
    bool? isSelf,
    String? deliveryStatus,
    ChatMessageAttachmentItem? attachment,
    DateTime? createdAt,
  }) {
    return ChatMessageItem(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderRoleLabel: senderRoleLabel ?? this.senderRoleLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      dateGroup: dateGroup ?? this.dateGroup,
      isSelf: isSelf ?? this.isSelf,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? 'specialist',
      senderRoleLabel: json['sender_role_label'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarInitials: json['avatar_initials'] as String?,
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      dateGroup: json['date_group'] as String? ?? 'Today',
      isSelf: json['is_self'] as bool? ?? false,
      deliveryStatus: json['delivery_status'] as String? ?? 'delivered',
      attachment: json['attachment'] != null
          ? ChatMessageAttachmentItem.fromJson(json['attachment'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'sender_role_label': senderRoleLabel,
        'avatar_url': avatarUrl,
        'avatar_initials': avatarInitials,
        'content': content,
        'timestamp': timestamp,
        'date_group': dateGroup,
        'is_self': isSelf,
        'delivery_status': deliveryStatus,
        'attachment': attachment?.toJson(),
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Specialist Session Summary & Notes model corresponding to the Stitch design.
///
/// Encapsulates all educational, non-diagnostic observation data:
/// * Learner profile identity & session completion metrics
/// * Selected learning pillars worked on
/// * Session observations & pedagogical notes
/// * Progress outcome rating
/// * Next practice focus
/// * Selected follow-up collaborative actions
/// * Next scheduled practice check-in
@immutable
class SpecialistSessionSummaryModel {
  final String id;
  final String? sessionId;
  final String? creatorId;
  final String? creatorName;
  final String learnerId;
  final String learnerName;
  final String learnerAgeBand;
  final String sessionDate;
  final String sessionTime;
  final int sessionDurationMinutes;
  final String sessionType;
  final String targetFocus;
  final int cardsCompleted;
  final int pacingRhythmPercentage;
  final int audioReflectionsCount;
  final List<String> workingAreas;
  final String notes;
  final String outcome; // 'great_progress', 'good_progress', 'steady_practice', 'needs_support'
  final String nextPracticeFocus;
  final String nextPracticeDescription;
  final List<String> followUpActions;
  final String? nextScheduledSessionDate;
  final String? nextScheduledSessionDescription;
  final String status;
  final DateTime? createdAt;
  final String? disclaimer;

  const SpecialistSessionSummaryModel({
    required this.id,
    this.sessionId,
    this.creatorId,
    this.creatorName,
    required this.learnerId,
    required this.learnerName,
    this.learnerAgeBand = 'Child • 10 yrs',
    this.sessionDate = 'Today, Oct 17',
    this.sessionTime = '10:30 – 11:02 AM',
    this.sessionDurationMinutes = 31,
    this.sessionType = '1-to-1 Live Support',
    this.targetFocus = '/r/ Blends',
    this.cardsCompleted = 8,
    this.pacingRhythmPercentage = 88,
    this.audioReflectionsCount = 1,
    this.workingAreas = const [
      'Phonics & Blends',
      'Speaking & Pacing',
      'Reading Aloud',
    ],
    this.notes = '',
    this.outcome = 'great_progress',
    this.nextPracticeFocus = 'Consonant Clusters (/rk/, /st/) in 2-syllable words',
    this.nextPracticeDescription = 'Assigned to Aarav\'s home practice deck with playful tactile rewards.',
    this.followUpActions = const [
      'Send tailored /r/ practice cards to Parent',
      'Share session highlight with Teacher',
    ],
    this.nextScheduledSessionDate = 'Friday, Oct 25 • 10:30 AM',
    this.nextScheduledSessionDescription = 'Practice Check-in • 20 min live video',
    this.status = 'completed',
    this.createdAt,
    this.disclaimer,
  });

  SpecialistSessionSummaryModel copyWith({
    String? id,
    String? sessionId,
    String? creatorId,
    String? creatorName,
    String? learnerId,
    String? learnerName,
    String? learnerAgeBand,
    String? sessionDate,
    String? sessionTime,
    int? sessionDurationMinutes,
    String? sessionType,
    String? targetFocus,
    int? cardsCompleted,
    int? pacingRhythmPercentage,
    int? audioReflectionsCount,
    List<String>? workingAreas,
    String? notes,
    String? outcome,
    String? nextPracticeFocus,
    String? nextPracticeDescription,
    List<String>? followUpActions,
    String? nextScheduledSessionDate,
    String? nextScheduledSessionDescription,
    String? status,
    DateTime? createdAt,
    String? disclaimer,
  }) {
    return SpecialistSessionSummaryModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      learnerId: learnerId ?? this.learnerId,
      learnerName: learnerName ?? this.learnerName,
      learnerAgeBand: learnerAgeBand ?? this.learnerAgeBand,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionType: sessionType ?? this.sessionType,
      targetFocus: targetFocus ?? this.targetFocus,
      cardsCompleted: cardsCompleted ?? this.cardsCompleted,
      pacingRhythmPercentage: pacingRhythmPercentage ?? this.pacingRhythmPercentage,
      audioReflectionsCount: audioReflectionsCount ?? this.audioReflectionsCount,
      workingAreas: workingAreas ?? this.workingAreas,
      notes: notes ?? this.notes,
      outcome: outcome ?? this.outcome,
      nextPracticeFocus: nextPracticeFocus ?? this.nextPracticeFocus,
      nextPracticeDescription: nextPracticeDescription ?? this.nextPracticeDescription,
      followUpActions: followUpActions ?? this.followUpActions,
      nextScheduledSessionDate: nextScheduledSessionDate ?? this.nextScheduledSessionDate,
      nextScheduledSessionDescription: nextScheduledSessionDescription ?? this.nextScheduledSessionDescription,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  factory SpecialistSessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SpecialistSessionSummaryModel(
      id: json['id'] as String? ?? 'summary_default',
      sessionId: json['session_id'] as String?,
      creatorId: json['creator_id'] as String?,
      creatorName: json['creator_name'] as String?,
      learnerId: json['learner_id'] as String? ?? 'learner-aarav',
      learnerName: json['learner_name'] as String? ?? 'Aarav Mehta',
      learnerAgeBand: json['learner_age_band'] as String? ?? 'Child • 10 yrs',
      sessionDate: json['session_date'] as String? ?? 'Today, Oct 17',
      sessionTime: json['session_time'] as String? ?? '10:30 – 11:02 AM',
      sessionDurationMinutes: (json['session_duration_minutes'] as num?)?.toInt() ?? 31,
      sessionType: json['session_type'] as String? ?? '1-to-1 Live Support',
      targetFocus: json['target_focus'] as String? ?? '/r/ Blends',
      cardsCompleted: (json['cards_completed'] as num?)?.toInt() ?? 8,
      pacingRhythmPercentage: (json['pacing_rhythm_percentage'] as num?)?.toInt() ?? 88,
      audioReflectionsCount: (json['audio_reflections_count'] as num?)?.toInt() ?? 1,
      workingAreas: (json['working_areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Phonics & Blends',
            'Speaking & Pacing',
            'Reading Aloud',
          ],
      notes: json['notes'] as String? ?? '',
      outcome: json['outcome'] as String? ?? 'great_progress',
      nextPracticeFocus: json['next_practice_focus'] as String? ??
          'Consonant Clusters (/rk/, /st/) in 2-syllable words',
      nextPracticeDescription: json['next_practice_description'] as String? ??
          'Assigned to Aarav\'s home practice deck with playful tactile rewards.',
      followUpActions: (json['follow_up_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Send tailored /r/ practice cards to Parent',
            'Share session highlight with Teacher',
          ],
      nextScheduledSessionDate: json['next_scheduled_session'] as String? ??
          json['next_scheduled_session_date'] as String? ??
          'Friday, Oct 25 • 10:30 AM',
      nextScheduledSessionDescription:
          json['next_scheduled_session_description'] as String? ??
              'Practice Check-in • 20 min live video',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      disclaimer: json['disclaimer'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'creator_id': creatorId,
        'creator_name': creatorName,
        'learner_id': learnerId,
        'learner_name': learnerName,
        'learner_age_band': learnerAgeBand,
        'session_date': sessionDate,
        'session_time': sessionTime,
        'session_duration_minutes': sessionDurationMinutes,
        'session_type': sessionType,
        'target_focus': targetFocus,
        'cards_completed': cardsCompleted,
        'pacing_rhythm_percentage': pacingRhythmPercentage,
        'audio_reflections_count': audioReflectionsCount,
        'working_areas': workingAreas,
        'notes': notes,
        'outcome': outcome,
        'next_practice_focus': nextPracticeFocus,
        'next_practice_description': nextPracticeDescription,
        'follow_up_actions': followUpActions,
        'next_scheduled_session': nextScheduledSessionDate,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'disclaimer': disclaimer,
      };
}

// -----------------------------------------------------------------------------
// 12. SPECIALIST PROFILE MODEL (Stitch Visual Source of Truth)
// -----------------------------------------------------------------------------
class SpecialistCredentialItem {
  final String title;
  final String subtitle;
  final String type; // "degree", "license", "safety"

  const SpecialistCredentialItem({
    required this.title,
    required this.subtitle,
    required this.type,
  });

  factory SpecialistCredentialItem.fromJson(Map<String, dynamic> json) {
    return SpecialistCredentialItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      type: json['type'] as String? ?? 'license',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'type': type,
      };
}

class SpecialistProfileModel {
  final String id;
  final String displayName;
  final String professionalTitle;
  final bool isVerified;
  final String verificationBadge;
  final String location;
  final int availabilitySpots;
  final int activeLearnersCount;
  final double rating;
  final int reviewsCount;
  final int experienceYears;
  final String profileVisibility;
  final String aboutMe;
  final String fullBio;
  final List<String> supportFocusAreas;
  final Map<String, String> practiceDetails;
  final List<SpecialistCredentialItem> credentials;
  final String disclaimer;
  final String privacyReassurance;

  const SpecialistProfileModel({
    required this.id,
    required this.displayName,
    required this.professionalTitle,
    required this.isVerified,
    required this.verificationBadge,
    required this.location,
    required this.availabilitySpots,
    required this.activeLearnersCount,
    required this.rating,
    required this.reviewsCount,
    required this.experienceYears,
    required this.profileVisibility,
    required this.aboutMe,
    required this.fullBio,
    required this.supportFocusAreas,
    required this.practiceDetails,
    required this.credentials,
    required this.disclaimer,
    required this.privacyReassurance,
  });

  factory SpecialistProfileModel.defaultProfile() {
    return const SpecialistProfileModel(
      id: 'spec_maya_default',
      displayName: 'Maya Reynolds, M.S.',
      professionalTitle: 'Learning Support Specialist (CCC-SLP)',
      isVerified: true,
      verificationBadge: 'VERIFIED SPECIALIST • LINGUA SAFE',
      location: 'San Francisco, CA',
      availabilitySpots: 3,
      activeLearnersCount: 8,
      rating: 4.9,
      reviewsCount: 42,
      experienceYears: 5,
      profileVisibility: 'Parents & Learners',
      aboutMe: "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading...",
      fullBio: "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading fluency. With over 8 years of clinical and educational practice, I specialize in pediatric speech scaffolding, multi-sensory phonics exercises, and cross-collaborative support between families and classroom educators.",
      supportFocusAreas: [
        'Reading Fluency',
        'Speech & Pacing',
        'Phonics & Spelling',
        'Vocabulary Growth',
        'Story Expression',
        'Active Listening',
        'Tactile Game Play',
      ],
      practiceDetails: {
        'experience': '8+ Years Pediatric Practice',
        'languages': 'English (Native), Spanish (Conversational)',
        'age_groups': 'Preschool (3–5), Elementary (6–10), Teens (11–16)',
        'supported_formats': '1-on-1 Interactive Audio & Video, Asynchronous Practice Reviews',
      },
      credentials: [
        SpecialistCredentialItem(
          title: 'M.S. in Speech & Hearing Sciences',
          subtitle: 'University of Washington • Verified',
          type: 'degree',
        ),
        SpecialistCredentialItem(
          title: 'Clinical Competence Certificate (CCC-SLP)',
          subtitle: 'Active National Standing • Current',
          type: 'license',
        ),
        SpecialistCredentialItem(
          title: 'Lingua AI Child-Safe & HIPAA Verified',
          subtitle: 'Annual Review Complete • 2024',
          type: 'safety',
        ),
      ],
      disclaimer: 'Lingua AI provides developmental learning facilitation and educational practice.',
      privacyReassurance: 'Only details you approve are shared with families. Protected by the Lingua AI Child-Safe Guarantee.',
    );
  }

  factory SpecialistProfileModel.fromJson(Map<String, dynamic> json) {
    return SpecialistProfileModel(
      id: json['id'] as String? ?? 'spec_default',
      displayName: json['display_name'] as String? ?? 'Maya Reynolds, M.S.',
      professionalTitle: json['professional_title'] as String? ??
          'Learning Support Specialist (CCC-SLP)',
      isVerified: json['is_verified'] as bool? ?? true,
      verificationBadge: json['verification_badge'] as String? ??
          'VERIFIED SPECIALIST • LINGUA SAFE',
      location: json['location'] as String? ?? 'San Francisco, CA',
      availabilitySpots: json['availability_spots'] as int? ?? 3,
      activeLearnersCount: json['active_learners_count'] as int? ?? 8,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewsCount: json['reviews_count'] as int? ?? 42,
      experienceYears: json['experience_years'] as int? ?? 5,
      profileVisibility: json['profile_visibility'] as String? ?? 'Parents & Learners',
      aboutMe: json['about_me'] as String? ??
          "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading...",
      fullBio: json['full_bio'] as String? ??
          "Hi there! I'm Maya. I help young learners build joyful confidence in phonemic awareness, speech pacing, and reading fluency. With over 8 years of clinical and educational practice, I specialize in pediatric speech scaffolding, multi-sensory phonics exercises, and cross-collaborative support between families and classroom educators.",
      supportFocusAreas: (json['support_focus_areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Reading Fluency',
            'Speech & Pacing',
            'Phonics & Spelling',
            'Vocabulary Growth',
            'Story Expression',
            'Active Listening',
            'Tactile Game Play',
          ],
      practiceDetails: (json['practice_details'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {
            'experience': '8+ Years Pediatric Practice',
            'languages': 'English (Native), Spanish (Conversational)',
            'age_groups': 'Preschool (3–5), Elementary (6–10), Teens (11–16)',
            'supported_formats':
                '1-on-1 Interactive Audio & Video, Asynchronous Practice Reviews',
          },
      credentials: (json['credentials'] as List<dynamic>?)
              ?.map((e) =>
                  SpecialistCredentialItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            SpecialistCredentialItem(
              title: 'M.S. in Speech & Hearing Sciences',
              subtitle: 'University of Washington • Verified',
              type: 'degree',
            ),
            SpecialistCredentialItem(
              title: 'Clinical Competence Certificate (CCC-SLP)',
              subtitle: 'Active National Standing • Current',
              type: 'license',
            ),
            SpecialistCredentialItem(
              title: 'Lingua AI Child-Safe & HIPAA Verified',
              subtitle: 'Annual Review Complete • 2024',
              type: 'safety',
            ),
          ],
      disclaimer: json['disclaimer'] as String? ??
          'Lingua AI provides developmental learning facilitation and educational practice.',
      privacyReassurance: json['privacy_reassurance'] as String? ??
          'Only details you approve are shared with families. Protected by the Lingua AI Child-Safe Guarantee.',
    );
  }

  SpecialistProfileModel copyWith({
    String? displayName,
    String? professionalTitle,
    String? location,
    int? availabilitySpots,
    int? activeLearnersCount,
    double? rating,
    int? reviewsCount,
    int? experienceYears,
    String? profileVisibility,
    String? aboutMe,
    String? fullBio,
    List<String>? supportFocusAreas,
    Map<String, String>? practiceDetails,
    List<SpecialistCredentialItem>? credentials,
  }) {
    return SpecialistProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      isVerified: isVerified,
      verificationBadge: verificationBadge,
      location: location ?? this.location,
      availabilitySpots: availabilitySpots ?? this.availabilitySpots,
      activeLearnersCount: activeLearnersCount ?? this.activeLearnersCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      experienceYears: experienceYears ?? this.experienceYears,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      aboutMe: aboutMe ?? this.aboutMe,
      fullBio: fullBio ?? this.fullBio,
      supportFocusAreas: supportFocusAreas ?? this.supportFocusAreas,
      practiceDetails: practiceDetails ?? this.practiceDetails,
      credentials: credentials ?? this.credentials,
      disclaimer: disclaimer,
      privacyReassurance: privacyReassurance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'professional_title': professionalTitle,
        'is_verified': isVerified,
        'verification_badge': verificationBadge,
        'location': location,
        'availability_spots': availabilitySpots,
        'active_learners_count': activeLearnersCount,
        'rating': rating,
        'reviews_count': reviewsCount,
        'experience_years': experienceYears,
        'profile_visibility': profileVisibility,
        'about_me': aboutMe,
        'full_bio': fullBio,
        'support_focus_areas': supportFocusAreas,
        'practice_details': practiceDetails,
        'credentials': credentials.map((e) => e.toJson()).toList(),
        'disclaimer': disclaimer,
        'privacy_reassurance': privacyReassurance,
      };
}

// -----------------------------------------------------------------------------
// 13. SPECIALIST NOTIFICATION MODEL (Stitch Visual Source of Truth)
// -----------------------------------------------------------------------------
class SpecialistNotificationModel {
  final String id;
  final String title;
  final String supportingText;
  final String timestamp;
  final String timeGroup; // "Today", "Yesterday & Earlier"
  final String category; // "all", "sessions", "learners", "messages", "team"
  final String? badgeLabel;
  final String? badgeType; // "interactive_audio", "consent_logged", "classroom_synergy"
  final bool isRead;
  final String? actionType; // "join_session", "review_details", "open_chat", "view_deck", "manage_schedule"
  final String? actionLabel;
  final String? targetId;
  final String iconType; // "video", "shield", "chat", "analytics", "calendar"

  const SpecialistNotificationModel({
    required this.id,
    required this.title,
    required this.supportingText,
    required this.timestamp,
    required this.timeGroup,
    required this.category,
    this.badgeLabel,
    this.badgeType,
    required this.isRead,
    this.actionType,
    this.actionLabel,
    this.targetId,
    required this.iconType,
  });

  static List<SpecialistNotificationModel> defaultNotifications() {
    return const [
      SpecialistNotificationModel(
        id: 'notif_001',
        title: 'Live session with Aarav in 30m',
        supportingText:
            '1-to-1 phonics & consonant clusters practice. Virtual room is primed.',
        timestamp: '10:00 AM',
        timeGroup: 'Today',
        category: 'sessions',
        badgeLabel: 'INTERACTIVE AUDIO',
        badgeType: 'interactive_audio',
        isRead: false,
        actionType: 'join_session',
        actionLabel: 'Join Session →',
        targetId: 'sess_live_001',
        iconType: 'video',
      ),
      SpecialistNotificationModel(
        id: 'notif_002',
        title: 'Priya Mehta accepted support c...',
        supportingText:
            "Guardian consent verified for Aarav's audio pacing & articulation logs.",
        timestamp: '9:15 AM',
        timeGroup: 'Today',
        category: 'learners',
        badgeLabel: 'CONSENT LOGGED',
        badgeType: 'consent_logged',
        isRead: false,
        actionType: 'review_details',
        actionLabel: 'Review Details',
        targetId: 'consent_aarav',
        iconType: 'shield',
      ),
      SpecialistNotificationModel(
        id: 'notif_003',
        title: 'New note from Mrs. Davies (Tea...',
        supportingText:
            '“Aarav raised his hand during story circle today! His /r/ sound was so clear.”',
        timestamp: '8:45 AM',
        timeGroup: 'Today',
        category: 'messages',
        badgeLabel: 'CLASSROOM SYNERGY',
        badgeType: 'classroom_synergy',
        isRead: false,
        actionType: 'open_chat',
        actionLabel: '↩ Open Chat',
        targetId: 'conv-aarav',
        iconType: 'chat',
      ),
      SpecialistNotificationModel(
        id: 'notif_004',
        title: 'Weekly progress summary gene...',
        supportingText:
            'Sofia K. completed 14 vocabulary speech decks with 92% pronunciation...',
        timestamp: 'Yesterday, 4:20 PM',
        timeGroup: 'Yesterday & Earlier',
        category: 'learners',
        badgeLabel: null,
        badgeType: null,
        isRead: true,
        actionType: 'view_deck',
        actionLabel: 'View Learning Deck →',
        targetId: 'deck_sofia',
        iconType: 'analytics',
      ),
      SpecialistNotificationModel(
        id: 'notif_005',
        title: 'Availability slot approved',
        supportingText:
            'New recurring Friday 10:30 AM specialist slot confirmed by curriculum...',
        timestamp: 'Oct 15',
        timeGroup: 'Yesterday & Earlier',
        category: 'team',
        badgeLabel: null,
        badgeType: null,
        isRead: true,
        actionType: 'manage_schedule',
        actionLabel: 'Manage Schedule',
        targetId: 'schedule_main',
        iconType: 'calendar',
      ),
    ];
  }

  factory SpecialistNotificationModel.fromJson(Map<String, dynamic> json) {
    return SpecialistNotificationModel(
      id: json['id'] as String? ?? 'notif_default',
      title: json['title'] as String? ?? '',
      supportingText: json['supporting_text'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      timeGroup: json['time_group'] as String? ?? 'Today',
      category: json['category'] as String? ?? 'all',
      badgeLabel: json['badge_label'] as String?,
      badgeType: json['badge_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      actionType: json['action_type'] as String?,
      actionLabel: json['action_label'] as String?,
      targetId: json['target_id'] as String?,
      iconType: json['icon_type'] as String? ?? 'video',
    );
  }

  bool get isToday => timeGroup == 'Today';

  SpecialistNotificationModel copyWith({
    bool? isRead,
  }) {
    return SpecialistNotificationModel(
      id: id,
      title: title,
      supportingText: supportingText,
      timestamp: timestamp,
      timeGroup: timeGroup,
      category: category,
      badgeLabel: badgeLabel,
      badgeType: badgeType,
      isRead: isRead ?? this.isRead,
      actionType: actionType,
      actionLabel: actionLabel,
      targetId: targetId,
      iconType: iconType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'supporting_text': supportingText,
        'timestamp': timestamp,
        'time_group': timeGroup,
        'category': category,
        'badge_label': badgeLabel,
        'badge_type': badgeType,
        'is_read': isRead,
        'action_type': actionType,
        'action_label': actionLabel,
        'target_id': targetId,
        'icon_type': iconType,
      };
}

// -----------------------------------------------------------------------------
// 14. SPECIALIST CONSENT CIRCLE MODEL (Stitch Visual Source of Truth)
// -----------------------------------------------------------------------------
class CircleMemberModel {
  final String name;
  final String roleLabel; // "(Guardian)", "(Teacher)", "(Specialist)"
  final String initial;
  final bool isSpecialist;

  const CircleMemberModel({
    required this.name,
    required this.roleLabel,
    required this.initial,
    this.isSpecialist = false,
  });

  factory CircleMemberModel.fromJson(Map<String, dynamic> json) {
    return CircleMemberModel(
      name: json['name'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? '',
      initial: json['initial'] as String? ?? '',
      isSpecialist: json['is_specialist'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role_label': roleLabel,
        'initial': initial,
        'is_specialist': isSpecialist,
      };
}

class PermissionScopeItemModel {
  final String key;
  final String title;
  final bool isShared;
  final String statusLabel; // "Shared", "Not Shared", "Learner Private"
  final String iconType; // "mic", "trend", "chat", "puzzle", "mic_off", "book"

  const PermissionScopeItemModel({
    required this.key,
    required this.title,
    required this.isShared,
    required this.statusLabel,
    required this.iconType,
  });

  factory PermissionScopeItemModel.fromJson(Map<String, dynamic> json) {
    return PermissionScopeItemModel(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isShared: json['is_shared'] as bool? ?? true,
      statusLabel: json['status_label'] as String? ?? 'Shared',
      iconType: json['icon_type'] as String? ?? 'mic',
    );
  }

  PermissionScopeItemModel copyWith({
    bool? isShared,
    String? statusLabel,
  }) {
    return PermissionScopeItemModel(
      key: key,
      title: title,
      isShared: isShared ?? this.isShared,
      statusLabel: statusLabel ?? this.statusLabel,
      iconType: iconType,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'is_shared': isShared,
        'status_label': statusLabel,
        'icon_type': iconType,
      };
}

class SpecialistConsentCircleModel {
  final String id;
  final String learnerId;
  final String learnerName;
  final String learnerInitials;
  final String status; // "active", "limited", "pending", "revoked"
  final String statusLabel; // "✓ Active", "⇄ Limited"
  final String subtitle; // "Learner • 10 yrs • Grade 4"
  final List<CircleMemberModel> collaborationCircle;
  final List<PermissionScopeItemModel> permissionScopes;
  final String? consentReconfirmedDate;
  final String? updatedTimeAgo;
  final String avatarColor; // "purple", "amber"

  const SpecialistConsentCircleModel({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    required this.learnerInitials,
    required this.status,
    required this.statusLabel,
    required this.subtitle,
    required this.collaborationCircle,
    required this.permissionScopes,
    this.consentReconfirmedDate,
    this.updatedTimeAgo,
    this.avatarColor = 'purple',
  });

  static List<SpecialistConsentCircleModel> defaultCircles() {
    return const [
      SpecialistConsentCircleModel(
        id: 'circle_aarav',
        learnerId: 'learner-aarav',
        learnerName: 'Aarav Mehta',
        learnerInitials: 'AM',
        status: 'active',
        statusLabel: '✓ Active',
        subtitle: 'Learner • 10 yrs • Grade 4',
        collaborationCircle: [
          CircleMemberModel(name: 'Priya Mehta', roleLabel: '(Guardian)', initial: 'P'),
          CircleMemberModel(name: 'Mrs. Davies', roleLabel: '(Teacher)', initial: 'D'),
          CircleMemberModel(name: 'You', roleLabel: '(Specialist)', initial: '★', isSpecialist: true),
        ],
        permissionScopes: [
          PermissionScopeItemModel(
            key: 'practice_audio',
            title: 'Practice Audio & Speech ...',
            isShared: true,
            statusLabel: 'Shared',
            iconType: 'mic',
          ),
          PermissionScopeItemModel(
            key: 'weekly_progress',
            title: 'Weekly Progress & Miles...',
            isShared: true,
            statusLabel: 'Shared',
            iconType: 'trend',
          ),
          PermissionScopeItemModel(
            key: 'practice_sessions',
            title: '1-on-1 Practice Session ...',
            isShared: true,
            statusLabel: 'Shared',
            iconType: 'chat',
          ),
          PermissionScopeItemModel(
            key: 'phonics_games',
            title: 'Phonics Games & Word ...',
            isShared: true,
            statusLabel: 'Shared',
            iconType: 'puzzle',
          ),
          PermissionScopeItemModel(
            key: 'raw_classroom',
            title: 'Raw Classroom Ambi...',
            isShared: false,
            statusLabel: 'Not Shared',
            iconType: 'mic_off',
          ),
        ],
        consentReconfirmedDate: 'Oct 12, 2024',
        updatedTimeAgo: 'Oct 12, 2024',
        avatarColor: 'purple',
      ),
      SpecialistConsentCircleModel(
        id: 'circle_sophia',
        learnerId: 'learner-sophia',
        learnerName: 'Sophia Chen',
        learnerInitials: 'SC',
        status: 'limited',
        statusLabel: '⇄ Limited',
        subtitle: 'Teen Learner • 15 yrs • Self-directed',
        collaborationCircle: [
          CircleMemberModel(name: 'Sophia Chen', roleLabel: '(Learner / Self)', initial: 'SC'),
          CircleMemberModel(name: 'You', roleLabel: '(Specialist)', initial: '★', isSpecialist: true),
        ],
        permissionScopes: [
          PermissionScopeItemModel(
            key: 'reading_fluency',
            title: 'Reading Fluency & Sum...',
            isShared: true,
            statusLabel: 'Shared',
            iconType: 'book',
          ),
          PermissionScopeItemModel(
            key: 'raw_practice_audio',
            title: 'Raw Practice Audi...',
            isShared: false,
            statusLabel: 'Learner Private',
            iconType: 'mic_off',
          ),
        ],
        consentReconfirmedDate: null,
        updatedTimeAgo: '3 days ago',
        avatarColor: 'amber',
      ),
    ];
  }

  factory SpecialistConsentCircleModel.fromJson(Map<String, dynamic> json) {
    return SpecialistConsentCircleModel(
      id: json['id'] as String? ?? 'circle_default',
      learnerId: json['learner_id'] as String? ?? 'learner_default',
      learnerName: json['learner_name'] as String? ?? '',
      learnerInitials: json['learner_initials'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      statusLabel: json['status_label'] as String? ?? '✓ Active',
      subtitle: json['subtitle'] as String? ?? '',
      collaborationCircle: (json['collaboration_circle'] as List<dynamic>?)
              ?.map((e) => CircleMemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      permissionScopes: (json['permission_scopes'] as List<dynamic>?)
              ?.map((e) =>
                  PermissionScopeItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      consentReconfirmedDate: json['consent_reconfirmed_date'] as String?,
      updatedTimeAgo: json['updated_time_ago'] as String?,
      avatarColor: json['avatar_color'] as String? ?? 'purple',
    );
  }

  SpecialistConsentCircleModel copyWith({
    List<PermissionScopeItemModel>? permissionScopes,
    String? status,
    String? statusLabel,
  }) {
    return SpecialistConsentCircleModel(
      id: id,
      learnerId: learnerId,
      learnerName: learnerName,
      learnerInitials: learnerInitials,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      subtitle: subtitle,
      collaborationCircle: collaborationCircle,
      permissionScopes: permissionScopes ?? this.permissionScopes,
      consentReconfirmedDate: consentReconfirmedDate,
      updatedTimeAgo: updatedTimeAgo,
      avatarColor: avatarColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learner_id': learnerId,
        'learner_name': learnerName,
        'learner_initials': learnerInitials,
        'status': status,
        'status_label': statusLabel,
        'subtitle': subtitle,
        'collaboration_circle':
            collaborationCircle.map((e) => e.toJson()).toList(),
        'permission_scopes': permissionScopes.map((e) => e.toJson()).toList(),
        'consent_reconfirmed_date': consentReconfirmedDate,
        'updated_time_ago': updatedTimeAgo,
        'avatar_color': avatarColor,
      };
}

// ---------------------------------------------------------------------------
// Screen 1: Availability & Appointment Settings Models
// ---------------------------------------------------------------------------
class SpecialistTimeSlotModel {
  final String id;
  final String timeRange;
  final String iconType;

  const SpecialistTimeSlotModel({
    required this.id,
    required this.timeRange,
    this.iconType = 'sun',
  });

  factory SpecialistTimeSlotModel.fromJson(Map<String, dynamic> json) {
    return SpecialistTimeSlotModel(
      id: json['id'] as String? ?? '',
      timeRange: json['time_range'] as String? ?? '',
      iconType: json['icon_type'] as String? ?? 'sun',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time_range': timeRange,
        'icon_type': iconType,
      };

  SpecialistTimeSlotModel copyWith({
    String? id,
    String? timeRange,
    String? iconType,
  }) {
    return SpecialistTimeSlotModel(
      id: id ?? this.id,
      timeRange: timeRange ?? this.timeRange,
      iconType: iconType ?? this.iconType,
    );
  }
}

class SpecialistDayAvailabilityModel {
  final String dayKey;
  final String dayLabel;
  final String initial;
  final bool isEnabled;
  final String subtitle;
  final List<SpecialistTimeSlotModel> slots;

  const SpecialistDayAvailabilityModel({
    required this.dayKey,
    required this.dayLabel,
    required this.initial,
    this.isEnabled = true,
    required this.subtitle,
    this.slots = const [],
  });

  factory SpecialistDayAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SpecialistDayAvailabilityModel(
      dayKey: json['day_key'] as String? ?? '',
      dayLabel: json['day_label'] as String? ?? '',
      initial: json['initial'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
      subtitle: json['subtitle'] as String? ?? '',
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) =>
                  SpecialistTimeSlotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'day_key': dayKey,
        'day_label': dayLabel,
        'initial': initial,
        'is_enabled': isEnabled,
        'subtitle': subtitle,
        'slots': slots.map((e) => e.toJson()).toList(),
      };

  SpecialistDayAvailabilityModel copyWith({
    String? dayKey,
    String? dayLabel,
    String? initial,
    bool? isEnabled,
    String? subtitle,
    List<SpecialistTimeSlotModel>? slots,
  }) {
    return SpecialistDayAvailabilityModel(
      dayKey: dayKey ?? this.dayKey,
      dayLabel: dayLabel ?? this.dayLabel,
      initial: initial ?? this.initial,
      isEnabled: isEnabled ?? this.isEnabled,
      subtitle: subtitle ?? this.subtitle,
      slots: slots ?? this.slots,
    );
  }
}

class SpecialistAvailabilityModel {
  final String specialistName;
  final String specialistTitle;
  final String specialistBadge;
  final bool availableForSessions;
  final String timezone;
  final List<SpecialistDayAvailabilityModel> days;
  final int sessionDurationMinutes;
  final int bufferMinutes;
  final int dailySessionCap;
  final String advanceNotice;

  const SpecialistAvailabilityModel({
    this.specialistName = 'Dr. Maya Lin, M.S. CCC-SLP',
    this.specialistTitle = 'Pediatric Speech & Phoneme Coaching',
    this.specialistBadge = 'LINGUA SPECIALIST • Active Caseload',
    this.availableForSessions = true,
    this.timezone = 'Pacific Time (GMT-7)',
    this.days = const [],
    this.sessionDurationMinutes = 45,
    this.bufferMinutes = 15,
    this.dailySessionCap = 5,
    this.advanceNotice = '24h Notice',
  });

  factory SpecialistAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SpecialistAvailabilityModel(
      specialistName: json['specialist_name'] as String? ??
          'Dr. Maya Lin, M.S. CCC-SLP',
      specialistTitle: json['specialist_title'] as String? ??
          'Pediatric Speech & Phoneme Coaching',
      specialistBadge: json['specialist_badge'] as String? ??
          'LINGUA SPECIALIST • Active Caseload',
      availableForSessions: json['available_for_sessions'] as bool? ?? true,
      timezone: json['timezone'] as String? ?? 'Pacific Time (GMT-7)',
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => SpecialistDayAvailabilityModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      sessionDurationMinutes: json['session_duration_minutes'] as int? ?? 45,
      bufferMinutes: json['buffer_minutes'] as int? ?? 15,
      dailySessionCap: json['daily_session_cap'] as int? ?? 5,
      advanceNotice: json['advance_notice'] as String? ?? '24h Notice',
    );
  }

  Map<String, dynamic> toJson() => {
        'specialist_name': specialistName,
        'specialist_title': specialistTitle,
        'specialist_badge': specialistBadge,
        'available_for_sessions': availableForSessions,
        'timezone': timezone,
        'days': days.map((e) => e.toJson()).toList(),
        'session_duration_minutes': sessionDurationMinutes,
        'buffer_minutes': bufferMinutes,
        'daily_session_cap': dailySessionCap,
        'advance_notice': advanceNotice,
      };

  SpecialistAvailabilityModel copyWith({
    String? specialistName,
    String? specialistTitle,
    String? specialistBadge,
    bool? availableForSessions,
    String? timezone,
    List<SpecialistDayAvailabilityModel>? days,
    int? sessionDurationMinutes,
    int? bufferMinutes,
    int? dailySessionCap,
    String? advanceNotice,
  }) {
    return SpecialistAvailabilityModel(
      specialistName: specialistName ?? this.specialistName,
      specialistTitle: specialistTitle ?? this.specialistTitle,
      specialistBadge: specialistBadge ?? this.specialistBadge,
      availableForSessions: availableForSessions ?? this.availableForSessions,
      timezone: timezone ?? this.timezone,
      days: days ?? this.days,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      dailySessionCap: dailySessionCap ?? this.dailySessionCap,
      advanceNotice: advanceNotice ?? this.advanceNotice,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 2: Specialist Verification Status Models
// ---------------------------------------------------------------------------
class SpecialistMilestoneItemModel {
  final String key;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const SpecialistMilestoneItemModel({
    required this.key,
    required this.label,
    this.isCompleted = true,
    this.isCurrent = false,
  });

  factory SpecialistMilestoneItemModel.fromJson(Map<String, dynamic> json) {
    return SpecialistMilestoneItemModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? true,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'is_completed': isCompleted,
        'is_current': isCurrent,
      };
}

class SpecialistVerifiedDocumentModel {
  final String id;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String iconType;
  final bool isApproved;

  const SpecialistVerifiedDocumentModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.statusLabel = 'Approved',
    this.iconType = 'grad_cap',
    this.isApproved = true,
  });

  factory SpecialistVerifiedDocumentModel.fromJson(Map<String, dynamic> json) {
    return SpecialistVerifiedDocumentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? 'Approved',
      iconType: json['icon_type'] as String? ?? 'grad_cap',
      isApproved: json['is_approved'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'status_label': statusLabel,
        'icon_type': iconType,
        'is_approved': isApproved,
      };
}

class SpecialistVerificationModel {
  final String verificationStatus;
  final String statusBadge;
  final String headline;
  final String description;
  final String verificationDateText;
  final int milestonesCompleted;
  final int milestonesTotal;
  final List<SpecialistMilestoneItemModel> milestones;
  final String specialistName;
  final String specialistInitials;
  final String specialistRoleSubtitle;
  final String experienceText;
  final String languagesText;
  final List<String> approvedDomains;
  final List<SpecialistVerifiedDocumentModel> verifiedDocuments;
  final String complianceNotice;

  const SpecialistVerificationModel({
    this.verificationStatus = 'verified',
    this.statusBadge = 'PROFILE VERIFIED',
    this.headline = 'Your profile is verified',
    this.description =
        'Your specialist credentials and child-safety background checks are confirmed. Families and schools can discover your profile and book sessions.',
    this.verificationDateText = 'Verified Oct 14, 2024 • Next check: Oct 2025',
    this.milestonesCompleted = 5,
    this.milestonesTotal = 5,
    this.milestones = const [],
    this.specialistName = 'Maya Reynolds, M.S.',
    this.specialistInitials = 'MR',
    this.specialistRoleSubtitle =
        'Learning Support Specialist (CCC-SLP)',
    this.experienceText = '8+ Yrs Pediatric',
    this.languagesText = 'English, Spanish',
    this.approvedDomains = const [
      'Reading Fluency',
      'Speech & Pacing',
      'Phonics & Spelling',
      'Vocabulary Growth',
    ],
    this.verifiedDocuments = const [],
    this.complianceNotice = 'Encrypted • FERPA Compliant',
  });

  factory SpecialistVerificationModel.fromJson(Map<String, dynamic> json) {
    return SpecialistVerificationModel(
      verificationStatus: json['verification_status'] as String? ?? 'verified',
      statusBadge: json['status_badge'] as String? ?? 'PROFILE VERIFIED',
      headline: json['headline'] as String? ?? 'Your profile is verified',
      description: json['description'] as String? ?? '',
      verificationDateText:
          json['verification_date_text'] as String? ?? '',
      milestonesCompleted: json['milestones_completed'] as int? ?? 5,
      milestonesTotal: json['milestones_total'] as int? ?? 5,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((e) => SpecialistMilestoneItemModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      specialistName:
          json['specialist_name'] as String? ?? 'Maya Reynolds, M.S.',
      specialistInitials:
          json['specialist_initials'] as String? ?? 'MR',
      specialistRoleSubtitle: json['specialist_role_subtitle'] as String? ??
          'Learning Support Specialist (CCC-SLP)',
      experienceText:
          json['experience_text'] as String? ?? '8+ Yrs Pediatric',
      languagesText: json['languages_text'] as String? ?? 'English, Spanish',
      approvedDomains: (json['approved_domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Reading Fluency',
            'Speech & Pacing',
            'Phonics & Spelling',
            'Vocabulary Growth',
          ],
      verifiedDocuments: (json['verified_documents'] as List<dynamic>?)
              ?.map((e) => SpecialistVerifiedDocumentModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      complianceNotice: json['compliance_notice'] as String? ??
          'Encrypted • FERPA Compliant',
    );
  }

  Map<String, dynamic> toJson() => {
        'verification_status': verificationStatus,
        'status_badge': statusBadge,
        'headline': headline,
        'description': description,
        'verification_date_text': verificationDateText,
        'milestones_completed': milestonesCompleted,
        'milestones_total': milestonesTotal,
        'milestones': milestones.map((e) => e.toJson()).toList(),
        'specialist_name': specialistName,
        'specialist_initials': specialistInitials,
        'specialist_role_subtitle': specialistRoleSubtitle,
        'experience_text': experienceText,
        'languages_text': languagesText,
        'approved_domains': approvedDomains,
        'verified_documents':
            verifiedDocuments.map((e) => e.toJson()).toList(),
        'compliance_notice': complianceNotice,
      };
}

// ---------------------------------------------------------------------------
// Screen 3: Help & Support Models
// ---------------------------------------------------------------------------
class HelpCategoryItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String iconType;
  final String color;

  const HelpCategoryItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconType,
    this.color = 'purple',
  });

  factory HelpCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return HelpCategoryItemModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      iconType: json['icon_type'] as String? ?? 'person',
      color: json['color'] as String? ?? 'purple',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'icon_type': iconType,
        'color': color,
      };
}

class FaqItemModel {
  final String id;
  final String question;
  final String answer;

  const FaqItemModel({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory FaqItemModel.fromJson(Map<String, dynamic> json) {
    return FaqItemModel(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
      };
}

class SpecialistHelpModel {
  final List<HelpCategoryItemModel> categories;
  final List<FaqItemModel> faqs;
  final String supportDeskHours;
  final String avgResponseTime;
  final String systemStatus;
  final String appVersion;

  const SpecialistHelpModel({
    this.categories = const [],
    this.faqs = const [],
    this.supportDeskHours = 'Mon–Fri, 8 AM–8 PM EST',
    this.avgResponseTime = '< 15 mins during desk hours',
    this.systemStatus = 'All Systems Operational',
    this.appVersion = 'Lingua Specialist v2.4.1 (Build 842)',
  });

  factory SpecialistHelpModel.fromJson(Map<String, dynamic> json) {
    return SpecialistHelpModel(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => HelpCategoryItemModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      faqs: (json['faqs'] as List<dynamic>?)
              ?.map((e) => FaqItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      supportDeskHours: json['support_desk_hours'] as String? ??
          'Mon–Fri, 8 AM–8 PM EST',
      avgResponseTime: json['avg_response_time'] as String? ??
          '< 15 mins during desk hours',
      systemStatus:
          json['system_status'] as String? ?? 'All Systems Operational',
      appVersion: json['app_version'] as String? ??
          'Lingua Specialist v2.4.1 (Build 842)',
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((e) => e.toJson()).toList(),
        'faqs': faqs.map((e) => e.toJson()).toList(),
        'support_desk_hours': supportDeskHours,
        'avg_response_time': avgResponseTime,
        'system_status': systemStatus,
        'app_version': appVersion,
      };
}

// ---------------------------------------------------------------------------
// SPECIALIST SETTINGS MODEL
// ---------------------------------------------------------------------------

class SpecialistSettingsModel {
  final String specialistName;
  final String specialistTitle;
  final bool isVerified;
  final String verificationBadge;
  final int activeLearnersCount;

  // Live Notifications
  final bool sessionReminders;
  final bool consentAlerts;
  final bool messagesAlerts;
  final bool appointmentRequests;
  final bool weeklyProgressDigests;

  // Child Safety & Consent
  final String profileVisibility;
  final String dataPrivacyLevel;

  // Accessibility & Comfort
  final bool largerText;
  final bool reduceMotion;
  final bool highContrast;
  final bool hapticFeedback;

  // Specialist Studio
  final String language;
  final String appearanceTheme;
  final String timeZone;
  final bool audioSoundFx;

  const SpecialistSettingsModel({
    this.specialistName = 'Maya Reynolds, M.S.',
    this.specialistTitle = 'Learning Support Specialist (CCC-SLP)',
    this.isVerified = true,
    this.verificationBadge = 'Profile Verified',
    this.activeLearnersCount = 18,
    this.sessionReminders = true,
    this.consentAlerts = true,
    this.messagesAlerts = true,
    this.appointmentRequests = true,
    this.weeklyProgressDigests = false,
    this.profileVisibility = 'Public',
    this.dataPrivacyLevel = 'COPPA-Compliant',
    this.largerText = false,
    this.reduceMotion = false,
    this.highContrast = false,
    this.hapticFeedback = true,
    this.language = 'English (US)',
    this.appearanceTheme = 'Light (Playful)',
    this.timeZone = 'Pacific Time (GMT-7)',
    this.audioSoundFx = true,
  });

  SpecialistSettingsModel copyWith({
    String? specialistName,
    String? specialistTitle,
    bool? isVerified,
    String? verificationBadge,
    int? activeLearnersCount,
    bool? sessionReminders,
    bool? consentAlerts,
    bool? messagesAlerts,
    bool? appointmentRequests,
    bool? weeklyProgressDigests,
    String? profileVisibility,
    String? dataPrivacyLevel,
    bool? largerText,
    bool? reduceMotion,
    bool? highContrast,
    bool? hapticFeedback,
    String? language,
    String? appearanceTheme,
    String? timeZone,
    bool? audioSoundFx,
  }) {
    return SpecialistSettingsModel(
      specialistName: specialistName ?? this.specialistName,
      specialistTitle: specialistTitle ?? this.specialistTitle,
      isVerified: isVerified ?? this.isVerified,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      activeLearnersCount: activeLearnersCount ?? this.activeLearnersCount,
      sessionReminders: sessionReminders ?? this.sessionReminders,
      consentAlerts: consentAlerts ?? this.consentAlerts,
      messagesAlerts: messagesAlerts ?? this.messagesAlerts,
      appointmentRequests: appointmentRequests ?? this.appointmentRequests,
      weeklyProgressDigests:
          weeklyProgressDigests ?? this.weeklyProgressDigests,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      dataPrivacyLevel: dataPrivacyLevel ?? this.dataPrivacyLevel,
      largerText: largerText ?? this.largerText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      language: language ?? this.language,
      appearanceTheme: appearanceTheme ?? this.appearanceTheme,
      timeZone: timeZone ?? this.timeZone,
      audioSoundFx: audioSoundFx ?? this.audioSoundFx,
    );
  }

  factory SpecialistSettingsModel.fromJson(Map<String, dynamic> json) {
    return SpecialistSettingsModel(
      specialistName:
          json['specialist_name'] as String? ?? 'Maya Reynolds, M.S.',
      specialistTitle: json['specialist_title'] as String? ??
          'Learning Support Specialist (CCC-SLP)',
      isVerified: json['is_verified'] as bool? ?? true,
      verificationBadge:
          json['verification_badge'] as String? ?? 'Profile Verified',
      activeLearnersCount: json['active_learners_count'] as int? ?? 18,
      sessionReminders: json['session_reminders'] as bool? ?? true,
      consentAlerts: json['consent_alerts'] as bool? ?? true,
      messagesAlerts: json['messages_alerts'] as bool? ?? true,
      appointmentRequests: json['appointment_requests'] as bool? ?? true,
      weeklyProgressDigests:
          json['weekly_progress_digests'] as bool? ?? false,
      profileVisibility: json['profile_visibility'] as String? ?? 'Public',
      dataPrivacyLevel:
          json['data_privacy_level'] as String? ?? 'COPPA-Compliant',
      largerText: json['larger_text'] as bool? ?? false,
      reduceMotion: json['reduce_motion'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      hapticFeedback: json['haptic_feedback'] as bool? ?? true,
      language: json['language'] as String? ?? 'English (US)',
      appearanceTheme:
          json['appearance_theme'] as String? ?? 'Light (Playful)',
      timeZone: json['time_zone'] as String? ?? 'Pacific Time (GMT-7)',
      audioSoundFx: json['audio_sound_fx'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'specialist_name': specialistName,
        'specialist_title': specialistTitle,
        'is_verified': isVerified,
        'verification_badge': verificationBadge,
        'active_learners_count': activeLearnersCount,
        'session_reminders': sessionReminders,
        'consent_alerts': consentAlerts,
        'messages_alerts': messagesAlerts,
        'appointment_requests': appointmentRequests,
        'weekly_progress_digests': weeklyProgressDigests,
        'profile_visibility': profileVisibility,
        'data_privacy_level': dataPrivacyLevel,
        'larger_text': largerText,
        'reduce_motion': reduceMotion,
        'high_contrast': highContrast,
        'haptic_feedback': hapticFeedback,
        'language': language,
        'appearance_theme': appearanceTheme,
        'time_zone': timeZone,
        'audio_sound_fx': audioSoundFx,
      };
}




