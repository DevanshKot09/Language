import 'package:lingua_ai/core/network/api_client.dart';
import 'package:lingua_ai/core/network/api_endpoints.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';

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

  // Specialist Session Summary & Notes
  Future<SpecialistSessionSummaryModel> saveSessionSummary(SpecialistSessionSummaryModel summary);
  Future<SpecialistSessionSummaryModel> getSessionSummary({String? sessionId, String? learnerId});

  // Specialist Profile, Notifications & Consent Circles
  Future<SpecialistProfileModel> getSpecialistProfile();
  Future<SpecialistProfileModel> updateSpecialistProfile(SpecialistProfileModel profile);
  Future<List<SpecialistNotificationModel>> getSpecialistNotifications({String? category});
  Future<void> markSpecialistNotificationRead(String id);
  Future<void> markAllSpecialistNotificationsRead();
  Future<List<SpecialistConsentCircleModel>> getSpecialistConsentCircles();
  Future<SpecialistConsentCircleModel> updateConsentCircleScope(String circleId, String scopeKey, bool shared);

  // Specialist Availability, Verification, Help & Settings
  Future<SpecialistAvailabilityModel> getSpecialistAvailability();
  Future<SpecialistAvailabilityModel> updateSpecialistAvailability(SpecialistAvailabilityModel availability);
  Future<SpecialistVerificationModel> getSpecialistVerification();
  Future<SpecialistHelpModel> getSpecialistHelp();
  Future<void> reportSpecialistProblem(String category, String description);
  Future<SpecialistSettingsModel> getSpecialistSettings();
  Future<SpecialistSettingsModel> updateSpecialistSettings(SpecialistSettingsModel settings);
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

  static final Map<String, SpecialistSessionSummaryModel> _inMemorySummaries = {};

  @override
  Future<SpecialistSessionSummaryModel> saveSessionSummary(SpecialistSessionSummaryModel summary) async {
    final trimmedNotes = summary.notes.trim();
    if (trimmedNotes.isEmpty) {
      throw Exception('Session notes cannot be empty. Please record key observations from this session.');
    }

    try {
      final body = summary.toJson();
      final response = await _apiClient.post(
        ApiEndpoints.specialistSessionSummary,
        body: body,
      );
      if (response is Map<String, dynamic>) {
        final saved = SpecialistSessionSummaryModel.fromJson(response);
        _inMemorySummaries[saved.id] = saved;
        if (saved.sessionId != null) _inMemorySummaries[saved.sessionId!] = saved;
        _inMemorySummaries[saved.learnerId] = saved;
        return saved;
      }
    } catch (_) {
      // In demo/test or offline mode, simulate persistence
    }

    final localId = 'summary_${DateTime.now().millisecondsSinceEpoch}';
    final saved = summary.copyWith(
      id: summary.id.startsWith('summary_') && summary.id != 'summary_default' ? summary.id : localId,
      status: 'completed',
      createdAt: DateTime.now(),
      disclaimer: 'Educational non-diagnostic learning support summary.',
    );
    _inMemorySummaries[saved.id] = saved;
    if (saved.sessionId != null) _inMemorySummaries[saved.sessionId!] = saved;
    _inMemorySummaries[saved.learnerId] = saved;
    return saved;
  }

  @override
  Future<SpecialistSessionSummaryModel> getSessionSummary({String? sessionId, String? learnerId}) async {
    try {
      if (sessionId != null) {
        final response = await _apiClient.get(ApiEndpoints.specialistSessionSummaryDetail(sessionId));
        if (response is Map<String, dynamic>) {
          return SpecialistSessionSummaryModel.fromJson(response);
        }
      } else if (learnerId != null) {
        final response = await _apiClient.get(ApiEndpoints.specialistLearnerLatestSummary(learnerId));
        if (response is Map<String, dynamic>) {
          return SpecialistSessionSummaryModel.fromJson(response);
        }
      }
    } catch (_) {
      // Fall through to memory / default Stitch data
    }

    if (sessionId != null && _inMemorySummaries.containsKey(sessionId)) {
      return _inMemorySummaries[sessionId]!;
    }
    if (learnerId != null && _inMemorySummaries.containsKey(learnerId)) {
      return _inMemorySummaries[learnerId]!;
    }

    // Default Stitch initial session state (Aarav Mehta)
    return SpecialistSessionSummaryModel(
      id: 'summary_aarav_default',
      sessionId: sessionId ?? 'sess_live_001',
      learnerId: learnerId ?? 'lr-1',
      learnerName: learnerId != null && learnerId.contains('maya') ? 'Maya Sharma' : 'Aarav Mehta',
      learnerAgeBand: learnerId != null && learnerId.contains('maya') ? 'Adult' : 'Child • 10 yrs',
      sessionDate: 'Today, Oct 17',
      sessionTime: '10:30 – 11:02 AM',
      sessionDurationMinutes: 31,
      sessionType: '1-to-1 Live Support',
      targetFocus: '/r/ Blends',
      cardsCompleted: 8,
      pacingRhythmPercentage: 88,
      audioReflectionsCount: 1,
      workingAreas: const [
        'Phonics & Blends',
        'Speaking & Pacing',
        'Reading Aloud',
      ],
      notes: '',
      outcome: 'great_progress',
      nextPracticeFocus: 'Consonant Clusters (/rk/, /st/) in 2-syllable words',
      nextPracticeDescription: 'Assigned to Aarav\'s home practice deck with playful tactile rewards.',
      followUpActions: const [
        'Send tailored /r/ practice cards to Parent',
        'Share session highlight with Teacher',
      ],
      nextScheduledSessionDate: 'Friday, Oct 25 • 10:30 AM',
      nextScheduledSessionDescription: 'Practice Check-in • 20 min live video',
      status: 'completed',
    );
  }

  static SpecialistProfileModel? _inMemoryProfile;
  static List<SpecialistNotificationModel>? _inMemoryNotifications;
  static List<SpecialistConsentCircleModel>? _inMemoryConsentCircles;

  @override
  Future<SpecialistProfileModel> getSpecialistProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistProfile);
      if (response is Map<String, dynamic>) {
        final profile = SpecialistProfileModel.fromJson(response);
        _inMemoryProfile = profile;
        return profile;
      }
    } catch (_) {}

    return _inMemoryProfile ??= SpecialistProfileModel.defaultProfile();
  }

  @override
  Future<SpecialistProfileModel> updateSpecialistProfile(SpecialistProfileModel profile) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.specialistProfile,
        body: profile.toJson(),
      );
      if (response is Map<String, dynamic>) {
        final updated = SpecialistProfileModel.fromJson(response);
        _inMemoryProfile = updated;
        return updated;
      }
    } catch (_) {}

    _inMemoryProfile = profile;
    return profile;
  }

  @override
  Future<List<SpecialistNotificationModel>> getSpecialistNotifications({String? category}) async {
    try {
      final endpoint = category != null && category != 'All'
          ? '${ApiEndpoints.specialistNotifications}?category=${category.toLowerCase()}'
          : ApiEndpoints.specialistNotifications;
      final response = await _apiClient.get(endpoint);
      if (response is Map<String, dynamic> && response['notifications'] is List) {
        final list = (response['notifications'] as List)
            .map((e) => SpecialistNotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _inMemoryNotifications = list;
        return list;
      }
    } catch (_) {}

    _inMemoryNotifications ??= SpecialistNotificationModel.defaultNotifications();
    if (category != null && category != 'All') {
      return _inMemoryNotifications!
          .where((n) => n.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    return _inMemoryNotifications!;
  }

  @override
  Future<void> markSpecialistNotificationRead(String id) async {
    try {
      await _apiClient.put(ApiEndpoints.specialistNotificationRead(id));
    } catch (_) {}

    if (_inMemoryNotifications != null) {
      _inMemoryNotifications = _inMemoryNotifications!.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
    }
  }

  @override
  Future<void> markAllSpecialistNotificationsRead() async {
    try {
      await _apiClient.post(ApiEndpoints.specialistNotificationsMarkAllRead);
    } catch (_) {}

    if (_inMemoryNotifications != null) {
      _inMemoryNotifications = _inMemoryNotifications!.map((n) => n.copyWith(isRead: true)).toList();
    }
  }

  @override
  Future<List<SpecialistConsentCircleModel>> getSpecialistConsentCircles() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistConsentCircles);
      if (response is Map<String, dynamic> && response['circles'] is List) {
        final list = (response['circles'] as List)
            .map((e) => SpecialistConsentCircleModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _inMemoryConsentCircles = list;
        return list;
      }
    } catch (_) {}

    return _inMemoryConsentCircles ??= SpecialistConsentCircleModel.defaultCircles();
  }

  @override
  Future<SpecialistConsentCircleModel> updateConsentCircleScope(
    String circleId,
    String scopeKey,
    bool shared,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.specialistConsentCircleScope(circleId, scopeKey),
        body: {'shared': shared},
      );
      if (response is Map<String, dynamic>) {
        final updated = SpecialistConsentCircleModel.fromJson(response);
        if (_inMemoryConsentCircles != null) {
          final idx = _inMemoryConsentCircles!.indexWhere((c) => c.id == circleId);
          if (idx != -1) {
            _inMemoryConsentCircles![idx] = updated;
          }
        }
        return updated;
      }
    } catch (_) {}

    _inMemoryConsentCircles ??= SpecialistConsentCircleModel.defaultCircles();
    final circleIdx = _inMemoryConsentCircles!.indexWhere((c) => c.id == circleId);
    if (circleIdx != -1) {
      final target = _inMemoryConsentCircles![circleIdx];
      final updatedScopes = target.permissionScopes.map((s) {
        if (s.key == scopeKey) {
          return s.copyWith(isShared: shared);
        }
        return s;
      }).toList();
      final updatedCircle = target.copyWith(permissionScopes: updatedScopes);
      _inMemoryConsentCircles![circleIdx] = updatedCircle;
      return updatedCircle;
    }
    throw Exception('Consent circle $circleId not found');
  }

  SpecialistAvailabilityModel? _inMemoryAvailability;
  SpecialistVerificationModel? _inMemoryVerification;
  SpecialistHelpModel? _inMemoryHelp;

  @override
  Future<SpecialistAvailabilityModel> getSpecialistAvailability() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistAvailability);
      if (response is Map<String, dynamic>) {
        final model = SpecialistAvailabilityModel.fromJson(response);
        _inMemoryAvailability = model;
        return model;
      }
    } catch (_) {}

    return _inMemoryAvailability ??= const SpecialistAvailabilityModel(
      specialistName: 'Dr. Maya Lin, M.S. CCC-SLP',
      specialistTitle: 'Pediatric Speech & Phoneme Coaching',
      specialistBadge: 'LINGUA SPECIALIST • Active Caseload',
      availableForSessions: true,
      timezone: 'Pacific Time (GMT-7)',
      sessionDurationMinutes: 45,
      bufferMinutes: 15,
      dailySessionCap: 5,
      advanceNotice: '24h Notice',
      days: [
        SpecialistDayAvailabilityModel(
          dayKey: 'monday',
          dayLabel: 'Monday',
          initial: 'M',
          isEnabled: true,
          subtitle: '2 Slots Active',
          slots: [
            SpecialistTimeSlotModel(id: 'mon_1', timeRange: '9:00 AM – 12:00 PM', iconType: 'sun'),
            SpecialistTimeSlotModel(id: 'mon_2', timeRange: '1:30 PM – 5:00 PM', iconType: 'sparkle'),
          ],
        ),
        SpecialistDayAvailabilityModel(
          dayKey: 'tuesday',
          dayLabel: 'Tuesday',
          initial: 'T',
          isEnabled: true,
          subtitle: '1 Slot Active',
          slots: [
            SpecialistTimeSlotModel(id: 'tue_1', timeRange: '10:00 AM – 3:30 PM', iconType: 'sun'),
          ],
        ),
        SpecialistDayAvailabilityModel(
          dayKey: 'wednesday',
          dayLabel: 'Wednesday',
          initial: 'W',
          isEnabled: true,
          subtitle: '2 Slots Active',
          slots: [
            SpecialistTimeSlotModel(id: 'wed_1', timeRange: '9:00 AM – 12:00 PM', iconType: 'sun'),
            SpecialistTimeSlotModel(id: 'wed_2', timeRange: '1:30 PM – 4:30 PM', iconType: 'sparkle'),
          ],
        ),
        SpecialistDayAvailabilityModel(
          dayKey: 'thursday_friday',
          dayLabel: 'Thursday & Friday',
          initial: 'TF',
          isEnabled: true,
          subtitle: 'Standard Afternoon blocks (1:00 - 5:00 PM)',
          slots: [
            SpecialistTimeSlotModel(id: 'tf_1', timeRange: '1:00 PM – 5:00 PM', iconType: 'sun'),
          ],
        ),
        SpecialistDayAvailabilityModel(
          dayKey: 'saturday',
          dayLabel: 'Saturday',
          initial: 'S',
          isEnabled: false,
          subtitle: 'Day off • Dedicated rest & prep',
          slots: [],
        ),
        SpecialistDayAvailabilityModel(
          dayKey: 'sunday',
          dayLabel: 'Sunday',
          initial: 'S',
          isEnabled: false,
          subtitle: 'Day off • Family & recharge',
          slots: [],
        ),
      ],
    );
  }

  @override
  Future<SpecialistAvailabilityModel> updateSpecialistAvailability(
    SpecialistAvailabilityModel availability,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.specialistAvailability,
        body: availability.toJson(),
      );
      if (response is Map<String, dynamic>) {
        final updated = SpecialistAvailabilityModel.fromJson(response);
        _inMemoryAvailability = updated;
        return updated;
      }
    } catch (_) {}

    _inMemoryAvailability = availability;
    return availability;
  }

  @override
  Future<SpecialistVerificationModel> getSpecialistVerification() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistVerification);
      if (response is Map<String, dynamic>) {
        final model = SpecialistVerificationModel.fromJson(response);
        _inMemoryVerification = model;
        return model;
      }
    } catch (_) {}

    return _inMemoryVerification ??= const SpecialistVerificationModel(
      verificationStatus: 'verified',
      statusBadge: 'PROFILE VERIFIED',
      headline: 'Your profile is verified',
      description:
          'Your specialist credentials and child-safety background checks are confirmed. Families and schools can discover your profile and book sessions.',
      verificationDateText: 'Verified Oct 14, 2024 • Next check: Oct 2025',
      milestonesCompleted: 5,
      milestonesTotal: 5,
      specialistName: 'Maya Reynolds, M.S.',
      specialistInitials: 'MR',
      specialistRoleSubtitle: 'Learning Support Specialist (CCC-SLP)',
      experienceText: '8+ Yrs Pediatric',
      languagesText: 'English, Spanish',
      approvedDomains: [
        'Reading Fluency',
        'Speech & Pacing',
        'Phonics & Spelling',
        'Vocabulary Growth',
      ],
      milestones: [
        SpecialistMilestoneItemModel(key: 'profile', label: 'Profile', isCompleted: true, isCurrent: false),
        SpecialistMilestoneItemModel(key: 'details', label: 'Details', isCompleted: true, isCurrent: false),
        SpecialistMilestoneItemModel(key: 'degrees', label: 'Degrees', isCompleted: true, isCurrent: false),
        SpecialistMilestoneItemModel(key: 'review', label: 'Review', isCompleted: true, isCurrent: false),
        SpecialistMilestoneItemModel(key: 'badge', label: 'Badge', isCompleted: true, isCurrent: true),
      ],
      verifiedDocuments: [
        SpecialistVerifiedDocumentModel(
          id: 'doc_degree',
          title: 'M.S. in Speech & Hearing Sciences',
          subtitle: 'University of Washington • Conferred 2016',
          statusLabel: 'Approved',
          iconType: 'grad_cap',
          isApproved: true,
        ),
        SpecialistVerifiedDocumentModel(
          id: 'doc_cert',
          title: 'Clinical Competence Certification (CCC-SLP)',
          subtitle: 'National Board Validated • Active Good Standing',
          statusLabel: 'Approved',
          iconType: 'certificate',
          isApproved: true,
        ),
        SpecialistVerifiedDocumentModel(
          id: 'doc_clearance',
          title: 'Child-Safe & Background Clearance',
          subtitle: 'Comprehensive Youth Safety Check • Passed',
          statusLabel: 'Cleared',
          iconType: 'shield',
          isApproved: true,
        ),
      ],
      complianceNotice: 'Encrypted • FERPA Compliant',
    );
  }

  @override
  Future<SpecialistHelpModel> getSpecialistHelp() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistHelp);
      if (response is Map<String, dynamic>) {
        final model = SpecialistHelpModel.fromJson(response);
        _inMemoryHelp = model;
        return model;
      }
    } catch (_) {}

    return _inMemoryHelp ??= const SpecialistHelpModel(
      categories: [
        HelpCategoryItemModel(id: 'account', title: 'Account', subtitle: 'Profile & cred...', iconType: 'person', color: 'purple'),
        HelpCategoryItemModel(id: 'sessions', title: 'Sessions', subtitle: 'Rooms, audio ...', iconType: 'video', color: 'teal'),
        HelpCategoryItemModel(id: 'learners', title: 'Learners', subtitle: 'Rosters & spe...', iconType: 'grad_cap', color: 'amber'),
        HelpCategoryItemModel(id: 'messages', title: 'Messages', subtitle: 'Parent & lear...', iconType: 'chat', color: 'purple'),
        HelpCategoryItemModel(id: 'consent', title: 'Consent', subtitle: 'Guardian per...', iconType: 'shield', color: 'mint'),
        HelpCategoryItemModel(id: 'verification', title: 'Verification', subtitle: 'Specialist sta...', iconType: 'badge', color: 'teal'),
        HelpCategoryItemModel(id: 'availability', title: 'Availability', subtitle: 'Weekly slots ...', iconType: 'clock', color: 'lilac'),
        HelpCategoryItemModel(id: 'alerts', title: 'Alerts', subtitle: 'Reminders & ...', iconType: 'bell', color: 'purple'),
      ],
      faqs: [
        FaqItemModel(
          id: 'faq_availability',
          question: 'How do I update my weekly availability hours?',
          answer:
              'Navigate to Availability Settings to toggle individual days, customize time slots, and set buffer intervals between sessions. Changes apply immediately to new parent booking requests.',
        ),
        FaqItemModel(
          id: 'faq_consent',
          question: 'How does learner guardian consent work?',
          answer:
              'Each learner profile is managed via a Permission-Based Consent Circle. Guardians explicitly grant permissions for audio review, progress milestones, and reports. If consent is revoked, sensitive media streams lock automatically.',
        ),
        FaqItemModel(
          id: 'faq_session',
          question: 'How do I start a live learning session?',
          answer:
              'Open your Schedule tab or tap on an active appointment. Tap \'Start Live Session\' to launch the interactive coaching room with real-time phoneme exercises and engagement telemetry.',
        ),
        FaqItemModel(
          id: 'faq_credentials',
          question: 'How do I edit my professional qualifications?',
          answer:
              'Open Specialist Profile, select Edit Profile, and update your specialization, experience, or degrees. New credentials undergo automatic compliance verification within 24 hours.',
        ),
      ],
      supportDeskHours: 'Mon–Fri, 8 AM–8 PM EST',
      avgResponseTime: '< 15 mins during desk hours',
      systemStatus: 'All Systems Operational',
      appVersion: 'Lingua Specialist v2.4.1 (Build 842)',
    );
  }

  @override
  Future<void> reportSpecialistProblem(String category, String description) async {
    try {
      await _apiClient.post(
        ApiEndpoints.specialistHelpReportProblem,
        body: {'category': category, 'description': description},
      );
    } catch (_) {}
  }

  SpecialistSettingsModel? _inMemorySettings;

  @override
  Future<SpecialistSettingsModel> getSpecialistSettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.specialistSettings);
      if (response is Map<String, dynamic>) {
        final model = SpecialistSettingsModel.fromJson(response);
        _inMemorySettings = model;
        return model;
      }
    } catch (_) {}

    return _inMemorySettings ??= const SpecialistSettingsModel();
  }

  @override
  Future<SpecialistSettingsModel> updateSpecialistSettings(
      SpecialistSettingsModel settings) async {
    _inMemorySettings = settings;
    try {
      final response = await _apiClient.put(
        ApiEndpoints.specialistSettings,
        body: settings.toJson(),
      );
      if (response is Map<String, dynamic>) {
        _inMemorySettings = SpecialistSettingsModel.fromJson(response);
      }
    } catch (_) {}
    return _inMemorySettings!;
  }
}


