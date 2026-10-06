import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/network_provider.dart';
import 'package:lingua_ai/features/collaboration/data/collaboration_repository.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';

final collaborationRepositoryProvider = Provider<ICollaborationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CollaborationRepository(apiClient);
});

// Relationships and Invitations
final relationshipsProvider = FutureProvider<List<RelationshipItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getRelationships();
});

final invitationsProvider = FutureProvider<List<InvitationItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getInvitations();
});

// Specialist Workspace Providers
final specialistCaseloadProvider = FutureProvider<List<SpecialistCaseloadItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getSpecialistCaseload();
});

final specialistLearnerDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, learnerId) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getSpecialistLearnerDetail(learnerId);
});

final availableSpecialistsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getAvailableSpecialists();
});

/// Specialist schedule sessions.
///
/// The FastAPI backend does not yet expose a scheduling/appointments
/// endpoint, so this resolves to an empty list and the Schedule screen
/// shows its "schedule is clear" state. When the endpoint is added, wire a
/// repository method here; the screen already renders
/// [SpecialistScheduleSession] data.
final specialistScheduleProvider = FutureProvider<List<SpecialistScheduleSession>>((ref) async {
  return const <SpecialistScheduleSession>[];
});

// Reports Providers
final reportsProvider = FutureProvider.family<List<ReportItem>, String?>((ref, learnerId) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getReports(learnerId: learnerId);
});

/// Query parameter wrapper for specialist conversations filtering & searching.
class SpecialistConversationsQuery {
  final String? filter;
  final String? search;

  const SpecialistConversationsQuery({this.filter, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialistConversationsQuery &&
          other.filter == filter &&
          other.search == search;

  @override
  int get hashCode => Object.hash(filter, search);
}

/// Specialist support and collaboration conversations provider.
final specialistConversationsProvider = FutureProvider.family<List<SpecialistConversationItem>, SpecialistConversationsQuery>((ref, query) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getSpecialistConversations(filter: query.filter, search: query.search);
});

/// State for the conversation chat thread.
class ChatThreadState {
  final List<ChatMessageItem> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const ChatThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  ChatThreadState copyWith({
    List<ChatMessageItem>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

/// State notifier managing conversation thread message loading, sending, optimistic states, and retries.
class ChatThreadNotifier extends Notifier<ChatThreadState> {
  final String conversationId;

  ChatThreadNotifier(this.conversationId);

  @override
  ChatThreadState build() {
    Future.microtask(() => loadMessages());
    return const ChatThreadState(isLoading: true);
  }

  ICollaborationRepository get _repository => ref.read(collaborationRepositoryProvider);

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final msgs = await _repository.getConversationMessages(conversationId);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> sendMessage(String text, {String? attachmentId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Optimistic pending message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';

    final pendingMsg = ChatMessageItem(
      id: tempId,
      conversationId: conversationId,
      senderId: 'specialist_self',
      senderName: 'You (Specialist)',
      senderRole: 'specialist',
      senderRoleLabel: 'You (Specialist)',
      content: trimmed,
      timestamp: timeStr,
      dateGroup: 'Today',
      isSelf: true,
      deliveryStatus: 'sending',
    );

    state = state.copyWith(
      messages: [...state.messages, pendingMsg],
      isSending: true,
    );

    try {
      final sent = await _repository.sendConversationMessage(
        conversationId,
        trimmed,
        attachmentId: attachmentId,
      );

      // Replace pending message with confirmed sent message
      final updated = state.messages.map((m) => m.id == tempId ? sent : m).toList();
      state = state.copyWith(messages: updated, isSending: false);
      return true;
    } catch (e) {
      // Mark as failed with retry
      final failed = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(deliveryStatus: 'failed');
        }
        return m;
      }).toList();
      state = state.copyWith(messages: failed, isSending: false);
      return false;
    }
  }

  Future<void> retryMessage(String messageId) async {
    final failedMsg = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );

    // Remove failed and resend
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
    await sendMessage(failedMsg.content);
  }
}

final chatThreadNotifierProvider =
    NotifierProvider.family<ChatThreadNotifier, ChatThreadState, String>(
  (conversationId) => ChatThreadNotifier(conversationId),
);

/// Query parameter wrapper for resolving a session summary.
class SessionSummaryQuery {
  final String? sessionId;
  final String? learnerId;
  final dynamic initialArg;

