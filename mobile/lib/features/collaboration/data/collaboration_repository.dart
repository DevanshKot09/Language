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

  // Messages & Collaboration
  Future<List<SpecialistConversationItem>> getSpecialistConversations({
    String? filter,
    String? search,
  });
  Future<List<ChatMessageItem>> getConversationMessages(String conversationId);
  Future<ChatMessageItem> sendConversationMessage(
    String conversationId,
    String content, {
    String? attachmentId,
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

  @override
  Future<List<SpecialistConversationItem>> getSpecialistConversations({
    String? filter,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = queryParams.isEmpty
          ? ApiEndpoints.specialistConversations
          : Uri(
              path: ApiEndpoints.specialistConversations,
              queryParameters: queryParams,
            ).toString();

      final response = await _apiClient.get(uri);
      if (response is List && response.isNotEmpty) {
        return response
            .map((e) => SpecialistConversationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // In demo/offline mode or before authentication, fall back to Stitch conversations
    }
    return _getFallbackSpecialistConversations(filter: filter, search: search);
  }

  List<SpecialistConversationItem> _getFallbackSpecialistConversations({
    String? filter,
    String? search,
  }) {
    const list = [
      SpecialistConversationItem(
        id: 'group_aarav',
        conversationType: 'group',
        category: 'teams',
        title: 'Aarav\'s Support Circle',
        subtitle: 'Parent · Teacher · Specialist',
        roles: ['Parent', 'Teacher', 'Specialist'],
        lastMessageSender: 'Priya M.',
        lastMessageText: 'Can we discuss tomorrow\'s phonics practice...',
        lastMessageTime: '10:42 AM',
        unreadCount: 2,
        isPinned: true,
        isOnline: true,
        consentStatus: 'verified',
        isLocked: false,
        targetLearnerId: 'learner-aarav',
        targetLearnerName: 'Aarav Sharma',
        avatarType: 'dual',
        avatarBadge: 'online',
      ),
      SpecialistConversationItem(
        id: 'group_maya',
        conversationType: 'group',
        category: 'teams',
        title: 'Maya\'s Learning Circle',
        subtitle: 'Adult Learner · Teacher · Specialist',
        roles: ['Adult Learner', 'Teacher', 'Specialist'],
        lastMessageSender: 'David W.',
        lastMessageText: 'Next week\'s fluency review is ready.',
        lastMessageTime: 'Yesterday',
        unreadCount: 0,
        isPinned: false,
        isOnline: false,
        consentStatus: 'verified',
        isLocked: false,
        targetLearnerId: 'learner-maya',
        targetLearnerName: 'Maya Lin',
        avatarType: 'team_teal',
        avatarBadge: 'team',
      ),
      SpecialistConversationItem(
        id: 'direct_parent_priya',
        conversationType: 'direct',
        category: 'learners',
        title: 'Priya Mehta',
        subtitle: 'Aarav\'s Primary Guardian',
        roles: ['Parent'],
        lastMessageSender: null,
        lastMessageText: 'Thank you for the quick turn summary! Aarav loved the star activity.',
        lastMessageTime: 'Oct 16',
        unreadCount: 0,
        isPinned: false,
        isOnline: true,
        consentStatus: 'verified',
        isLocked: false,
        targetLearnerId: 'learner-aarav',
        targetLearnerName: 'Aarav Sharma',
        avatarType: 'parent_online',
        avatarBadge: 'online',
      ),
      SpecialistConversationItem(
        id: 'group_sofia',
        conversationType: 'group',
        category: 'teams',
        title: 'Sofia\'s Support Circle',
        subtitle: 'Guardian Consent Pending',
        roles: ['Parent', 'Teacher', 'Specialist'],
        lastMessageSender: null,
        lastMessageText: 'Audio turns and session notes locked until guardian sign-off.',
        lastMessageTime: 'Oct 15',
        unreadCount: 0,
        isPinned: false,
        isOnline: false,
        consentStatus: 'pending',
        isLocked: true,
        lockReason: 'Audio turns and session notes locked until guardian sign-off.',
        targetLearnerId: 'learner-sofia',
        targetLearnerName: 'Sofia Patel',
        avatarType: 'locked_child',
        avatarBadge: 'locked',
      ),
      SpecialistConversationItem(
        id: 'direct_teacher_davies',
        conversationType: 'direct',
        category: 'learners',
        title: 'Mrs. Eleanor Davies',
        subtitle: 'Classroom Educator · Oakridge Elementary',
        roles: ['Teacher'],
        lastMessageSender: null,
        lastMessageText: 'Shared classroom reading observations and notes.',
        lastMessageTime: 'Oct 12',
        unreadCount: 0,
        isPinned: false,
        isOnline: false,
        consentStatus: 'verified',
        isLocked: false,
        targetLearnerId: 'learner-aarav',
        targetLearnerName: 'Aarav Sharma',
        avatarType: 'educator',
        avatarBadge: 'book',
      ),
    ];

    var result = list;
    if (filter != null && filter.isNotEmpty && filter.toLowerCase() != 'all') {
      final f = filter.toLowerCase();
      if (f == 'unread') {
        result = result.where((c) => c.unreadCount > 0).toList();
      } else if (f == 'learners') {
        result = result.where((c) => c.category == 'learners' || c.conversationType == 'direct').toList();
      } else if (f == 'teams') {
        result = result.where((c) => c.category == 'teams' || c.conversationType == 'group').toList();
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.subtitle.toLowerCase().contains(q) ||
            c.lastMessageText.toLowerCase().contains(q) ||
            (c.targetLearnerName != null && c.targetLearnerName!.toLowerCase().contains(q)) ||
            (c.lastMessageSender != null && c.lastMessageSender!.toLowerCase().contains(q));
      }).toList();
    }

    return result;
  }

  static final Map<String, List<ChatMessageItem>> _inMemoryMessages = {};

  @override
  Future<List<ChatMessageItem>> getConversationMessages(String conversationId) async {
    try {
      final uri = ApiEndpoints.specialistConversationMessages(conversationId);
      final response = await _apiClient.get(uri);
      if (response is List && response.isNotEmpty) {
        return response
            .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // In demo/offline mode, fall back to Stitch thread
    }
    return _getFallbackChatMessages(conversationId);
  }

  @override
  Future<ChatMessageItem> sendConversationMessage(
    String conversationId,
    String content, {
    String? attachmentId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message content cannot be empty.');
    }

    try {
      final uri = ApiEndpoints.specialistConversationMessages(conversationId);
      final body = <String, dynamic>{
        'content': trimmed,
        'attachment_id': ?attachmentId,
      };
      final response = await _apiClient.post(uri, body: body);
      if (response is Map<String, dynamic>) {
        final item = ChatMessageItem.fromJson(response);
        // Also cache locally
        _inMemoryMessages.putIfAbsent(conversationId, () => _getDefaultStitchMessages(conversationId)).add(item);
        return item;
      }
    } catch (_) {
      // In demo/offline mode, simulate locally
    }

    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';

    final localMsg = ChatMessageItem(
      id: 'local_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'specialist_local',
      senderName: 'You (Specialist)',
      senderRole: 'specialist',
      senderRoleLabel: 'You (Specialist)',
      content: trimmed,
      timestamp: timeStr,
      dateGroup: 'Today',
      isSelf: true,
      deliveryStatus: 'delivered',
      createdAt: now,
    );

    final list = _inMemoryMessages.putIfAbsent(conversationId, () => _getDefaultStitchMessages(conversationId));
    list.add(localMsg);
    return localMsg;
  }

  List<ChatMessageItem> _getFallbackChatMessages(String conversationId) {
    if (_inMemoryMessages.containsKey(conversationId)) {
      return List<ChatMessageItem>.from(_inMemoryMessages[conversationId]!);
    }
    final initial = _getDefaultStitchMessages(conversationId);
    _inMemoryMessages[conversationId] = List<ChatMessageItem>.from(initial);
    return initial;
  }

  List<ChatMessageItem> _getDefaultStitchMessages(String conversationId) {
    if (conversationId.contains('sofia')) {
      return [
        const ChatMessageItem(
          id: 'sofia_notice_1',
          conversationId: 'group_sofia',
          senderId: 'system',
          senderName: 'System Notice',
          senderRole: 'system',
          senderRoleLabel: 'System',
          content: 'Audio turns and session notes locked until guardian sign-off.',
          timestamp: 'Oct 15',
          dateGroup: 'Oct 15',
          isSelf: false,
          deliveryStatus: 'delivered',
        ),
      ];
    }

    if (conversationId.contains('maya')) {
      return [
        const ChatMessageItem(
          id: 'maya_msg_1',
          conversationId: 'group_maya',
          senderId: 'teacher_david',
          senderName: 'David W.',
          senderRole: 'teacher',
          senderRoleLabel: 'Teacher',
          avatarInitials: 'DW',
          content: 'Next week\'s fluency review is ready.',
          timestamp: 'Yesterday',
          dateGroup: 'Yesterday',
          isSelf: false,
          deliveryStatus: 'delivered',
        ),
      ];
    }

    // Default primary Stitch conversation thread (Aarav Sharma circle)
    return [
      // 1. Priya Mehta (Parent) - Yesterday
      const ChatMessageItem(
        id: 'msg_stitch_1',
        conversationId: 'group_aarav',
        senderId: 'parent_priya',
        senderName: 'Priya Mehta',
        senderRole: 'parent',
        senderRoleLabel: 'Parent',
        avatarInitials: 'PM',
        content:
            'Good morning Dr. Maya! Aarav really enjoyed the phonics card game yesterday. He was practicing the /r/ blends during bedtime reading without any prompting! 🪅',
        timestamp: '10:38 AM',
        dateGroup: 'Yesterday',
        isSelf: false,
        deliveryStatus: 'delivered',
      ),
      // 2. Mrs. Davies (Teacher) - Yesterday
      const ChatMessageItem(
        id: 'msg_stitch_2',
        conversationId: 'group_aarav',
        senderId: 'teacher_davies',
        senderName: 'Mrs. Davies',
        senderRole: 'teacher',
        senderRoleLabel: 'Teacher • Oakridge',
        avatarInitials: 'ED',
        content:
            'I noticed the same in class today during reading circle! He was eager to raise his hand. Should we reinforce the same syllable cards this Thursday?',
        timestamp: '10:41 AM',
        dateGroup: 'Yesterday',
        isSelf: false,
        deliveryStatus: 'delivered',
      ),
      // 3. You (Specialist) - Today (with Attachment)
      const ChatMessageItem(
        id: 'msg_stitch_3',
        conversationId: 'group_aarav',
        senderId: 'specialist_self',
        senderName: 'You (Specialist)',
        senderRole: 'specialist',
        senderRoleLabel: 'You (Specialist)',
        avatarInitials: 'MS',
        content:
            'That is wonderful progress! Yes Eleanor, continuing with two-syllable /r/ clusters will build strong retention. I\'ve attached the tailored card set we used in our live session.',
        timestamp: '10:45 AM',
        dateGroup: 'Today',
        isSelf: true,
        deliveryStatus: 'delivered',
        attachment: ChatMessageAttachmentItem(
          id: 'att_phoneme_cards',
          filename: 'Phoneme_Pacing_Cards.pdf',
          fileSizeLabel: '2.4 MB',
          fileType: 'pdf',
          categoryLabel: 'Guided Practice',
          downloadUrl: '/api/v1/specialist/attachments/att_phoneme_cards',
        ),
      ),
      // 4. Priya Mehta (Parent) - Today
      const ChatMessageItem(
        id: 'msg_stitch_4',
        conversationId: 'group_aarav',
        senderId: 'parent_priya',
        senderName: 'Priya Mehta',
        senderRole: 'parent',
        senderRoleLabel: null,
        avatarInitials: 'PM',
        content:
            'Downloaded! Will practice this evening before our 10:30 AM session tomorrow. ✨',
        timestamp: '10:48 AM',
        dateGroup: 'Today',
        isSelf: false,
        deliveryStatus: 'delivered',
      ),
    ];
  }
}
