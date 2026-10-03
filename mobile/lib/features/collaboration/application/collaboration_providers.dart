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

// Reports Providers
final reportsProvider = FutureProvider.family<List<ReportItem>, String?>((ref, learnerId) async {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getReports(learnerId: learnerId);
});
