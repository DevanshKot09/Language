import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/learning/application/learning_providers.dart';
import 'package:lingua_ai/features/learning/presentation/screens/practice_hub_screen.dart';
import 'package:lingua_ai/features/learning/presentation/screens/lesson_player_screen.dart';
import 'package:lingua_ai/features/learning/presentation/screens/lesson_completion_screen.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/exercise_progress_indicator.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/exercise_feedback_banner.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/exercise_hint_drawer.dart';
import 'package:lingua_ai/features/learning_path/learning_path_screen.dart';
import '../helpers/mock_learning_repository.dart';

void main() {
  group('Phase 5 Learning & Practice Screens Widget Tests', () {
    testWidgets('PracticeHubScreen renders recommended lessons and track filter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockLearningRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: PracticeHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Practice Hub'), findsOneWidget);
      expect(find.text('Recommended Practice'), findsOneWidget);
      expect(find.text('Skills in Practice'), findsOneWidget);
      expect(find.text('Continue In Progress'), findsOneWidget);

      // Check seeded lesson cards and skills summary exist
      expect(find.text('Everyday Action Words'), findsAtLeastNWidgets(1));
      expect(find.text('Vocabulary Breadth'), findsOneWidget);
      expect(find.text('1 of 2 lessons completed'), findsOneWidget);
    });

    testWidgets('LessonPlayerScreen renders progress, exercise prompt, hint and feedback', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockLearningRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LessonPlayerScreen(lessonId: 'lesson-dld-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress bar and exercise view
      expect(find.byType(ExerciseProgressIndicator), findsOneWidget);
      expect(find.text('Everyday Action Words'), findsOneWidget);
      expect(find.textContaining('explore'), findsOneWidget);

      // Hint button in app bar
      final hintButton = find.byIcon(Icons.lightbulb_outline);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseHintModal), findsOneWidget);
      expect(find.text('Helpful Learning Clue'), findsOneWidget);
      expect(find.text('Got it, let me try!'), findsOneWidget);

      // Close hint modal
      await tester.tap(find.text('Got it, let me try!'));
      await tester.pumpAndSettle();

      // Select an option
      final correctOption = find.text('To look around and discover new things');
      expect(correctOption, findsOneWidget);
      await tester.tap(correctOption);
      await tester.pumpAndSettle();

      // Submit answer
      expect(find.text('Check Answer'), findsOneWidget);
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();

      // Verify feedback banner
      expect(find.byType(ExerciseFeedbackBanner), findsOneWidget);
      expect(find.text('Wonderful job! You found the right answer.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('LessonCompletionScreen renders celebratory non-diagnostic summary', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lesson = MockLearningRepository().mockLessonDetail;

      await tester.pumpWidget(
        MaterialApp(
          home: LessonCompletionScreen(
            lesson: lesson,
            onContinue: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert non-diagnostic language and practice summary
      expect(find.text('Lesson Complete!'), findsOneWidget);
      expect(find.text('Practice Summary'), findsOneWidget);
      expect(find.textContaining('Everyday Action Words'), findsOneWidget);
      expect(find.text('3 activities completed'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
    });

    testWidgets('LearningPathScreen renders live nodes with real lesson data', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockLearningRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LearningPathScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and nodes
      expect(find.text('My Skill Path'), findsOneWidget);
      expect(find.text('Personalized Learning Sequence'), findsOneWidget);
      expect(find.text('Everyday Action Words'), findsOneWidget);
      expect(find.text('Building Connected Sentences'), findsOneWidget);
    });

    testWidgets('Phase 5 Safety Guard: Strict non-diagnostic terminology across learning screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prohibitedPhrases = [
        'you have dld',
        'you have dyslexia',
        'dyslexia score',
        'dld severity',
        'you are cured',
        'disorder improved',
        'diagnosis of',
        'clinical risk',
        'diagnostic probability',
        'deficit',
      ];

      final mockRepo = MockLearningRepository();

      // Test PracticeHubScreen text
      await tester.pumpWidget(
        ProviderScope(
          overrides: [learningRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(home: PracticeHubScreen()),
        ),
      );
      await tester.pumpAndSettle();

      for (final phrase in prohibitedPhrases) {
        expect(
          find.textContaining(phrase, findRichText: true),
          findsNothing,
          reason: 'Prohibited clinical phrase "$phrase" found in PracticeHubScreen',
        );
      }

      // Test LessonCompletionScreen text
      await tester.pumpWidget(
        MaterialApp(
          home: LessonCompletionScreen(
            lesson: mockRepo.mockLessonDetail,
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final phrase in prohibitedPhrases) {
        expect(
          find.textContaining(phrase, findRichText: true),
          findsNothing,
          reason: 'Prohibited clinical phrase "$phrase" found in LessonCompletionScreen',
        );
      }
    });
  });
}
