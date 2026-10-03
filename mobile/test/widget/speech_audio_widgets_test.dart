import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/audio_provider.dart';
import 'package:lingua_ai/core/audio/i_audio_permission_service.dart';
import 'package:lingua_ai/core/audio/audio_capabilities.dart';
import 'package:lingua_ai/features/speech/presentation/widgets/speech_interaction_widget.dart';
import 'package:lingua_ai/features/speech/presentation/widgets/microphone_permission_dialog.dart';
import 'package:lingua_ai/features/speech/presentation/screens/voice_privacy_center_screen.dart';
import 'package:lingua_ai/features/learning/presentation/widgets/speaking_practice_exercise_view.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_model.dart';
import '../unit/audio_speech_unit_test.dart';

void main() {
  group('Phase 8 Speech & Audio Widgets and UI Tests', () {
    late MockSttService mockStt;
    late MockAudioPermissionService mockPerm;

    setUp(() {
      mockStt = MockSttService();
      mockPerm = MockAudioPermissionService();
    });

    tearDown(() {
      mockStt.dispose();
    });

    testWidgets('MicrophonePermissionDialog renders non-coercive explanation and actions', (tester) async {
      bool granted = false;
      bool cancelled = false;
      bool typed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicrophonePermissionDialog(
              onGrant: () => granted = true,
              onCancel: () => cancelled = true,
              onTypeInstead: () => typed = true,
            ),
          ),
        ),
      );

      expect(find.text('Use Your Voice?'), findsOneWidget);
      expect(find.text('• We only listen when you tap Speak'), findsOneWidget);
      expect(find.text('• No permanent audio recordings are kept'), findsOneWidget);
      expect(find.text('• You can always choose to type instead'), findsOneWidget);
      expect(find.text('Type Instead'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(granted, isTrue);

      await tester.tap(find.text('Type Instead'));
      expect(typed, isTrue);

      await tester.tap(find.text('Not Now'));
      expect(cancelled, isTrue);
    });

    testWidgets('SpeechInteractionWidget renders ready state and starts listening on mic tap', (tester) async {
      mockPerm.currentStatus = MicrophonePermissionStatus.granted;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sttServiceProvider.overrideWithValue(mockStt),
            audioPermissionServiceProvider.overrideWithValue(mockPerm),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SpeechInteractionWidget(
                prompt: 'Describe what you did this morning.',
                onAnswerConfirmed: (ans) {},
                onTypeInstead: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Describe what you did this morning.'), findsOneWidget);
      expect(find.text('Tap to speak your answer'), findsOneWidget);
      expect(find.text('Type your answer instead'), findsOneWidget);

      // Tap microphone
      await tester.tap(find.byTooltip('Tap to speak'));
      await tester.pump();

      expect(find.text('Listening...'), findsOneWidget);
      expect(find.text('Done Speaking'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('SpeakingPracticeExerciseView switches to text input when Type Instead is chosen', (tester) async {
      mockPerm.currentStatus = MicrophonePermissionStatus.granted;

      final exercise = ExerciseModel(
        id: 'ex-speaking-1',
        lessonId: 'lesson-1',
        skillId: 'skill-1',
        exerciseType: 'speaking_practice',
        prompt: 'Tell us about a favorite hobby.',
        instruction: 'Practice speaking clearly using full sentences.',
        content: const {'prompt': 'Tell us about a favorite hobby.'},
        difficulty: 1,
        ageBand: 'teen',
        track: 'dld_track',
        sequenceOrder: 1,
      );

      String? submittedAnswer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sttServiceProvider.overrideWithValue(mockStt),
            audioPermissionServiceProvider.overrideWithValue(mockPerm),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SpeakingPracticeExerciseView(
                exercise: exercise,
                currentAnswer: submittedAnswer,
                onAnswerChanged: (ans) => submittedAnswer = ans,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Practice speaking clearly using full sentences.'), findsOneWidget);
      expect(find.text('Type your answer instead'), findsOneWidget);

      // Tap "Type your answer instead"
      await tester.tap(find.text('Type your answer instead'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Switch back to voice input'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'I enjoy playing the guitar');
      expect(submittedAnswer, equals('I enjoy playing the guitar'));
    });

    testWidgets('VoicePrivacyCenterScreen renders all retention and child protection policies', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPermissionServiceProvider.overrideWithValue(mockPerm),
            audioCapabilitiesProvider.overrideWith((ref) => Future.value(const AudioCapabilities(
              ttsSupported: true,
              sttSupported: true,
              microphoneAvailable: true,
              processingMode: SpeechProcessingMode.onDevice,
              supportsWordHighlighting: true,
              activeLocale: 'en-US',
            ))),
          ],
          child: const MaterialApp(
            home: VoicePrivacyCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Audio Privacy & Control Center'), findsOneWidget);
      expect(find.text('Zero Permanent Raw Audio Storage'), findsOneWidget);
      expect(find.text('Child Data Minimization (COPPA/GDPR-K Compliant)'), findsOneWidget);
      expect(find.text('Learner-Controlled Transcripts'), findsOneWidget);
      expect(find.text('Universal Type-In Fallback'), findsOneWidget);

      // Ensure no diagnostic terms appear in voice privacy center
      final bodyText = find.byType(Text);
      for (final widget in tester.widgetList<Text>(bodyText)) {
        final text = (widget.data ?? '').toLowerCase();
        expect(text.contains('pronunciation score'), isFalse);
        expect(text.contains('fluency score'), isFalse);
        expect(text.contains('disorder diagnosis'), isFalse);
      }
    });
  });
}
