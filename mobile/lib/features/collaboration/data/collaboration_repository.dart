import 'package:lingua_ai/core/network/api_client.dart';
import 'package:lingua_ai/core/network/api_endpoints.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/progress/domain/models/progress_models.dart';
import 'package:lingua_ai/features/progress/domain/models/goal_models.dart';

abstract class ICollaborationRepository {
  Future<List<RelationshipItem>> getRelationships();
  Future<InvitationItem> createInvitation({
    required String inviteeEmail,
    required String relationshipType,
    String? targetLearnerId,
    String? organization,
    List<String>? permissionScope,
  });
  Future<List<InvitationItem>> getInvitations();
  Future<RelationshipItem> acceptInvitation(String token);
  Future<void> rejectInvitation(String token);
  Future<void> revokeRelationship(String relationshipId);

  // Parent Workspace
  Future<List<ParentChildItem>> getParentChildren();
  Future<ProgressDashboardData> getChildProgress(String childId);
  Future<List<Map<String, dynamic>>> getAvailableSpecialists();
  Future<Map<String, dynamic>> appointSpecialist({
    required String childId,
    String? specialistId,
    String? specialistEmail,
  });
  Future<Map<String, dynamic>> createChildProfile({
    required String displayName,
    required String ageBand,
    required String supportFocus,
  });

  // Teacher Workspace
  Future<List<TeacherStudentItem>> getTeacherStudents();
  Future<List<AssignmentItem>> getTeacherAssignments();
  Future<AssignmentItem> createAssignment({
    required String studentId,
    required String lessonId,
    required String title,
    String? instructions,
    DateTime? dueAt,
  });
  Future<Map<String, dynamic>> getClassroomTrends();

  // Specialist Workspace
  Future<List<SpecialistCaseloadItem>> getSpecialistCaseload();
  Future<Map<String, dynamic>> getSpecialistLearnerDetail(String learnerId);
  Future<LearnerGoal> createSpecialistGoal(
    String learnerId, {
    required String title,
    required String description,
    required String goalType,
    required int targetCount,
    String? skillId,
  });
  Future<void> reviewAiRecommendation(
    String recId, {
    required String humanStatus,
    String? modifiedReason,
    String? modifiedLessonId,
  });

  // Reports
  Future<List<ReportItem>> getReports({String? learnerId});
  Future<ReportItem> getReportDetail(String reportId);
  Future<ReportItem> createReport({
    required String learnerId,
    required String reportType,
    String? title,
  });
}

class CollaborationRepository implements ICollaborationRepository {
  final IApiClient _apiClient;

  CollaborationRepository(this._apiClient);

