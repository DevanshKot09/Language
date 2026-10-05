import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_live_session_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  final testSpecialistUser = AuthUser(
    id: 'spec-user-id',
    email: 'specialist.sarah@lingua.ai',
    role: UserRole.specialist,
    status: 'active',
    createdAt: DateTime.now(),
  );

  const testSpecialistProfile = UserProfile(
    id: 'prof-spec-001',
    userId: 'spec-user-id',
    displayName: 'Dr. Sarah Jenkins',
    ageBand: AgeBand.adult,
    supportFocus: SupportTrack.multimodalBoth,
    baselineStatus: 'completed',
  );

  Widget buildTestableWidget({
    UserRole role = UserRole.specialist,
    dynamic sessionArg,
  }) {
    return ProviderScope(
      overrides: [
        userSessionProvider.overrideWith(
          () => _MockUserSessionNotifier(
            UserSessionState(
              status: SessionStatus.authenticated,
              currentUser: testSpecialistUser,
              profile: testSpecialistProfile,
              currentRole: role,
              activeTrack: SupportTrack.dldSpokenLanguage,
              isOnboardingCompleted: true,
              learnerName: 'Dr. Sarah Jenkins',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: SpecialistLiveSessionScreen(
          sessionOrLearner: sessionArg,
        ),
      ),
    );
  }

  group('Specialist Live Support Session — Stitch Reference UI & Interaction Tests', () {
    testWidgets('Renders all primary visual elements matching Stitch reference', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // 1. Top App Bar
      expect(find.byKey(const Key('live_session_close_button')), findsOneWidget);
      expect(find.text('Specialist Live Session'), findsOneWidget);
      expect(find.byKey(const Key('live_session_options_button')), findsOneWidget);
      expect(find.byKey(const Key('live_session_specialist_avatar')), findsOneWidget);

      // 2. Learner Identity Header
      expect(find.text('Aarav Mehta'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('live_session_timer_badge')), findsOneWidget);
      expect(find.textContaining('18:'), findsOneWidget); // Live timer string
      expect(find.textContaining('Age 10 • Consonant Clusters • Session 3'), findsOneWidget);
      expect(find.byKey(const Key('live_session_quick_report_button')), findsOneWidget);

      // 3. Main Session Surface (Deep Navy Card)
      expect(find.text('Live Audio'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Focus: Phoneme /r/ • Card 4/8'), findsOneWidget);
      expect(find.byKey(const Key('live_session_praise_button')), findsOneWidget);

      // 4. Session Tools Section
      expect(find.text('SESSION TOOLS'), findsOneWidget);
      expect(find.byKey(const Key('session_tool_cards')), findsOneWidget);
      expect(find.byKey(const Key('session_tool_pacer')), findsOneWidget);
      expect(find.byKey(const Key('session_tool_notes')), findsOneWidget);
      expect(find.byKey(const Key('session_tool_reward')), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Pacer'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Reward'), findsOneWidget);

      // 5. Learner Guidance Card
      expect(find.text('Learner Guidance'), findsOneWidget);
      expect(find.text('Tier'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Pacing & /r/ consonant clusters'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Mastered 12 cards (88% accuracy)'), findsOneWidget);
      expect(find.byKey(const Key('live_session_view_profile_link')), findsOneWidget);
      expect(find.text('Updated 2h ago'), findsOneWidget);

      // 6. Bottom Session Controls Bar
      expect(find.byKey(const Key('control_mic_toggle')), findsOneWidget);
      expect(find.byKey(const Key('control_camera_toggle')), findsOneWidget);
      expect(find.byKey(const Key('control_speaker_toggle')), findsOneWidget);
      expect(find.byKey(const Key('control_materials_button')), findsOneWidget);
      expect(find.byKey(const Key('control_end_session_button')), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('Tapping Praise sends feedback to learner', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byKey(const Key('live_session_praise_button')));
      await tester.pump();

      expect(find.textContaining('Praise sent to Aarav Mehta'), findsOneWidget);
    });

    testWidgets('Tapping Cards opens practice cards modal and allows navigation', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('session_tool_cards')));
      await tester.pumpAndSettle();

      expect(find.text('Practice Cards (4/8)'), findsOneWidget);
      expect(find.text('Ring'), findsOneWidget);

      // Tap Next Card
      await tester.tap(find.text('Next Card'));
      await tester.pumpAndSettle();

      expect(find.text('Practice Cards (5/8)'), findsOneWidget);
      expect(find.text('Grass'), findsOneWidget);
    });

    testWidgets('Tapping Pacer opens speech cadence pacer modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('session_tool_pacer')));
      await tester.pumpAndSettle();

      expect(find.text('Speech Cadence Pacer'), findsOneWidget);
      expect(find.text('64 BPM'), findsOneWidget);
      expect(find.text('Start Pacer'), findsOneWidget);

      await tester.tap(find.text('Start Pacer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pacer active'), findsOneWidget);
    });

    testWidgets('Tapping Notes opens learning support notes modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('session_tool_notes')));
      await tester.pumpAndSettle();

      expect(find.text('Add Learning Support Note'), findsOneWidget);
      expect(find.text('Save Note'), findsOneWidget);

      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      expect(find.text('Learning support observation saved.'), findsOneWidget);
    });

    testWidgets('Tapping Reward awards practice stars to learner', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('session_tool_reward')));
      await tester.pump();

      expect(find.textContaining('5 Practice Stars awarded'), findsOneWidget);
    });

    testWidgets('Session control toggles: mic, camera, speaker, materials', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Mic toggle
      await tester.tap(find.byKey(const Key('control_mic_toggle')));
      await tester.pump();
      expect(find.text('Microphone muted'), findsOneWidget);

      // Camera toggle
      await tester.tap(find.byKey(const Key('control_camera_toggle')));
      await tester.pump();
      expect(find.text('Camera active'), findsOneWidget);

      // Speaker toggle
      await tester.tap(find.byKey(const Key('control_speaker_toggle')));
      await tester.pump();
      expect(find.text('Audio output muted'), findsOneWidget);

      // Materials button
      await tester.tap(find.byKey(const Key('control_materials_button')));
      await tester.pumpAndSettle();
      expect(find.text('Curriculum Materials & Targets'), findsOneWidget);
    });

    testWidgets('End Session flow: shows confirmation dialog, cancels or completes session', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap End button
      await tester.tap(find.byKey(const Key('control_end_session_button')));
      await tester.pumpAndSettle();

      expect(find.text('End this session?'), findsOneWidget);
      expect(find.text('Continue Session'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);

      // Tap Continue Session
      await tester.tap(find.text('Continue Session'));
      await tester.pumpAndSettle();
      expect(find.text('End this session?'), findsNothing);

      // Tap End again and confirm
      await tester.tap(find.byKey(const Key('control_end_session_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Session'));
      await tester.pumpAndSettle();

      // Completed View
      expect(find.text('Session Completed!'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Focus Area'), findsOneWidget);
      expect(find.byKey(const Key('completed_add_note_button')), findsOneWidget);
      expect(find.byKey(const Key('completed_return_button')), findsOneWidget);
    });

    testWidgets('Restricted role displays security access notice', (tester) async {
      await tester.pumpWidget(buildTestableWidget(role: UserRole.parent));
      await tester.pump();

      expect(find.text('Specialist Access Scoped'), findsOneWidget);
      expect(find.text('Return to Login'), findsOneWidget);
    });

    testWidgets('Responsive Layout: No overflow on 320px, 360px, 390px, 430px widths', (tester) async {
      const widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'No overflow at width $w');
      }
      tester.view.resetPhysicalSize();
    });
  });
}

class _MockUserSessionNotifier extends UserSessionNotifier {
  final UserSessionState _initialState;

  _MockUserSessionNotifier(this._initialState);

  @override
  UserSessionState build() => _initialState;

  @override
  Future<void> restoreSession() async {
    state = _initialState;
  }
}
