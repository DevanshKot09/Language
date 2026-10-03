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
