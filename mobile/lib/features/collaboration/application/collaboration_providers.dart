import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/network_provider.dart';
import 'package:lingua_ai/features/collaboration/data/collaboration_repository.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/progress/domain/models/progress_models.dart';

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

// Parent Workspace Providers
final parentChildrenProvider = FutureProvider<List<ParentChildItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getParentChildren();
});

final parentChildProgressProvider =
    FutureProvider.family<ProgressDashboardData, String>((ref, childId) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getChildProgress(childId);
});

// Teacher Workspace Providers
final teacherStudentsProvider = FutureProvider<List<TeacherStudentItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getTeacherStudents();
});

final teacherAssignmentsProvider = FutureProvider<List<AssignmentItem>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getTeacherAssignments();
});

final teacherClassroomTrendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getClassroomTrends();
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



