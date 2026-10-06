import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_session_summary_screen.dart';
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
              currentRole: UserRole.specialist,
              activeTrack: SupportTrack.dldSpokenLanguage,
              isOnboardingCompleted: true,
              learnerName: 'Dr. Sarah Jenkins',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRouter.generateRoute,
        home: SpecialistSessionSummaryScreen(
          sessionOrSummary: sessionArg,
        ),
      ),
    );
  }

  group('Specialist — Session Summary & Notes (Stitch Reference UI & Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch reference', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.byKey(const Key('session_summary_back_button')), findsOneWidget);
      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.text('DRAFT AUTO-SAVED'), findsOneWidget);
      expect(find.byKey(const Key('session_summary_options_button')), findsOneWidget);

      // 2. Learner Identity Header Card
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Child • 10 yrs'), findsOneWidget);
      expect(find.text('1-to-1 Live Support'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Today, Oct 17'), findsOneWidget);
      expect(find.text('10:30 – 11:02 AM'), findsOneWidget);
      expect(find.text('31 min'), findsOneWidget);

      // 3. 2x2 Metric Cards
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Cards completed'), findsOneWidget);
      expect(find.text('/r/ Blends'), findsOneWidget);
      expect(find.text('Target sound focus'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('Pacing rhythm'), findsOneWidget);
      expect(find.text('1 Rec'), findsOneWidget);
      expect(find.text('Audio reflection'), findsOneWidget);

      // 4. What did you work on?
      expect(find.text('What did you work on?'), findsOneWidget);
      expect(find.text('Tap to toggle'), findsOneWidget);
      expect(find.text('Phonics & Blends'), findsOneWidget);
      expect(find.text('Speaking & Pacing'), findsOneWidget);
      expect(find.text('Reading Aloud'), findsOneWidget);
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('Listening Comprehension'), findsOneWidget);

      // 5. Session Observations & Notes
      expect(find.text('Session Observations & Notes'), findsOneWidget);
      expect(find.text('Live Draft'), findsOneWidget);
      expect(find.byKey(const Key('session_summary_notes_field')), findsOneWidget);
      expect(find.text('Lingua AI Co-Writer Ready'), findsOneWidget);
      expect(find.text('TAP TO INSERT NOTE TAG:'), findsOneWidget);
      expect(find.text('+ Great engagement'), findsOneWidget);
      expect(find.text('+ Self-corrected pacing'), findsOneWidget);

      // 6. How did today's session go?
      expect(find.text("How did today's session go?"), findsOneWidget);
      expect(find.text('Great progress'), findsOneWidget);
      expect(find.text('Good progress'), findsOneWidget);
      expect(find.text('Steady practice'), findsOneWidget);
      expect(find.text('Needs support'), findsOneWidget);

      // 7. Next Practice Focus
      expect(find.text('Next Practice Focus'), findsOneWidget);
      expect(find.text('Change focus'), findsOneWidget);
      expect(find.text('Consonant Clusters (/rk/, /st/) in 2-syllable words'), findsOneWidget);

      // 8. Follow-up Actions
      expect(find.text('Follow-up Actions'), findsOneWidget);
      expect(find.text('2 of 4 selected'), findsOneWidget);
      expect(find.text('Send tailored /r/ practice cards to Parent'), findsOneWidget);
      expect(find.text('Share session highlight with Teacher'), findsOneWidget);
      expect(find.text('Schedule next live practice check-in'), findsOneWidget);
      expect(find.text('Update Caseload Milestone Tracker'), findsOneWidget);

      // 9. Next Session Scheduled
      expect(find.text('NEXT SESSION SCHEDULED'), findsOneWidget);
      expect(find.text('Friday, Oct 25 • 10:30 AM'), findsOneWidget);
      expect(find.text('Reschedule or edit'), findsOneWidget);

      // 10. CTAs
      expect(find.byKey(const Key('save_summary_primary_button')), findsOneWidget);
      expect(find.text('Save & Complete Summary'), findsOneWidget);
      expect(find.byKey(const Key('discard_draft_button')), findsOneWidget);
    });

    testWidgets('Interactive language pillar selection and toggling', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Vocabulary to add it to working pillars
      await tester.tap(find.text('Vocabulary'));
      await tester.pumpAndSettle();

      expect(find.text('UNSAVED CHANGES'), findsOneWidget);

      // Tap Reading Aloud to toggle it off
      await tester.tap(find.text('Reading Aloud'));
      await tester.pumpAndSettle();

      expect(find.text('UNSAVED CHANGES'), findsOneWidget);
    });

    testWidgets('Quick-tag inserts into Session Observations & Notes field', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Scroll to quick tag and tap
      await tester.scrollUntilVisible(
        find.text('+ Great engagement'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('+ Great engagement'));
      await tester.pumpAndSettle();

      final notesField = tester.widget<TextField>(find.byKey(const Key('session_summary_notes_field')));
      expect(notesField.controller?.text, contains('Great engagement'));
      expect(find.text('UNSAVED CHANGES'), findsOneWidget);
    });

    testWidgets('Outcome selection switches smoothly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('outcome_good_progress')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('outcome_good_progress')));
      await tester.pumpAndSettle();

      expect(find.text('UNSAVED CHANGES'), findsOneWidget);
    });

    testWidgets('Follow-up actions toggling updates selection count', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 of 4 selected'), findsOneWidget);

      // Scroll to follow-up actions
      await tester.scrollUntilVisible(
        find.text('Schedule next live practice check-in'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Schedule next live practice check-in'));
      await tester.pumpAndSettle();

      expect(find.text('3 of 4 selected'), findsOneWidget);
    });

    testWidgets('Save Summary validates notes and confirms save', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Clear notes to test empty notes validation
      await tester.enterText(find.byKey(const Key('session_summary_notes_field')), '');
      await tester.pumpAndSettle();

      // Attempt save with empty notes triggers validation message
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_summary_primary_button')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save_summary_primary_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter session observations'), findsOneWidget);

      // Now add observation notes
      await tester.scrollUntilVisible(
        find.byKey(const Key('session_summary_notes_field')),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('session_summary_notes_field')),
        'Aarav engaged enthusiastically with the /r/ consonant clusters and achieved 88% pacing consistency.',
      );
      await tester.pumpAndSettle();

      // Save again
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_summary_primary_button')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save_summary_primary_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Session summary saved'), findsOneWidget);
    });

    testWidgets('Unsaved changes dialog prompts before discard', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Modify notes
      await tester.enterText(
        find.byKey(const Key('session_summary_notes_field')),
        'Initial test notes...',
      );
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byKey(const Key('session_summary_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Save your session notes?'), findsOneWidget);
      expect(find.byKey(const Key('dialog_discard_button')), findsOneWidget);
      expect(find.byKey(const Key('dialog_keep_editing_button')), findsOneWidget);
      expect(find.byKey(const Key('dialog_save_button')), findsOneWidget);

      // Keep editing closes dialog
      await tester.tap(find.byKey(const Key('dialog_keep_editing_button')));
      await tester.pumpAndSettle();

      expect(find.text('Save your session notes?'), findsNothing);
    });

    testWidgets('Responsive Layout: No overflow on 320px, 360px, 390px, 430px widths', (tester) async {
      const widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1100 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

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
