import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/network_provider.dart';
import '../data/learning_repository.dart';
import '../domain/models/lesson_model.dart';
import '../domain/models/exercise_model.dart';
import '../domain/models/exercise_attempt_model.dart';
import '../domain/models/practice_hub_model.dart';
import '../domain/models/learning_path_model.dart';

/// Provider for Learning Repository
final learningRepositoryProvider = Provider<ILearningRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LearningRepository(client);
});

/// Provider for Practice Hub overview
final practiceHubProvider = FutureProvider<PracticeHubModel>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getPracticeHub();
});

/// Provider for personalized Learning Path
final learningPathProvider = FutureProvider<LearningPathModel>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getLearningPath();
});

/// Provider for listing lessons with optional track filter
final lessonsListProvider = FutureProvider.family<List<LessonSummaryModel>, String?>((ref, track) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getLessons(track: track);
});

/// State of the interactive Lesson Player
class LessonPlayerState {
  final bool isLoading;
  final String? errorMessage;
  final LessonDetailModel? lesson;
  final int currentExerciseIndex;
  final dynamic selectedResponse;
  final bool isSubmitting;
  final bool hintUsed;
  final int attemptNumber;
  final ExerciseAttemptResponseModel? evaluationResult;
  final bool isLessonCompleted;

  const LessonPlayerState({
    this.isLoading = true,
    this.errorMessage,
    this.lesson,
    this.currentExerciseIndex = 0,
    this.selectedResponse,
    this.isSubmitting = false,
    this.hintUsed = false,
    this.attemptNumber = 1,
    this.evaluationResult,
    this.isLessonCompleted = false,
  });

  ExerciseModel? get currentExercise {
    if (lesson == null || lesson!.exercises.isEmpty) return null;
    if (currentExerciseIndex < lesson!.exercises.length) {
      return lesson!.exercises[currentExerciseIndex];
    }
    return null;
  }

  int get totalExercises => lesson?.exercises.length ?? 0;
  double get progressFraction {
    if (totalExercises == 0) return 0.0;
    return (currentExerciseIndex / totalExercises).clamp(0.0, 1.0);
  }

  LessonPlayerState copyWith({
    bool? isLoading,
    String? errorMessage,
    LessonDetailModel? lesson,
    int? currentExerciseIndex,
    dynamic selectedResponse,
    bool? isSubmitting,
    bool? hintUsed,
    int? attemptNumber,
    ExerciseAttemptResponseModel? evaluationResult,
    bool clearEvaluation = false,
    bool? isLessonCompleted,
  }) {
    return LessonPlayerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lesson: lesson ?? this.lesson,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      selectedResponse: selectedResponse ?? this.selectedResponse,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hintUsed: hintUsed ?? this.hintUsed,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      evaluationResult: clearEvaluation ? null : (evaluationResult ?? this.evaluationResult),
      isLessonCompleted: isLessonCompleted ?? this.isLessonCompleted,
    );
  }
}

/// Notifier managing lesson progression, interaction, hints, and retries.
class LessonPlayerNotifier extends Notifier<LessonPlayerState> {
  final String lessonId;

  LessonPlayerNotifier(this.lessonId);

  ILearningRepository get _repository => ref.read(learningRepositoryProvider);

  @override
  LessonPlayerState build() {
    Future.microtask(() => init());
    return const LessonPlayerState(isLoading: true);
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Fetch lesson details with exercises
      final lessonDetail = await _repository.getLessonDetail(lessonId);

      // 2. Start or resume lesson on backend to retrieve/persist position
      final progressData = await _repository.startOrResumeLesson(lessonId);
      final currentIdx = (progressData['current_exercise_index'] as int?) ?? 0;
      final isCompleted = progressData['status'] == 'completed';

      state = state.copyWith(
        isLoading: false,
        lesson: lessonDetail,
        currentExerciseIndex: currentIdx < lessonDetail.exercises.length ? currentIdx : 0,
        isLessonCompleted: isCompleted,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load lesson practice. Please check your connection and retry.',
      );
    }
  }

  void selectResponse(dynamic response) {
    state = state.copyWith(selectedResponse: response);
  }

  void recordHintUsed() {
    state = state.copyWith(hintUsed: true);
  }

  Future<void> submitCurrentAttempt() async {
    final ex = state.currentExercise;
    if (ex == null || state.selectedResponse == null || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);
    try {
      final request = ExerciseAttemptRequestModel(
        response: state.selectedResponse,
        attemptNumber: state.attemptNumber,
        hintUsed: state.hintUsed,
      );

      final result = await _repository.submitExerciseAttempt(
        exerciseId: ex.id,
        request: request,
      );

      state = state.copyWith(
        isSubmitting: false,
        evaluationResult: result,
        isLessonCompleted: result.lessonCompleted,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: "We couldn't save your answer. Your progress has not been lost.",
      );
    }
  }

  void retryCurrentExercise() {
    // Non-punitive retry: clear evaluation, increment attempt number, clear response
    state = state.copyWith(
      clearEvaluation: true,
      selectedResponse: null,
      attemptNumber: state.attemptNumber + 1,
    );
  }

  void moveToNextExercise() {
    final nextIdx = state.currentExerciseIndex + 1;
    if (nextIdx >= state.totalExercises) {
      state = state.copyWith(
        isLessonCompleted: true,
        clearEvaluation: true,
      );
    } else {
      state = state.copyWith(
        currentExerciseIndex: nextIdx,
        selectedResponse: null,
        hintUsed: false,
        attemptNumber: 1,
        clearEvaluation: true,
      );
    }
  }
}

final lessonPlayerControllerProvider =
    NotifierProvider.family<LessonPlayerNotifier, LessonPlayerState, String>(
  (lessonId) => LessonPlayerNotifier(lessonId),
);
