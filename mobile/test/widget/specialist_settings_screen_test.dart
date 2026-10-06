import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_settings_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  final testSpecialistUser = AuthUser(
    id: 'spec-user-id',
    email: 'maya.reynolds@lingua.ai',
    role: UserRole.specialist,
    status: 'active',
    createdAt: DateTime.now(),
  );

  const testSpecialistProfile = UserProfile(
    id: 'prof-spec-001',
    userId: 'spec-user-id',
    displayName: 'Maya Reynolds, M.S.',
    ageBand: AgeBand.adult,
    supportFocus: SupportTrack.multimodalBoth,
    baselineStatus: 'completed',
  );

  Widget createTestApp(Widget home) {
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
              learnerName: 'Maya Reynolds',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRouter.generateRoute,
        home: home,
      ),
    );
  }

  group('SPECIALIST SETTINGS SCREEN (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.text('Specialist Settings'), findsOneWidget);
      expect(find.byKey(const Key('settings_back_button')), findsOneWidget);

      // Profile / Account Summary Card
      expect(find.text('Maya Reynolds, M.S.'), findsOneWidget);
      expect(find.text('Learning Support Specialist (CCC-SLP)'), findsOneWidget);
      expect(find.text('Profile Verified'), findsOneWidget);
      expect(find.textContaining('18 Active Learners'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);

      // Section 1: SPECIALIST ACCOUNT
      expect(find.text('SPECIALIST ACCOUNT'), findsOneWidget);
      expect(find.text('FERPA Safe'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Availability & Appointments'), findsOneWidget);
      expect(find.text('Verification Status'), findsOneWidget);
      expect(find.text('Change Password & Security'), findsOneWidget);

      // Section 2: LIVE NOTIFICATIONS
      expect(find.text('LIVE NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Push & Sound'), findsOneWidget);
      expect(find.text('Session Reminders'), findsOneWidget);
      expect(find.text('Consent & Sharing Alerts'), findsOneWidget);
      expect(find.text('Learner & Parent Messages'), findsOneWidget);
      expect(find.text('Appointment Requests'), findsOneWidget);
      expect(find.text('Weekly Progress Digests'), findsOneWidget);

      // Section 3: CHILD SAFETY & CONSENT
      expect(find.text('CHILD SAFETY & CONSENT'), findsOneWidget);
      expect(find.text('Consent & Sharing Center'), findsOneWidget);
      expect(find.text('Profile Visibility'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Data & Privacy Controls'), findsOneWidget);

      // Scroll down to view lower sections
      await tester.scrollUntilVisible(
        find.text('SUPPORT & COMMUNITY'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Section 4: ACCESSIBILITY & COMFORT
      expect(find.text('ACCESSIBILITY & COMFORT'), findsOneWidget);
      expect(find.text('Larger Text / Dynamic Type'), findsOneWidget);
      expect(find.text('Reduce Motion'), findsOneWidget);
      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(find.text('Haptic Touch Feedback'), findsOneWidget);

      // Section 5: SPECIALIST STUDIO
      expect(find.text('SPECIALIST STUDIO'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
      expect(find.text('Appearance / Theme'), findsOneWidget);
      expect(find.text('Light (Playful)'), findsOneWidget);
      expect(find.text('Specialist Time Zone'), findsOneWidget);
      expect(find.text('Audio & Sound FX'), findsOneWidget);

      // Section 6: SUPPORT & COMMUNITY
      expect(find.text('Help & Resource Center'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('Contact Specialist Desk'), findsOneWidget);

      // Log Out Button
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_logout_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_logout_button')), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Footer
      expect(find.textContaining('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Lingua Specialist Suite v2.4.1'), findsOneWidget);
      expect(find.text('Safe, playful speech learning ecosystem'), findsOneWidget);
    });

    testWidgets('Toggles notification and accessibility preferences smoothly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
      await tester.pumpAndSettle();

      // Session Reminders switch
      final reminderSwitch = find.byKey(const Key('toggle_session_reminders'));
      expect(reminderSwitch, findsOneWidget);
      CupertinoSwitch sw1 = tester.widget(reminderSwitch);
      expect(sw1.value, isTrue);

      // Tap to toggle OFF
      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();
      sw1 = tester.widget(reminderSwitch);
      expect(sw1.value, isFalse);

      // Weekly Progress Digests switch (default false)
      final digestSwitch = find.byKey(const Key('toggle_weekly_progress_digests'));
      expect(digestSwitch, findsOneWidget);
      CupertinoSwitch sw2 = tester.widget(digestSwitch);
      expect(sw2.value, isFalse);

      // Tap to toggle ON
      await tester.tap(digestSwitch);
      await tester.pumpAndSettle();
      sw2 = tester.widget(digestSwitch);
      expect(sw2.value, isTrue);

      // Scroll to accessibility toggles
      await tester.scrollUntilVisible(
        find.byKey(const Key('toggle_larger_text')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final largerTextSwitch = find.byKey(const Key('toggle_larger_text'));
      expect(largerTextSwitch, findsOneWidget);
      CupertinoSwitch sw3 = tester.widget(largerTextSwitch);
      expect(sw3.value, isFalse);

      await tester.tap(largerTextSwitch);
      await tester.pumpAndSettle();
      sw3 = tester.widget(largerTextSwitch);
      expect(sw3.value, isTrue);

      // Audio & Sound FX toggle
      await tester.scrollUntilVisible(
        find.byKey(const Key('toggle_audio_sound_fx')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final audioFxSwitch = find.byKey(const Key('toggle_audio_sound_fx'));
      expect(audioFxSwitch, findsOneWidget);
      CupertinoSwitch sw4 = tester.widget(audioFxSwitch);
      expect(sw4.value, isTrue);

      await tester.tap(audioFxSwitch);
      await tester.pumpAndSettle();
      sw4 = tester.widget(audioFxSwitch);
      expect(sw4.value, isFalse);
    });

    testWidgets('Opens Profile Visibility bottom sheet and updates selection', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
      await tester.pumpAndSettle();

      // Tap Profile Visibility row
      await tester.tap(find.byKey(const Key('settings_row_profile_visibility')));
      await tester.pumpAndSettle();

      // Bottom sheet header
      expect(find.text('Specialist Profile Visibility'), findsOneWidget);
      expect(find.text('Enrolled Schools Only'), findsOneWidget);

      // Select 'Enrolled Schools Only'
      await tester.tap(find.text('Enrolled Schools Only'));
      await tester.pumpAndSettle();

      // Verified updated on main screen
      expect(find.text('Enrolled Schools Only'), findsOneWidget);
    });

    testWidgets('Opens Report a Problem dialog and submits feedback', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_report_problem')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_row_report_problem')));
      await tester.pumpAndSettle();

      expect(find.text('Report a Problem'), findsWidgets);
      expect(find.byKey(const Key('settings_report_problem_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings_report_problem_field')),
        'Phoneme playback delay on card 4.',
      );
      await tester.tap(find.byKey(const Key('settings_submit_problem_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Report received!'), findsOneWidget);
    });

    testWidgets('Log Out confirmation dialog workflow (Cancel & Confirm)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
      await tester.pumpAndSettle();

      // Scroll to logout button
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_logout_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Log Out button
      await tester.tap(find.byKey(const Key('settings_logout_button')));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Log Out of LINGUA AI?'), findsOneWidget);
      expect(find.byKey(const Key('logout_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('logout_confirm_button')), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const Key('logout_cancel_button')));
      await tester.pumpAndSettle();
      expect(find.text('Log Out of LINGUA AI?'), findsNothing);

      // Tap Log Out again and Confirm
      await tester.tap(find.byKey(const Key('settings_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout_confirm_button')));
      await tester.pumpAndSettle();

      // Success without unhandled exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive mobile rendering at 320, 360, 390, 430 px without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1200 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestApp(const SpecialistSettingsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Specialist Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });
}

class _MockUserSessionNotifier extends UserSessionNotifier {
  final UserSessionState _initial;
  _MockUserSessionNotifier(this._initial);

  @override
  UserSessionState build() => _initial;

  @override
  Future<void> logout() async {
    state = state.copyWith(status: SessionStatus.unauthenticated);
  }
}
