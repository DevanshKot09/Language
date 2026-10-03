import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../domain/models/exercise_model.dart';
import '../../application/learning_providers.dart';
import '../widgets/exercise_progress_indicator.dart';
import '../widgets/multiple_choice_exercise_view.dart';
import '../widgets/word_order_exercise_view.dart';
import '../widgets/speaking_practice_exercise_view.dart';
import '../widgets/matching_exercise_view.dart';
import '../widgets/reading_passage_exercise_view.dart';
import '../widgets/narrative_sequencing_exercise_view.dart';
import '../widgets/listening_exercise_view.dart';
import '../widgets/social_communication_exercise_view.dart';
import '../widgets/word_building_exercise_view.dart';
import '../widgets/exercise_hint_drawer.dart';
import '../widgets/exercise_feedback_banner.dart';
import 'lesson_completion_screen.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/widgets/ai_explanation_sheet.dart';

class LessonPlayerScreen extends ConsumerWidget {
  final String lessonId;

  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonPlayerControllerProvider(lessonId));
    final controller = ref.read(lessonPlayerControllerProvider(lessonId).notifier);

    // If lesson is completed, transition to LessonCompletionScreen
    if (state.isLessonCompleted && state.lesson != null) {
      return LessonCompletionScreen(
        lesson: state.lesson!,
        onContinue: () {
          // Invalidate practice & path providers so they refresh
          ref.invalidate(practiceHubProvider);
          ref.invalidate(learningPathProvider);
          Navigator.pop(context);
        },
      );
    }

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Practice...')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.errorMessage != null || state.lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice Session')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: LinguaTokens.inkMuted),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Lesson unavailable right now.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: LinguaTokens.ink700),
                ),
                const SizedBox(height: 24),
                LinguaButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  onPressed: () => controller.init(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final lesson = state.lesson!;
    final exercise = state.currentExercise;

    if (exercise == null) {
      return LessonCompletionScreen(
        lesson: lesson,
        onContinue: () => Navigator.pop(context),
      );
    }

    final hasResponse = state.selectedResponse != null &&
        (state.selectedResponse is! List || (state.selectedResponse as List).isNotEmpty) &&
        (state.selectedResponse is! Map || (state.selectedResponse as Map).isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Pause & Exit',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (exercise.hints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Clue & Hint',
              onPressed: () {
                ExerciseHintModal.show(
                  context,
                  exercise.hints,
                  onHintUsed: () => controller.recordHintUsed(),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LinguaTokens.space20,
                vertical: LinguaTokens.space12,
              ),
              child: ExerciseProgressIndicator(
                currentIndex: state.currentExerciseIndex,
                totalCount: state.totalExercises,
              ),
            ),
            const Divider(height: 1, color: LinguaTokens.borderSubtle),

            // Scrollable Exercise Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LinguaTokens.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dynamic View based on exerciseType
                    _buildExerciseView(exercise, state, controller),

                    // Evaluation Result Banner
                    if (state.evaluationResult != null) ...[
                      ExerciseFeedbackBanner(
                        evaluation: state.evaluationResult!,
                        onContinue: () {
                          if (state.evaluationResult!.lessonCompleted) {
                            controller.moveToNextExercise();
                          } else {
                            controller.moveToNextExercise();
                          }
                        },
                        onRetry: () => controller.retryCurrentExercise(),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.school_outlined, size: 16),
                          label: const Text('Why is this correct? Ask AI to explain'),
                          style: TextButton.styleFrom(
                            foregroundColor: LinguaTokens.primary700,
                          ),
                          onPressed: () async {
                            final aiRepo = ref.read(aiRepositoryProvider);
                            final explanation = await aiRepo.getExplanation(
                              lessonTitle: lesson.title,
                              exercisePrompt: exercise.prompt,
                              targetConcept: exercise.instruction,
                              learnerQuestion: 'Can you explain why this answer is correct?',
                              ageBand: 'child',
                            );
                            if (context.mounted) {
                              AiExplanationSheet.show(
                                context,
                                conceptTitle: exercise.instruction,
                                explanation: explanation,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Bar when not yet evaluated
            if (state.evaluationResult == null)
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: LinguaTokens.borderSubtle)),
                ),
                child: LinguaButton(
                  label: 'Check Answer',
                  isLoading: state.isSubmitting,
                  onPressed: hasResponse ? () => controller.submitCurrentAttempt() : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseView(
    ExerciseModel exercise,
    LessonPlayerState state,
    LessonPlayerNotifier controller,
  ) {
    final isLocked = state.evaluationResult != null;

    switch (exercise.exerciseType) {
      case 'word_order':
        final currentTokens = state.selectedResponse is List<String>
            ? state.selectedResponse as List<String>
            : (state.selectedResponse is List
                ? (state.selectedResponse as List).map((e) => e.toString()).toList()
                : <String>[]);
        return WordOrderExerciseView(
          exercise: exercise,
          currentArrangement: currentTokens,
          isLocked: isLocked,
          onArrangementChanged: (tokens) => controller.selectResponse(tokens),
        );

      case 'matching':
        final currentPairs = state.selectedResponse is Map<String, String>
            ? state.selectedResponse as Map<String, String>
            : (state.selectedResponse is Map
                ? Map<String, String>.from(
                    (state.selectedResponse as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
                  )
                : <String, String>{});
        return MatchingExerciseView(
          exercise: exercise,
          currentMatches: currentPairs,
          isLocked: isLocked,
          onMatchesChanged: (pairs) => controller.selectResponse(pairs),
        );

      case 'reading_passage':
      case 'reading_comprehension':
        if (exercise.readingPassage != null && exercise.readingPassage!.isNotEmpty) {
          return ReadingPassageExerciseView(
            exercise: exercise,
            selectedOption: state.selectedResponse as String?,
            isLocked: isLocked,
            onSelectOption: (opt) => controller.selectResponse(opt),
          );
        }
        return MultipleChoiceExerciseView(
          exercise: exercise,
          selectedOption: state.selectedResponse as String?,
          isLocked: isLocked,
          onSelectOption: (opt) => controller.selectResponse(opt),
        );

      case 'word_building':
        final currentTiles = state.selectedResponse is List<String>
            ? state.selectedResponse as List<String>
            : (state.selectedResponse is List
                ? (state.selectedResponse as List).map((e) => e.toString()).toList()
                : <String>[]);
        return WordBuildingExerciseView(
          exercise: exercise,
          currentTiles: currentTiles,
          isLocked: isLocked,
          onTilesChanged: (tiles) => controller.selectResponse(tiles),
        );

      case 'narrative_sequencing':
        final currentOrder = state.selectedResponse is List<String>
            ? state.selectedResponse as List<String>
            : (state.selectedResponse is List
                ? (state.selectedResponse as List).map((e) => e.toString()).toList()
                : <String>[]);
        return NarrativeSequencingExerciseView(
          exercise: exercise,
          currentOrder: currentOrder,
          isLocked: isLocked,
          onOrderChanged: (order) => controller.selectResponse(order),
        );

      case 'listening_comprehension':
        return ListeningExerciseView(
          exercise: exercise,
          selectedOption: state.selectedResponse as String?,
          isLocked: isLocked,
          onSelectOption: (opt) => controller.selectResponse(opt),
        );

      case 'social_communication':
        return SocialCommunicationExerciseView(
          exercise: exercise,
          selectedOption: state.selectedResponse as String?,
          isLocked: isLocked,
          onSelectOption: (opt) => controller.selectResponse(opt),
        );

      case 'speaking_practice':
      case 'speaking':
      case 'oral_narration':
      case 'reading_aloud':
        return SpeakingPracticeExerciseView(
          exercise: exercise,
          currentAnswer: state.selectedResponse as String?,
          isLocked: isLocked,
          onAnswerChanged: (ans) => controller.selectResponse(ans),
        );

      case 'phonological_awareness':
      case 'phonics':
      case 'decoding':
      case 'spelling':
      case 'multiple_choice':
      case 'sentence_completion':
      case 'spelling_selection':
      default:
        return MultipleChoiceExerciseView(
          exercise: exercise,
          selectedOption: state.selectedResponse as String?,
          isLocked: isLocked,
          onSelectOption: (opt) => controller.selectResponse(opt),
        );
    }
  }
}