  @override
  Future<List<RelationshipItem>> getRelationships() async {
    final response = await _apiClient.get(ApiEndpoints.relationships);
    if (response is List) {
      return response
          .map((e) => RelationshipItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<InvitationItem> createInvitation({
    required String inviteeEmail,
    required String relationshipType,
    String? targetLearnerId,
    String? organization,
    List<String>? permissionScope,
  }) async {
    final body = <String, dynamic>{
      'invitee_email': inviteeEmail,
      'relationship_type': relationshipType,
      'target_learner_id': ?targetLearnerId,
      'organization': ?organization,
      'permission_scope': ?permissionScope,
    };
    final response = await _apiClient.post(
      ApiEndpoints.relationshipInvitations,
      body: body,
    );
    return InvitationItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<InvitationItem>> getInvitations() async {
    final response = await _apiClient.get(ApiEndpoints.relationshipInvitations);
    if (response is List) {
      return response
          .map((e) => InvitationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<RelationshipItem> acceptInvitation(String token) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.relationshipInvitations}/accept?token=$token',
      body: {},
    );
    return RelationshipItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> rejectInvitation(String token) async {
    await _apiClient.post(
      '${ApiEndpoints.relationshipInvitations}/reject?token=$token',
      body: {},
    );
  }

  @override
  Future<void> revokeRelationship(String relationshipId) async {
    await _apiClient.delete('${ApiEndpoints.relationships}/$relationshipId');
  }

  @override
  Future<List<ParentChildItem>> getParentChildren() async {
    final response = await _apiClient.get(ApiEndpoints.parentChildren);
    if (response is List) {
      return response
          .map((e) => ParentChildItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ProgressDashboardData> getChildProgress(String childId) async {
    final response = await _apiClient.get(ApiEndpoints.parentChildProgress(childId));
    return ProgressDashboardData.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<TeacherStudentItem>> getTeacherStudents() async {
    final response = await _apiClient.get(ApiEndpoints.teacherStudents);
    if (response is List) {
      return response
          .map((e) => TeacherStudentItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<AssignmentItem>> getTeacherAssignments() async {
    final response = await _apiClient.get(ApiEndpoints.teacherAssignments);
    if (response is List) {
      return response
          .map((e) => AssignmentItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<AssignmentItem> createAssignment({
    required String studentId,
    required String lessonId,
    required String title,
    String? instructions,
    DateTime? dueAt,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'lesson_id': lessonId,
      'title': title,
      'instructions': ?instructions,
      'due_at': ?dueAt?.toIso8601String(),
    };
    final response = await _apiClient.post(
      ApiEndpoints.teacherAssignments,
      body: body,
    );
    return AssignmentItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getClassroomTrends() async {
    final response = await _apiClient.get(ApiEndpoints.teacherClassroomTrends);
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<SpecialistCaseloadItem>> getSpecialistCaseload() async {
    final response = await _apiClient.get(ApiEndpoints.specialistCaseload);
    if (response is List) {
      return response
          .map((e) => SpecialistCaseloadItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getSpecialistLearnerDetail(String learnerId) async {
    final response = await _apiClient.get(ApiEndpoints.specialistLearnerDetail(learnerId));
    return response as Map<String, dynamic>;
  }

  @override
  Future<LearnerGoal> createSpecialistGoal(
    String learnerId, {
    required String title,
    required String description,
    required String goalType,
    required int targetCount,
    String? skillId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'goal_type': goalType,
      'target_count': targetCount,
      'skill_id': ?skillId,
    };
    final response = await _apiClient.post(
      ApiEndpoints.specialistLearnerGoals(learnerId),
      body: body,
    );
    return LearnerGoal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> reviewAiRecommendation(
    String recId, {
    required String humanStatus,
    String? modifiedReason,
    String? modifiedLessonId,
  }) async {
    final body = <String, dynamic>{
      'human_status': humanStatus,
      'modified_reason': ?modifiedReason,
      'modified_lesson_id': ?modifiedLessonId,
    };
    await _apiClient.put(
      ApiEndpoints.specialistReviewAiRec(recId),
      body: body,
    );
  }

  @override
  Future<List<ReportItem>> getReports({String? learnerId}) async {
    final url = learnerId != null
        ? '${ApiEndpoints.reports}?learner_id=$learnerId'
        : ApiEndpoints.reports;
    final response = await _apiClient.get(url);
    if (response is List) {
      return response
          .map((e) => ReportItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ReportItem> getReportDetail(String reportId) async {
    final response = await _apiClient.get(ApiEndpoints.reportDetail(reportId));
    return ReportItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ReportItem> createReport({
    required String learnerId,
    required String reportType,
    String? title,
  }) async {
    final body = <String, dynamic>{
      'learner_id': learnerId,
      'report_type': reportType,
      'title': ?title,
    };
    final response = await _apiClient.post(
      ApiEndpoints.reports,
      body: body,
    );
    return ReportItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableSpecialists() async {
    final response = await _apiClient.get(ApiEndpoints.specialists);
    return (response as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> appointSpecialist({
    required String childId,
    String? specialistId,
    String? specialistEmail,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentAppointSpecialist,
      body: {
        'child_id': childId,
        'specialist_id': ?specialistId,
        'specialist_email': ?specialistEmail,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> createChildProfile({
    required String displayName,
    required String ageBand,
    required String supportFocus,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentChildren,
      body: {
        'display_name': displayName,
        'age_band': ageBand,
        'support_focus': supportFocus,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
