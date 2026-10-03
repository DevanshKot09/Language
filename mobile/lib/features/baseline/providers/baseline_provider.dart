import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/network_provider.dart';
import '../data/models/baseline_session_model.dart';
import '../data/models/baseline_activity_model.dart';
import '../data/models/skill_snapshot_model.dart';
import '../data/models/learner_goal_model.dart';
import '../data/repositories/baseline_repository.dart';

final baselineRepositoryProvider = Provider<IBaselineRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BaselineRepository(client);
});

final skillSnapshotProvider = FutureProvider<SkillSnapshotModel>((ref) async {
  final repo = ref.watch(baselineRepositoryProvider);
  return await repo.getSkillSnapshot();
});

final learnerGoalsProvider = FutureProvider<List<LearnerGoalModel>>((ref) async {
  final repo = ref.watch(baselineRepositoryProvider);
  return await repo.getGoals();
});

/// State of an active baseline session.
class BaselineSessionState {
  final BaselineSessionModel? session;
  final int currentIndex;
  final String? selectedOption;
  final BaselineResponseResultModel? lastResult;
  final bool isSubmitting;
  final bool isCompleted;
  final SkillSnapshotModel? snapshot;
  final String? errorMessage;
  final int activityStartTimeMs;

  const BaselineSessionState({
    this.session,
    this.currentIndex = 0,
    this.selectedOption,
    this.lastResult,
    this.isSubmitting = false,
    this.isCompleted = false,
    this.snapshot,
    this.errorMessage,
    this.activityStartTimeMs = 0,
  });

  BaselineActivityModel? get currentActivity {
    if (session == null || session!.activities.isEmpty) return null;
    if (currentIndex >= session!.activities.length) return null;
    return session!.activities[currentIndex];
  }

  int get totalActivities => session?.activities.length ?? 0;

  double get progress {
    if (totalActivities == 0) return 0.0;
    return (currentIndex) / totalActivities;
  }

  BaselineSessionState copyWith({
    BaselineSessionModel? session,
    int? currentIndex,
    String? selectedOption,
    BaselineResponseResultModel? lastResult,
    bool? isSubmitting,
    bool? isCompleted,
    SkillSnapshotModel? snapshot,
    String? errorMessage,
    int? activityStartTimeMs,
    bool clearSelectedOption = false,
    bool clearLastResult = false,
    bool clearError = false,
  }) {
    return BaselineSessionState(
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activityStartTimeMs: activityStartTimeMs ?? this.activityStartTimeMs,
    );
  }
}

/// Controller managing baseline session lifecycle and activity progression.
class BaselineSessionNotifier extends Notifier<AsyncValue<BaselineSessionState>> {
  @override
  AsyncValue<BaselineSessionState> build() {
    return const AsyncValue.data(BaselineSessionState());
  }

  IBaselineRepository get _repository => ref.read(baselineRepositoryProvider);

  Future<void> startOrResumeSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.createOrGetSession();
      // If session is already completed, fetch snapshot directly
      if (session.isCompleted) {
        final snapshot = await _repository.getSkillSnapshot();
        state = AsyncValue.data(
          BaselineSessionState(
            session: session,
            isCompleted: true,
            snapshot: snapshot,
          ),
        );
        return;
      }

      // Resume from current completed activities index
      final startIndex = session.completedActivities < session.activities.length
          ? session.completedActivities
          : 0;

      state = AsyncValue.data(
        BaselineSessionState(
          session: session,
          currentIndex: startIndex,
          activityStartTimeMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void selectOption(String option) {
    state.whenData((current) {
      if (current.lastResult != null) return; // Answer already submitted for this question
      state = AsyncValue.data(current.copyWith(selectedOption: option));
    });
  }

  Future<void> submitAnswer() async {
    final current = state.asData?.value;
    if (current == null || current.session == null || current.selectedOption == null) return;
    final activity = current.currentActivity;
    if (activity == null) return;

    state = AsyncValue.data(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeTaken = (now - current.activityStartTimeMs).clamp(500, 120000).toInt();

      final result = await _repository.submitResponse(
        sessionId: current.session!.id,
        activityId: activity.id,
        selectedOption: current.selectedOption!,
        timeTakenMs: timeTaken,
      );

      final updatedSession = current.session!.copyWith(
        completedActivities: result.completedActivities,
      );

      state = AsyncValue.data(
        current.copyWith(
          session: updatedSession,
          lastResult: result,
          isSubmitting: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to submit response. Please check connection.',
        ),
      );
    }
  }

  Future<void> nextActivity() async {
    final current = state.asData?.value;
    if (current == null || current.session == null) return;

    final nextIndex = current.currentIndex + 1;
    final isDone = nextIndex >= current.totalActivities;

    if (isDone) {
      state = AsyncValue.data(current.copyWith(isSubmitting: true));
      try {
        final snapshot = await _repository.completeSession(current.session!.id);
        state = AsyncValue.data(
          current.copyWith(
            isSubmitting: false,
            isCompleted: true,
            snapshot: snapshot,
          ),
        );
      } catch (e) {
        state = AsyncValue.data(
          current.copyWith(
            isSubmitting: false,
            errorMessage: 'Error finalizing baseline. Please try again.',
          ),
        );
      }
    } else {
      state = AsyncValue.data(
        current.copyWith(
          currentIndex: nextIndex,
          clearSelectedOption: true,
          clearLastResult: true,
          activityStartTimeMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  void reset() {
    state = const AsyncValue.data(BaselineSessionState());
  }
}

final baselineSessionProvider =
    NotifierProvider<BaselineSessionNotifier, AsyncValue<BaselineSessionState>>(
  BaselineSessionNotifier.new,
);

