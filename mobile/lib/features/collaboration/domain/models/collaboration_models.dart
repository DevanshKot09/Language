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

