import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/learning/application/learning_providers.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_model.dart';
import 'package:lingua_ai/features/learning/domain/models/practice_hub_model.dart';
import 'package:lingua_ai/features/learning/presentation/screens/dld_track_dashboard_screen.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/listening_exercise_view.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/social_communication_exercise_view.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/narrative_sequencing_exercise_view.dart';
import '../helpers/mock_learning_repository.dart';

void main() {
  group('Phase 6 DLD Specific Learning Experience Tests', () {
    testWidgets('DldTrackDashboardScreen renders skill domains, age filters, and non-diagnostic copy',
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
            skillCode: 'dld_vocab',
            skillName: 'Vocabulary & Semantics',
            track: 'dld_track',
            completedLessons: 1,
            totalLessons: 2,
            masteryStatus: 'Practicing',
          ),
          SkillProgressItemModel(
            skillId: 's2',
            skillCode: 'dld_grammar',
            skillName: 'Grammar & Morphology',
            track: 'dld_track',
            completedLessons: 0,
            totalLessons: 2,
            masteryStatus: 'Developing',
          ),
          SkillProgressItemModel(
            skillId: 's3',
            skillCode: 'dld_sentence',
            skillName: 'Sentence Formulation',
            track: 'dld_track',
            completedLessons: 0,
            totalLessons: 2,
            masteryStatus: 'Starting',
          ),
          SkillProgressItemModel(
            skillId: 's4',
            skillCode: 'dld_listening',
            skillName: 'Listening Comprehension',
            track: 'dld_track',
            completedLessons: 2,
            totalLessons: 2,
            masteryStatus: 'Consistent',
          ),
          SkillProgressItemModel(
            skillId: 's5',
            skillCode: 'dld_narrative',
            skillName: 'Narrative & Discourse',
            track: 'dld_track',
            completedLessons: 1,
            totalLessons: 2,
            masteryStatus: 'Practicing',
          ),
          SkillProgressItemModel(
            skillId: 's6',
            skillCode: 'dld_pragmatics',
            skillName: 'Social Communication & Pragmatics',
            track: 'dld_track',
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
            home: DldTrackDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Spoken Language (DLD)'), findsOneWidget);
      expect(find.text('Spoken Language Learning Area'), findsOneWidget);
      expect(find.text('DLD Practice Domains'), findsOneWidget);
      expect(find.textContaining('Targeted everyday language practice'), findsOneWidget);

      // Verify DLD Skill Domains
      expect(find.text('Vocabulary & Semantics'), findsOneWidget);
      expect(find.text('Grammar & Morphology'), findsOneWidget);
      expect(find.text('Sentence Formulation'), findsOneWidget);
      expect(find.text('Listening Comprehension'), findsOneWidget);
      expect(find.text('Narrative & Discourse'), findsOneWidget);
      expect(find.text('Social Communication & Pragmatics'), findsOneWidget);

      // Verify Age-Band Filter Dropdown and Available Lessons
      expect(find.text('Available DLD Lessons'), findsOneWidget);
      expect(find.text('All Ages'), findsOneWidget);

      // Verify Non-diagnostic terminology guard
      expect(find.textContaining('You have DLD'), findsNothing);
      expect(find.textContaining('Your DLD score'), findsNothing);
      expect(find.textContaining('severity'), findsNothing);
    });

    testWidgets('ListeningExerciseView renders audio controls, transcript toggle, and options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final listeningExercise = ExerciseModel(
        id: 'ex-dld-006',
        lessonId: 'lesson-dld-006',
        skillId: 'dld_listening_comp',
        exerciseType: 'listening_comprehension',
        prompt: 'Listen carefully to the instructions and select the first step.',
        instruction: 'Tap play to listen, or view the transcript for accessible reading.',
        content: {
          'transcript': 'First, open your drawing book. Then, find the blue pencil on your desk.',
          'options': [
            'Find the blue pencil',
            'Open your drawing book',
            'Close the backpack',
          ],
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dld_track',
        sequenceOrder: 1,
      );

      String? selectedValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ListeningExerciseView(
                  exercise: listeningExercise,
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

      // Check prompt & instruction
      expect(find.text('Listen carefully to the instructions and select the first step.'), findsOneWidget);
      expect(find.text('Spoken Audio Direction'), findsOneWidget);

      // Initially, transcript is hidden
      expect(find.text('"First, open your drawing book. Then, find the blue pencil on your desk."'), findsNothing);
      expect(find.text('Show Spoken Transcript'), findsOneWidget);

      // Tap toggle to show transcript
      await tester.tap(find.text('Show Spoken Transcript'));
      await tester.pumpAndSettle();

      // Now transcript is visible
      expect(find.text('"First, open your drawing book. Then, find the blue pencil on your desk."'), findsOneWidget);
      expect(find.text('Hide Spoken Transcript'), findsOneWidget);

      // Tap an answer option
      final optionFinder = find.text('Open your drawing book');
      expect(optionFinder, findsOneWidget);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      expect(selectedValue, 'Open your drawing book');
    });

    testWidgets('SocialCommunicationExerciseView renders scenario context and allows selecting pragmatic response',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final socialExercise = ExerciseModel(
        id: 'ex-dld-012',
        lessonId: 'lesson-dld-012',
        skillId: 'dld_pragmatics',
        exerciseType: 'social_communication',
        prompt: 'Choose the most constructive way to ask for clarification on group homework.',
        instruction: 'Read the scenario and select the most appropriate response.',
        content: {
          'scenario': 'Your classmate gives fast, unclear instructions about who does which part of the group presentation.',
          'options': [
            'Say nothing and hope someone else does it.',
            'Could you clarify which slides you would like me to prepare?',
            'Your instructions make no sense at all.',
          ],
        },
        difficulty: 2,
        ageBand: 'teen',
        track: 'dld_track',
        sequenceOrder: 1,
      );

      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialCommunicationExerciseView(
                exercise: socialExercise,
                selectedOption: selectedValue,
                onSelectOption: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check scenario context
      expect(find.text('Real-World Scenario'), findsOneWidget);
      expect(find.textContaining('Your classmate gives fast, unclear instructions'), findsOneWidget);

      // Check options
      final constructiveChoice = find.text('Could you clarify which slides you would like me to prepare?');
      expect(constructiveChoice, findsOneWidget);

      await tester.tap(constructiveChoice);
      await tester.pumpAndSettle();

      expect(selectedValue, 'Could you clarify which slides you would like me to prepare?');
    });

    testWidgets('NarrativeSequencingExerciseView supports accessible Move Up / Move Down buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final narrativeExercise = ExerciseModel(
        id: 'ex-dld-004',
        lessonId: 'lesson-dld-004',
        skillId: 'dld_narrative',
        exerciseType: 'narrative_sequencing',
        prompt: 'Put the story steps into the correct chronological order.',
        instruction: 'Use the up/down arrows or drag to arrange the cards.',
        content: {
          'events': [
            {'id': 'e1', 'text': 'Mia planted a sunflower seed in the garden.'},
            {'id': 'e2', 'text': 'She watered it every morning as the sun rose.'},
            {'id': 'e3', 'text': 'A bright yellow sunflower blossomed.'},
          ],
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dld_track',
        sequenceOrder: 1,
      );

      List<String> currentOrder = ['e1', 'e2', 'e3'];
      List<String>? orderedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NarrativeSequencingExerciseView(
                exercise: narrativeExercise,
                currentOrder: currentOrder,
                onOrderChanged: (order) {
                  orderedIds = order;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially loaded in order e1, e2, e3
      expect(find.text('Mia planted a sunflower seed in the garden.'), findsOneWidget);
      expect(find.text('She watered it every morning as the sun rose.'), findsOneWidget);
      expect(find.text('A bright yellow sunflower blossomed.'), findsOneWidget);

      // Accessible move buttons exist
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      expect(find.byIcon(Icons.arrow_downward), findsWidgets);

      // Tap Move Down on the first item (index 0)
      final downButtons = find.byIcon(Icons.arrow_downward);
      await tester.tap(downButtons.first);
      await tester.pumpAndSettle();

      // The order should now have changed such that e2 is first, e1 is second
      expect(orderedIds, isNotNull);
      expect(orderedIds![0], 'e2');
      expect(orderedIds![1], 'e1');
      expect(orderedIds![2], 'e3');
    });
  });
}
