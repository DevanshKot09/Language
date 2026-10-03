import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/learning/application/learning_providers.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_model.dart';
import 'package:lingua_ai/features/learning/domain/models/practice_hub_model.dart';
import 'package:lingua_ai/features/learning/presentation/screens/dyslexia_track_dashboard_screen.dart';
import 'package:lingua_ai/features/learning/presentation/screens/practice_hub_screen.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/reading_passage_exercise_view.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/word_building_exercise_view.dart';
import 'package:lingua_ai/app/providers/audio_provider.dart';
import '../helpers/mock_learning_repository.dart';
import '../unit/audio_speech_unit_test.dart';

void main() {
  group('Phase 7 Dyslexia / Literacy Dedicated Experience Tests', () {
    testWidgets('DyslexiaTrackDashboardScreen renders skill domains, age filters, and non-diagnostic copy',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final customHub = PracticeHubModel(
        recommendedLessons: [],
        inProgressLessons: [],
        completedLessons: [],
        skillsSummary: const [
          SkillProgressItemModel(
            skillId: 's1',
            skillCode: 'dys_phonological_awareness',
            skillName: 'Phonological & Phonemic Awareness',
            track: 'dyslexia_track',
            completedLessons: 1,
            totalLessons: 2,
            masteryStatus: 'Practicing',
          ),
          SkillProgressItemModel(
            skillId: 's2',
            skillCode: 'dys_phonics',
            skillName: 'Systematic Phonics & Graphemes',
            track: 'dyslexia_track',
            completedLessons: 2,
            totalLessons: 2,
            masteryStatus: 'Consistent',
          ),
          SkillProgressItemModel(
            skillId: 's3',
            skillCode: 'dys_decoding',
            skillName: 'Word Recognition & Decoding',
            track: 'dyslexia_track',
            completedLessons: 0,
            totalLessons: 2,
            masteryStatus: 'Developing',
          ),
          SkillProgressItemModel(
            skillId: 's4',
            skillCode: 'dys_spelling',
            skillName: 'Spelling & Orthographic Patterns',
            track: 'dyslexia_track',
            completedLessons: 0,
            totalLessons: 2,
            masteryStatus: 'Starting',
          ),
          SkillProgressItemModel(
            skillId: 's5',
            skillCode: 'dys_fluency',
            skillName: 'Reading Fluency & Automaticity',
            track: 'dyslexia_track',
            completedLessons: 1,
            totalLessons: 2,
            masteryStatus: 'Practicing',
          ),
          SkillProgressItemModel(
            skillId: 's6',
            skillCode: 'dys_reading_comprehension',
            skillName: 'Text Comprehension & Strategy Use',
            track: 'dyslexia_track',
            completedLessons: 0,
            totalLessons: 2,
            masteryStatus: 'Developing',
          ),
        ],
      );

      final mockRepo = MockLearningRepository(practiceHub: customHub);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DyslexiaTrackDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Literacy & Reading (Dyslexia)'), findsOneWidget);
      expect(find.text('Literacy & Reading Learning Area'), findsOneWidget);
      expect(find.text('Literacy Practice Domains'), findsOneWidget);
      expect(find.textContaining('Targeted reading science practice'), findsOneWidget);

      // Verify Dyslexia Skill Domains
      expect(find.text('Phonological & Phonemic Awareness'), findsOneWidget);
      expect(find.text('Systematic Phonics & Graphemes'), findsOneWidget);
      expect(find.text('Word Recognition & Decoding'), findsOneWidget);
      expect(find.text('Spelling & Orthographic Patterns'), findsOneWidget);
      expect(find.text('Reading Fluency & Automaticity'), findsOneWidget);
      expect(find.text('Text Comprehension & Strategy Use'), findsOneWidget);

      // Verify Age-Band Filter Dropdown and Available Lessons
      expect(find.text('Available Literacy Lessons'), findsOneWidget);
      expect(find.text('All Ages'), findsOneWidget);

      // Verify Non-diagnostic terminology guard
      expect(find.textContaining('You have dyslexia'), findsNothing);
      expect(find.textContaining('Your dyslexia score'), findsNothing);
      expect(find.textContaining('dyslexia severity'), findsNothing);
    });

    testWidgets('ReadingPassageExerciseView renders passage, accessibility aids, TTS toggle, and options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readingExercise = ExerciseModel(
        id: 'ex-dys-005',
        lessonId: 'lesson-dys-005',
        skillId: 'dys_fluency',
        exerciseType: 'reading_passage',
        prompt: 'Who walked down the forest path with Leo?',
        instruction: 'Read the story or tap play to listen with line pacing.',
        content: {
          'passage': 'Leo and his friendly puppy Milo walked down the quiet forest path.',
          'options': [
            'His friendly puppy Milo',
            'His brother Sam',
            'A wild brown rabbit',
          ],
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dyslexia_track',
        sequenceOrder: 1,
      );

      final mockTts = MockTtsService();
      String? selectedValue;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ttsServiceProvider.overrideWithValue(mockTts),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReadingPassageExerciseView(
                  exercise: readingExercise,
                  selectedOption: selectedValue,
                  onSelectOption: (val) {
                    selectedValue = val;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check passage title & content
      expect(find.text('Reading Passage'), findsOneWidget);
      expect(find.textContaining('Leo and his friendly puppy Milo'), findsOneWidget);
      expect(find.text('Who walked down the forest path with Leo?'), findsOneWidget);

      // Check reading aids toolbar buttons
      expect(find.byTooltip('Read passage aloud (TTS)'), findsOneWidget);
      expect(find.byTooltip('Enable line focus guide'), findsOneWidget);
      expect(find.byTooltip('High-legibility letter spacing'), findsOneWidget);

      // Tap TTS audio read-aloud button
      await tester.tap(find.byTooltip('Read passage aloud (TTS)'));
      await tester.pumpAndSettle();

      // Verify "Reading Aloud..." indicator is visible
      expect(find.text('Reading Aloud...'), findsOneWidget);

      // Cycle font size (A -> A+)
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('A+'), findsOneWidget);

      // Select option
      final optionToSelect = find.text('His friendly puppy Milo');
      expect(optionToSelect, findsOneWidget);
      await tester.tap(optionToSelect);
      await tester.pumpAndSettle();

      expect(selectedValue, 'His friendly puppy Milo');
    });

    testWidgets('WordBuildingExerciseView supports tile pool and accessible Move Left / Move Right controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final wordBuildExercise = ExerciseModel(
        id: 'ex-dys-004',
        lessonId: 'lesson-dys-004',
        skillId: 'dys_spelling',
        exerciseType: 'word_building',
        prompt: 'Build the word: "ship"',
        instruction: 'Arrange the letter tiles to spell the word.',
        content: {
          'tiles': ['s', 'h', 'i', 'p'],
          'target_word': 'ship',
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dyslexia_track',
        sequenceOrder: 1,
      );

      List<String> assembled = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WordBuildingExerciseView(
                exercise: wordBuildExercise,
                currentTiles: assembled,
                onTilesChanged: (tiles) {
                  assembled = List.from(tiles);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Build the word: "ship"'), findsOneWidget);
      expect(find.text('Constructed Word'), findsOneWidget);
      expect(find.text('Available Sound & Letter Tiles'), findsOneWidget);

      // Initially, pool has s, h, i, p tiles
      expect(find.text('s'), findsOneWidget);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(find.text('p'), findsOneWidget);

      // Tap 's' tile from available pool
      await tester.tap(find.text('s'));
      await tester.pumpAndSettle();

      // Tap 'h' tile from available pool
      await tester.tap(find.text('h'));
      await tester.pumpAndSettle();

      expect(assembled.length, 2);
      expect(assembled[0], 's');
      expect(assembled[1], 'h');

      // Accessible reordering buttons (arrow_left) exist on the second tile
      final leftArrows = find.byIcon(Icons.arrow_left);
      expect(leftArrows, findsWidgets);

      // Tap move left on 'h' to swap 'h' and 's'
      await tester.tap(leftArrows.first);
      await tester.pumpAndSettle();

      expect(assembled[0], 'h');
      expect(assembled[1], 's');
    });

    testWidgets('PracticeHubScreen exposes both DLD and Dyslexia tracks independently',
        (WidgetTester tester) async {
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

      // Both tracks must be clearly visible and independent
      expect(find.text('Spoken Language (DLD) Practice Area'), findsOneWidget);
      expect(find.text('Literacy & Reading (Dyslexia) Practice Area'), findsOneWidget);

      // Non-diagnostic terminology guard
      expect(find.textContaining('disorder severity'), findsNothing);
      expect(find.textContaining('diagnostic score'), findsNothing);
    });
  });
}
