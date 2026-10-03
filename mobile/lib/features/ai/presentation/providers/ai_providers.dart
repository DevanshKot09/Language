import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/network_provider.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/repositories/i_ai_repository.dart';
import '../../data/ai_repository.dart';

/// Provider for IAiRepository
final aiRepositoryProvider = Provider<IAiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AiRepository(apiClient: client);
});

/// Provider for AI Runtime Status
final aiStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(aiRepositoryProvider);
  return repo.getAiStatus();
});

/// Recommendation State
class AiRecommendationState {
  final bool isLoading;
  final List<AiRecommendationItemModel> recommendations;
  final String? error;

  const AiRecommendationState({
    this.isLoading = false,
    this.recommendations = const [],
    this.error,
  });

  AiRecommendationState copyWith({
    bool? isLoading,
    List<AiRecommendationItemModel>? recommendations,
    String? error,
  }) {
    return AiRecommendationState(
      isLoading: isLoading ?? this.isLoading,
      recommendations: recommendations ?? this.recommendations,
      error: error,
    );
  }
}

class AiRecommendationNotifier extends Notifier<AiRecommendationState> {
  @override
  AiRecommendationState build() {
    return const AiRecommendationState();
  }

  Future<void> loadRecommendations({
    required String track,
    required String ageBand,
    required List<String> candidateLessonIds,
    List<String> recentCompleted = const [],
    List<String> goals = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(aiRepositoryProvider);
      final recs = await repo.getRecommendations(
        track: track,
        ageBand: ageBand,
        candidateLessonIds: candidateLessonIds,
        recentCompletedLessonIds: recentCompleted,
        currentGoals: goals,
      );
      state = state.copyWith(isLoading: false, recommendations: recs);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'AI suggestions are unavailable right now. Standard sequence will guide you.',
      );
    }
  }
}

final aiRecommendationProvider =
    NotifierProvider<AiRecommendationNotifier, AiRecommendationState>(
  AiRecommendationNotifier.new,
);

/// Explanation Notifier
class AiExplanationState {
  final bool isLoading;
  final AiExplanationModel? explanation;
  final String? error;

  const AiExplanationState({
    this.isLoading = false,
    this.explanation,
    this.error,
  });
}

class AiExplanationNotifier extends Notifier<AiExplanationState> {
  @override
  AiExplanationState build() {
    return const AiExplanationState();
  }

  Future<void> askExplanation({
    required String lessonTitle,
    required String exercisePrompt,
    required String targetConcept,
    required String learnerQuestion,
    required String ageBand,
  }) async {
    state = const AiExplanationState(isLoading: true);
    try {
      final repo = ref.read(aiRepositoryProvider);
      final res = await repo.getExplanation(
        lessonTitle: lessonTitle,
        exercisePrompt: exercisePrompt,
        targetConcept: targetConcept,
        learnerQuestion: learnerQuestion,
        ageBand: ageBand,
      );
      state = AiExplanationState(isLoading: false, explanation: res);
    } catch (e) {
      state = const AiExplanationState(
        isLoading: false,
        error: 'AI explanation is unavailable right now.',
      );
    }
  }
}

final aiExplanationProvider =
    NotifierProvider<AiExplanationNotifier, AiExplanationState>(
  AiExplanationNotifier.new,
);

/// Writing / Speaking Feedback Notifier
class AiFeedbackState {
  final bool isLoading;
  final AiFeedbackModel? feedback;
  final String? error;

  const AiFeedbackState({
    this.isLoading = false,
    this.feedback,
    this.error,
  });
}

class AiFeedbackNotifier extends Notifier<AiFeedbackState> {
  @override
  AiFeedbackState build() {
    return const AiFeedbackState();
  }

  Future<void> requestFeedback({
    required String activityType,
    required String prompt,
    required String learnerSubmission,
    required String ageBand,
    required String track,
  }) async {
    state = const AiFeedbackState(isLoading: true);
    try {
      final repo = ref.read(aiRepositoryProvider);
      final res = await repo.getFeedback(
        activityType: activityType,
        prompt: prompt,
        learnerSubmission: learnerSubmission,
        ageBand: ageBand,
        track: track,
      );
      state = AiFeedbackState(isLoading: false, feedback: res);
    } catch (e) {
      state = const AiFeedbackState(
        isLoading: false,
        error: 'AI feedback is unavailable right now.',
      );
    }
  }
}

final aiFeedbackProvider =
    NotifierProvider<AiFeedbackNotifier, AiFeedbackState>(
  AiFeedbackNotifier.new,
);