  const SessionSummaryQuery({
    this.sessionId,
    this.learnerId,
    this.initialArg,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionSummaryQuery &&
          other.sessionId == sessionId &&
          other.learnerId == learnerId;

  @override
  int get hashCode => Object.hash(sessionId, learnerId);
}

/// State for the Specialist Session Summary & Notes screen.
class SessionSummaryState {
  final SpecialistSessionSummaryModel summary;
  final bool isLoading;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;
  final bool hasUnsavedChanges;

  const SessionSummaryState({
    required this.summary,
    this.isLoading = false,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
    this.hasUnsavedChanges = false,
  });

  SessionSummaryState copyWith({
    SpecialistSessionSummaryModel? summary,
    bool? isLoading,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    bool? hasUnsavedChanges,
  }) {
    return SessionSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

/// State notifier managing session summary form data, auto-save status,
/// validation, and FastAPI backend persistence.
class SessionSummaryNotifier extends Notifier<SessionSummaryState> {
  final SessionSummaryQuery query;

  SessionSummaryNotifier(this.query);

  @override
  SessionSummaryState build() {
    // Resolve initial baseline model from arg or default
    final initial = _resolveInitial(query);
    Future.microtask(() => _loadLatest(query));
    return SessionSummaryState(summary: initial, isLoading: false);
  }

  ICollaborationRepository get _repository => ref.read(collaborationRepositoryProvider);

  SpecialistSessionSummaryModel _resolveInitial(SessionSummaryQuery query) {
    final raw = query.initialArg;
    if (raw is SpecialistSessionSummaryModel) {
      return raw;
    } else if (raw is SpecialistScheduleSession) {
      return SpecialistSessionSummaryModel(
        id: 'summary_${raw.id}',
        sessionId: raw.id,
        learnerId: raw.learnerId,
        learnerName: raw.learnerName,
        learnerAgeBand: raw.ageBand == 'child' ? 'Child • 10 yrs' : raw.ageBand,
        sessionDate: 'Today, Oct 17',
        sessionTime: '10:30 – 11:02 AM',
        sessionDurationMinutes: raw.durationMinutes,
        sessionType: raw.sessionType,
        targetFocus: raw.focus ?? '/r/ Blends',
      );
    } else if (raw is SpecialistCaseloadItem) {
      return SpecialistSessionSummaryModel(
        id: 'summary_${raw.learnerId}',
        learnerId: raw.learnerId,
        learnerName: raw.displayName,
        learnerAgeBand: raw.ageBand == 'teen' ? 'Child • 10 yrs' : raw.ageBand,
        sessionDate: 'Today, Oct 17',
        sessionTime: '10:30 – 11:02 AM',
        sessionDurationMinutes: 31,
        sessionType: '1-to-1 Live Support',
        targetFocus: raw.supportFocus.replaceAll('_', ' '),
      );
    } else if (raw is String && raw.isNotEmpty) {
      final isMaya = raw.toLowerCase().contains('maya');
      return SpecialistSessionSummaryModel(
        id: 'summary_$raw',
        learnerId: raw,
        learnerName: isMaya ? 'Maya Sharma' : 'Aarav Mehta',
        learnerAgeBand: isMaya ? 'Adult' : 'Child • 10 yrs',
        sessionDate: 'Today, Oct 17',
        sessionTime: '10:30 – 11:02 AM',
        sessionDurationMinutes: 31,
        sessionType: '1-to-1 Live Support',
        targetFocus: isMaya ? 'Phonological Decoding' : '/r/ Blends',
      );
    }

    return const SpecialistSessionSummaryModel(
      id: 'summary_aarav_default',
      sessionId: 'sess_live_001',
      learnerId: 'lr-1',
      learnerName: 'Aarav Mehta',
      learnerAgeBand: 'Child • 10 yrs',
      sessionDate: 'Today, Oct 17',
      sessionTime: '10:30 – 11:02 AM',
      sessionDurationMinutes: 31,
      sessionType: '1-to-1 Live Support',
      targetFocus: '/r/ Blends',
      cardsCompleted: 8,
      pacingRhythmPercentage: 88,
      audioReflectionsCount: 1,
      workingAreas: [
        'Phonics & Blends',
        'Speaking & Pacing',
        'Reading Aloud',
      ],
      notes: '',
      outcome: 'great_progress',
      nextPracticeFocus: 'Consonant Clusters (/rk/, /st/) in 2-syllable words',
      nextPracticeDescription: 'Assigned to Aarav\'s home practice deck with playful tactile rewards.',
      followUpActions: [
        'Send tailored /r/ practice cards to Parent',
        'Share session highlight with Teacher',
      ],
      nextScheduledSessionDate: 'Friday, Oct 25 • 10:30 AM',
      nextScheduledSessionDescription: 'Practice Check-in • 20 min live video',
    );
  }

  Future<void> _loadLatest(SessionSummaryQuery query) async {
    try {
      final remote = await _repository.getSessionSummary(
        sessionId: query.sessionId,
        learnerId: query.learnerId,
      );
      // Keep entered notes if user already started typing
      final currentNotes = state.summary.notes;
      state = state.copyWith(
        summary: remote.copyWith(
          notes: currentNotes.isNotEmpty ? currentNotes : remote.notes,
        ),
      );
    } catch (_) {
      // Retain current model
    }
  }

  void toggleWorkingArea(String area) {
    final current = List<String>.from(state.summary.workingAreas);
    if (current.contains(area)) {
      current.remove(area);
    } else {
      current.add(area);
    }
    state = state.copyWith(
      summary: state.summary.copyWith(workingAreas: current),
      hasUnsavedChanges: true,
      isSaved: false,
    );
  }

  void updateNotes(String notes) {
    state = state.copyWith(
      summary: state.summary.copyWith(notes: notes),
      hasUnsavedChanges: true,
      isSaved: false,
    );
  }

  void appendNoteTag(String tag) {
    final cleanTag = tag.startsWith('+ ') ? tag.substring(2).trim() : tag.trim();
    final currentNotes = state.summary.notes;
    final newNotes = currentNotes.isEmpty
        ? cleanTag
        : (currentNotes.endsWith('.') || currentNotes.endsWith('\n')
            ? '$currentNotes $cleanTag'
            : '$currentNotes • $cleanTag');
    updateNotes(newNotes);
  }

  void updateOutcome(String outcome) {
    state = state.copyWith(
      summary: state.summary.copyWith(outcome: outcome),
      hasUnsavedChanges: true,
      isSaved: false,
    );
  }

  void updateNextPracticeFocus(String focus, {String? description}) {
    state = state.copyWith(
      summary: state.summary.copyWith(
        nextPracticeFocus: focus,
        nextPracticeDescription: description ?? state.summary.nextPracticeDescription,
      ),
      hasUnsavedChanges: true,
      isSaved: false,
    );
  }

  void toggleFollowUpAction(String action) {
    final current = List<String>.from(state.summary.followUpActions);
    if (current.contains(action)) {
      current.remove(action);
    } else {
      current.add(action);
    }
    state = state.copyWith(
      summary: state.summary.copyWith(followUpActions: current),
      hasUnsavedChanges: true,
      isSaved: false,
    );
  }

  Future<bool> saveSummary() async {
    final notes = state.summary.notes.trim();
    if (notes.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter session observations and notes before saving.',
        isSaving: false,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final saved = await _repository.saveSessionSummary(state.summary);
      state = state.copyWith(
        summary: saved,
        isSaving: false,
        isSaved: true,
        hasUnsavedChanges: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: "Couldn't save summary. Please verify connection and try again.",
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final sessionSummaryNotifierProvider =
    NotifierProvider.family<SessionSummaryNotifier, SessionSummaryState, SessionSummaryQuery>(
  (query) => SessionSummaryNotifier(query),
);

// =============================================================================
// SPECIALIST PROFILE STATE & NOTIFIER
// =============================================================================

class SpecialistProfileState {
  final SpecialistProfileModel profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isSpecialistView;
  final bool isBioExpanded;

  const SpecialistProfileState({
    required this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSpecialistView = true,
    this.isBioExpanded = false,
  });

  SpecialistProfileState copyWith({
    SpecialistProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isSpecialistView,
    bool? isBioExpanded,
  }) {
    return SpecialistProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSpecialistView: isSpecialistView ?? this.isSpecialistView,
      isBioExpanded: isBioExpanded ?? this.isBioExpanded,
    );
  }
}

class SpecialistProfileNotifier extends Notifier<SpecialistProfileState> {
  @override
  SpecialistProfileState build() {
    Future.microtask(() => loadProfile());
    return SpecialistProfileState(
      profile: SpecialistProfileModel.defaultProfile(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository => ref.read(collaborationRepositoryProvider);

  Future<void> loadProfile() async {
    try {
      final profile = await _repository.getSpecialistProfile();
      state = state.copyWith(profile: profile, isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleViewMode(bool specialistView) {
    state = state.copyWith(isSpecialistView: specialistView);
  }

  void toggleBioExpanded() {
    state = state.copyWith(isBioExpanded: !state.isBioExpanded);
  }

  void updateVisibility(String visibility) {
    final updated = state.profile.copyWith(profileVisibility: visibility);
    state = state.copyWith(profile: updated);
    _repository.updateSpecialistProfile(updated);
  }

  Future<bool> updateProfile(SpecialistProfileModel newProfile) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final saved = await _repository.updateSpecialistProfile(newProfile);
      state = state.copyWith(profile: saved, isSaving: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final specialistProfileNotifierProvider =
    NotifierProvider<SpecialistProfileNotifier, SpecialistProfileState>(
  SpecialistProfileNotifier.new,
);

// =============================================================================
// SPECIALIST NOTIFICATIONS STATE & NOTIFIER
// =============================================================================

class SpecialistNotificationsState {
  final List<SpecialistNotificationModel> notifications;
  final String selectedFilter;
  final bool isLoading;
  final String? errorMessage;

  const SpecialistNotificationsState({
    required this.notifications,
    this.selectedFilter = 'All',
    this.isLoading = false,
    this.errorMessage,
  });

  SpecialistNotificationsState copyWith({
    List<SpecialistNotificationModel>? notifications,
    String? selectedFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SpecialistNotificationsState(
      notifications: notifications ?? this.notifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<SpecialistNotificationModel> get filteredNotifications {
    if (selectedFilter == 'All') return notifications;
    return notifications
        .where((n) => n.category.toLowerCase() == selectedFilter.toLowerCase())
        .toList();
  }

  List<SpecialistNotificationModel> get todayNotifications =>
      filteredNotifications.where((n) => n.isToday).toList();

  List<SpecialistNotificationModel> get earlierNotifications =>
      filteredNotifications.where((n) => !n.isToday).toList();

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class SpecialistNotificationsNotifier extends Notifier<SpecialistNotificationsState> {
  @override
  SpecialistNotificationsState build() {
    Future.microtask(() => loadNotifications());
    return SpecialistNotificationsState(
      notifications: SpecialistNotificationModel.defaultNotifications(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository => ref.read(collaborationRepositoryProvider);

  Future<void> loadNotifications() async {
    try {
      final list = await _repository.getSpecialistNotifications();
      state = state.copyWith(notifications: list, isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
    await _repository.markSpecialistNotificationRead(id);
  }

  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    await _repository.markAllSpecialistNotificationsRead();
  }

  void dismissNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
    _repository.markSpecialistNotificationRead(id);
  }
}

final specialistNotificationsNotifierProvider =
    NotifierProvider<SpecialistNotificationsNotifier, SpecialistNotificationsState>(
  SpecialistNotificationsNotifier.new,
);

// =============================================================================
// SPECIALIST CONSENT CIRCLES STATE & NOTIFIER
// =============================================================================

class SpecialistConsentCirclesState {
  final List<SpecialistConsentCircleModel> circles;
  final bool isLoading;
  final String? errorMessage;
  final String? updatingCircleId;

  const SpecialistConsentCirclesState({
    required this.circles,
    this.isLoading = false,
    this.errorMessage,
    this.updatingCircleId,
  });

  SpecialistConsentCirclesState copyWith({
    List<SpecialistConsentCircleModel>? circles,
    bool? isLoading,
    String? errorMessage,
    String? updatingCircleId,
  }) {
    return SpecialistConsentCirclesState(
      circles: circles ?? this.circles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      updatingCircleId: updatingCircleId,
    );
  }
}

class SpecialistConsentCirclesNotifier extends Notifier<SpecialistConsentCirclesState> {
  @override
  SpecialistConsentCirclesState build() {
    Future.microtask(() => loadCircles());
    return SpecialistConsentCirclesState(
      circles: SpecialistConsentCircleModel.defaultCircles(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository => ref.read(collaborationRepositoryProvider);

  Future<void> loadCircles() async {
    try {
      final list = await _repository.getSpecialistConsentCircles();
      state = state.copyWith(circles: list, isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleScope(String circleId, String scopeKey, bool currentShared) async {
    state = state.copyWith(updatingCircleId: circleId);
    try {
      final updated = await _repository.updateConsentCircleScope(circleId, scopeKey, !currentShared);
      final list = state.circles.map((c) => c.id == circleId ? updated : c).toList();
      state = state.copyWith(circles: list, updatingCircleId: null);
    } catch (e) {
      state = state.copyWith(updatingCircleId: null, errorMessage: e.toString());
    }
  }
}

final specialistConsentCirclesNotifierProvider =
    NotifierProvider<SpecialistConsentCirclesNotifier, SpecialistConsentCirclesState>(
  SpecialistConsentCirclesNotifier.new,
);

// ---------------------------------------------------------------------------
// Screen 1: Availability & Appointment Settings Provider
// ---------------------------------------------------------------------------
class SpecialistAvailabilityState {
  final SpecialistAvailabilityModel availability;
  final bool isLoading;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const SpecialistAvailabilityState({
    required this.availability,
    this.isLoading = false,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  SpecialistAvailabilityState copyWith({
    SpecialistAvailabilityModel? availability,
    bool? isLoading,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
  }) {
    return SpecialistAvailabilityState(
      availability: availability ?? this.availability,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
    );
  }
}

class SpecialistAvailabilityNotifier
    extends Notifier<SpecialistAvailabilityState> {
  @override
  SpecialistAvailabilityState build() {
    Future.microtask(() => loadAvailability());
    return const SpecialistAvailabilityState(
      availability: SpecialistAvailabilityModel(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository =>
      ref.read(collaborationRepositoryProvider);

  Future<void> loadAvailability() async {
    try {
      final data = await _repository.getSpecialistAvailability();
      state = state.copyWith(
        availability: data,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleAvailableForSessions(bool val) {
    state = state.copyWith(
      availability: state.availability.copyWith(availableForSessions: val),
      isSaved: false,
    );
  }

  void toggleDay(String dayKey) {
    final updatedDays = state.availability.days.map((d) {
      if (d.dayKey == dayKey) {
        final newEnabled = !d.isEnabled;
        final sub = newEnabled
            ? (d.slots.isNotEmpty
                ? '${d.slots.length} ${d.slots.length == 1 ? "Slot Active" : "Slots Active"}'
                : '1 Slot Active')
            : 'Day off • Dedicated rest & prep';
        return d.copyWith(isEnabled: newEnabled, subtitle: sub);
      }
      return d;
    }).toList();
    state = state.copyWith(
      availability: state.availability.copyWith(days: updatedDays),
      isSaved: false,
    );
  }

  void addSlot(String dayKey, String timeRange) {
    final updatedDays = state.availability.days.map((d) {
      if (d.dayKey == dayKey) {
        final newSlots = [
          ...d.slots,
          SpecialistTimeSlotModel(
            id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
            timeRange: timeRange,
            iconType: d.slots.isEmpty ? 'sun' : 'sparkle',
          ),
        ];
        return d.copyWith(
          slots: newSlots,
          isEnabled: true,
          subtitle:
              '${newSlots.length} ${newSlots.length == 1 ? "Slot Active" : "Slots Active"}',
        );
      }
      return d;
    }).toList();
    state = state.copyWith(
      availability: state.availability.copyWith(days: updatedDays),
      isSaved: false,
    );
  }

  void removeSlot(String dayKey, String slotId) {
    final updatedDays = state.availability.days.map((d) {
      if (d.dayKey == dayKey) {
        final newSlots = d.slots.where((s) => s.id != slotId).toList();
        final sub = newSlots.isNotEmpty
            ? '${newSlots.length} ${newSlots.length == 1 ? "Slot Active" : "Slots Active"}'
            : 'Day off • Dedicated rest & prep';
        return d.copyWith(
          slots: newSlots,
          subtitle: sub,
        );
      }
      return d;
    }).toList();
    state = state.copyWith(
      availability: state.availability.copyWith(days: updatedDays),
      isSaved: false,
    );
  }

  void selectDuration(int minutes) {
    state = state.copyWith(
      availability:
          state.availability.copyWith(sessionDurationMinutes: minutes),
      isSaved: false,
    );
  }

  void selectBuffer(int minutes) {
    state = state.copyWith(
      availability: state.availability.copyWith(bufferMinutes: minutes),
      isSaved: false,
    );
  }

  void changeDailyCap(int delta) {
    final newCap = (state.availability.dailySessionCap + delta).clamp(1, 12);
    state = state.copyWith(
      availability: state.availability.copyWith(dailySessionCap: newCap),
      isSaved: false,
    );
  }

  Future<void> saveAvailability() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated =
          await _repository.updateSpecialistAvailability(state.availability);
      state = state.copyWith(
        availability: updated,
        isSaving: false,
        isSaved: true,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}

final specialistAvailabilityNotifierProvider = NotifierProvider<
    SpecialistAvailabilityNotifier, SpecialistAvailabilityState>(
  SpecialistAvailabilityNotifier.new,
);

// ---------------------------------------------------------------------------
// Screen 2: Specialist Verification Status Provider
// ---------------------------------------------------------------------------
class SpecialistVerificationState {
  final SpecialistVerificationModel verification;
  final bool isLoading;
  final String? errorMessage;

  const SpecialistVerificationState({
    required this.verification,
    this.isLoading = false,
    this.errorMessage,
  });

  SpecialistVerificationState copyWith({
    SpecialistVerificationModel? verification,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SpecialistVerificationState(
      verification: verification ?? this.verification,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SpecialistVerificationNotifier
    extends Notifier<SpecialistVerificationState> {
  @override
  SpecialistVerificationState build() {
    Future.microtask(() => loadVerification());
    return const SpecialistVerificationState(
      verification: SpecialistVerificationModel(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository =>
      ref.read(collaborationRepositoryProvider);

  Future<void> loadVerification() async {
    try {
      final data = await _repository.getSpecialistVerification();
      state = state.copyWith(
        verification: data,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final specialistVerificationNotifierProvider = NotifierProvider<
    SpecialistVerificationNotifier, SpecialistVerificationState>(
  SpecialistVerificationNotifier.new,
);

// ---------------------------------------------------------------------------
// Screen 3: Help & Support Provider
// ---------------------------------------------------------------------------
class SpecialistHelpState {
  final SpecialistHelpModel helpData;
  final bool isLoading;
  final String searchQuery;
  final Set<String> expandedFaqIds;
  final bool reportSubmitted;
  final String? errorMessage;

  const SpecialistHelpState({
    required this.helpData,
    this.isLoading = false,
    this.searchQuery = '',
    this.expandedFaqIds = const {},
    this.reportSubmitted = false,
    this.errorMessage,
  });

  List<FaqItemModel> get filteredFaqs {
    if (searchQuery.trim().isEmpty) return helpData.faqs;
    final q = searchQuery.toLowerCase().trim();
    return helpData.faqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
        .toList();
  }

  List<HelpCategoryItemModel> get filteredCategories {
    if (searchQuery.trim().isEmpty) return helpData.categories;
    final q = searchQuery.toLowerCase().trim();
    return helpData.categories
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.subtitle.toLowerCase().contains(q))
        .toList();
  }

  SpecialistHelpState copyWith({
    SpecialistHelpModel? helpData,
    bool? isLoading,
    String? searchQuery,
    Set<String>? expandedFaqIds,
    bool? reportSubmitted,
    String? errorMessage,
  }) {
    return SpecialistHelpState(
      helpData: helpData ?? this.helpData,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedFaqIds: expandedFaqIds ?? this.expandedFaqIds,
      reportSubmitted: reportSubmitted ?? this.reportSubmitted,
      errorMessage: errorMessage,
    );
  }
}

class SpecialistHelpNotifier extends Notifier<SpecialistHelpState> {
  @override
  SpecialistHelpState build() {
    Future.microtask(() => loadHelp());
    return const SpecialistHelpState(
      helpData: SpecialistHelpModel(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository =>
      ref.read(collaborationRepositoryProvider);

  Future<void> loadHelp() async {
    try {
      final data = await _repository.getSpecialistHelp();
      state = state.copyWith(
        helpData: data,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFaq(String faqId) {
    final next = Set<String>.from(state.expandedFaqIds);
    if (next.contains(faqId)) {
      next.remove(faqId);
    } else {
      next.add(faqId);
    }
    state = state.copyWith(expandedFaqIds: next);
  }

  Future<void> reportProblem(String category, String description) async {
    try {
      await _repository.reportSpecialistProblem(category, description);
      state = state.copyWith(reportSubmitted: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void resetReportStatus() {
    state = state.copyWith(reportSubmitted: false);
  }
}

final specialistHelpNotifierProvider =
    NotifierProvider<SpecialistHelpNotifier, SpecialistHelpState>(
  SpecialistHelpNotifier.new,
);

// =============================================================================
// SPECIALIST SETTINGS STATE & NOTIFIER
// =============================================================================

class SpecialistSettingsState {
  final SpecialistSettingsModel settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool saveSuccess;

  const SpecialistSettingsState({
    this.settings = const SpecialistSettingsModel(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveSuccess = false,
  });

  SpecialistSettingsState copyWith({
    SpecialistSettingsModel? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? saveSuccess,
  }) {
    return SpecialistSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

class SpecialistSettingsNotifier extends Notifier<SpecialistSettingsState> {
  @override
  SpecialistSettingsState build() {
    Future.microtask(() => loadSettings());
    return const SpecialistSettingsState(
      settings: SpecialistSettingsModel(),
      isLoading: true,
    );
  }

  ICollaborationRepository get _repository =>
      ref.read(collaborationRepositoryProvider);

  Future<void> loadSettings() async {
    try {
      final data = await _repository.getSpecialistSettings();
      state = state.copyWith(
        settings: data,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateToggle(String key, bool value) async {
    SpecialistSettingsModel updated;
    switch (key) {
      case 'session_reminders':
        updated = state.settings.copyWith(sessionReminders: value);
        break;
      case 'consent_alerts':
        updated = state.settings.copyWith(consentAlerts: value);
        break;
      case 'messages_alerts':
        updated = state.settings.copyWith(messagesAlerts: value);
        break;
      case 'appointment_requests':
        updated = state.settings.copyWith(appointmentRequests: value);
        break;
      case 'weekly_progress_digests':
        updated = state.settings.copyWith(weeklyProgressDigests: value);
        break;
      case 'larger_text':
        updated = state.settings.copyWith(largerText: value);
        break;
      case 'reduce_motion':
        updated = state.settings.copyWith(reduceMotion: value);
        break;
      case 'high_contrast':
        updated = state.settings.copyWith(highContrast: value);
        break;
      case 'haptic_feedback':
        updated = state.settings.copyWith(hapticFeedback: value);
        break;
      case 'audio_sound_fx':
        updated = state.settings.copyWith(audioSoundFx: value);
        break;
      default:
        return;
    }
    state = state.copyWith(settings: updated, isSaving: true);
    try {
      final saved = await _repository.updateSpecialistSettings(updated);
      state = state.copyWith(settings: saved, isSaving: false, saveSuccess: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> updateVisibility(String visibility) async {
    final updated = state.settings.copyWith(profileVisibility: visibility);
    state = state.copyWith(settings: updated, isSaving: true);
    try {
      final saved = await _repository.updateSpecialistSettings(updated);
      state = state.copyWith(settings: saved, isSaving: false, saveSuccess: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> updateStudioPreference({
    String? language,
    String? appearanceTheme,
    String? timeZone,
  }) async {
    final updated = state.settings.copyWith(
      language: language,
      appearanceTheme: appearanceTheme,
      timeZone: timeZone,
    );
    state = state.copyWith(settings: updated, isSaving: true);
    try {
      final saved = await _repository.updateSpecialistSettings(updated);
      state = state.copyWith(settings: saved, isSaving: false, saveSuccess: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}

final specialistSettingsNotifierProvider =
    NotifierProvider<SpecialistSettingsNotifier, SpecialistSettingsState>(
  SpecialistSettingsNotifier.new,
);






