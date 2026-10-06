import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_availability_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_verification_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_help_support_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  final testSpecialistUser = AuthUser(
    id: 'spec-user-id',
    email: 'specialist.lin@lingua.ai',
    role: UserRole.specialist,
    status: 'active',
    createdAt: DateTime.now(),
  );

  const testSpecialistProfile = UserProfile(
    id: 'prof-spec-001',
    userId: 'spec-user-id',
    displayName: 'Dr. Maya Lin, M.S. CCC-SLP',
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
              learnerName: 'Maya Lin',
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

  group('SCREEN 1 — AVAILABILITY & APPOINTMENT SETTINGS (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistAvailabilityScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Availability Settings'), findsOneWidget);
      expect(find.byKey(const Key('availability_back_button')), findsOneWidget);

      // Specialist Header Card
      expect(find.text('Dr. Maya Lin, M.S. CCC-SLP'), findsOneWidget);
      expect(find.text('Pediatric Speech & Phoneme Coaching'), findsOneWidget);
      expect(find.textContaining('ACTIVE CASELOAD'), findsOneWidget);

      // Accepting Requests Card
      expect(find.text('ACCEPTING REQUESTS'), findsOneWidget);
      expect(find.text('Available for sessions'), findsOneWidget);
      expect(find.byKey(const Key('available_for_sessions_toggle')), findsOneWidget);
      expect(find.text('SPECIALIST TIME ZONE'), findsOneWidget);
      expect(find.text('Pacific Time (GMT-7)'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Weekly Schedule
      expect(find.text('Weekly Schedule'), findsOneWidget);
      expect(find.text('Copy M-F'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday & Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);

      // Active Slots
      expect(find.text('9:00 AM – 12:00 PM'), findsWidgets);
      expect(find.text('1:30 PM – 5:00 PM'), findsWidgets);

      // Session Preferences
      expect(find.text('ERGONOMICS & ENERGY'), findsOneWidget);
      expect(find.text('Session Preferences'), findsOneWidget);
      expect(find.text('Standard Session Duration'), findsOneWidget);
      expect(find.text('30 Minutes'), findsOneWidget);
      expect(find.text('45 Minutes'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('60 Minutes'), findsOneWidget);

      // Buffers & Cap
      expect(find.text('Buffer Between Sessions'), findsOneWidget);
      expect(find.text('15 min ⚡'), findsOneWidget);
      expect(find.text('Daily Session Cap'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Advance Notice'), findsOneWidget);
      expect(find.text('24h Notice'), findsOneWidget);

      // Bottom Button
      expect(find.byKey(const Key('save_availability_button')), findsOneWidget);
      expect(find.text('Save Availability'), findsOneWidget);
    });

    testWidgets('Toggles sessions availability and updates daily cap', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistAvailabilityScreen()));
      await tester.pumpAndSettle();

      // Tap toggle
      await tester.tap(find.byKey(const Key('available_for_sessions_toggle')));
      await tester.pumpAndSettle();

      // Tap increment daily cap
      await tester.scrollUntilVisible(find.byKey(const Key('cap_increment_button')), 100);
      await tester.tap(find.byKey(const Key('cap_increment_button')));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);

      // Tap duration 60 minutes
      await tester.scrollUntilVisible(find.byKey(const Key('duration_option_60')), 100);
      await tester.tap(find.byKey(const Key('duration_option_60')));
      await tester.pumpAndSettle();

      // Tap Save Availability
      await tester.scrollUntilVisible(find.byKey(const Key('save_availability_button')), 100);
      await tester.tap(find.byKey(const Key('save_availability_button')));
      await tester.pumpAndSettle();
      expect(find.text('Availability Saved!'), findsOneWidget);
    });

    testWidgets('Responsive mobile rendering at 320, 360, 390, 430 px without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1200 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestApp(const SpecialistAvailabilityScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Availability Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('SCREEN 2 — SPECIALIST VERIFICATION STATUS (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistVerificationScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Verification Status'), findsOneWidget);
      expect(find.byKey(const Key('verification_back_button')), findsOneWidget);

      // Verified Hero Card
      expect(find.text('PROFILE VERIFIED'), findsOneWidget);
      expect(find.text('Your profile is verified'), findsOneWidget);
      expect(find.textContaining('specialist credentials and child-safety'), findsOneWidget);
      expect(find.textContaining('Verified Oct 14, 2024'), findsOneWidget);

      // Review Milestones
      expect(find.text('Review Milestones'), findsOneWidget);
      expect(find.text('5 of 5 Complete'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Degrees'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Badge'), findsOneWidget);

      // Specialist Details Card
      expect(find.text('Specialist Details'), findsOneWidget);
      expect(find.byKey(const Key('edit_profile_link')), findsOneWidget);
      expect(find.text('MR'), findsOneWidget);
      expect(find.text('Maya Reynolds, M.S.'), findsOneWidget);
      expect(find.text('Learning Support Specialist (CCC-SLP)'), findsOneWidget);
      expect(find.text('8+ Yrs Pediatric'), findsOneWidget);
      expect(find.text('English, Spanish'), findsOneWidget);
      expect(find.text('APPROVED SUPPORT DOMAINS'), findsOneWidget);
      expect(find.text('Reading Fluency'), findsOneWidget);
      expect(find.text('Speech & Pacing'), findsOneWidget);
      expect(find.text('Phonics & Spelling'), findsOneWidget);
      expect(find.text('Vocabulary Growth'), findsOneWidget);

      // Verified Documents
      expect(find.text('Verified Documents'), findsOneWidget);
      expect(find.text('Encrypted • FERPA Compliant'), findsOneWidget);
      expect(find.text('M.S. in Speech & Hearing Sciences'), findsOneWidget);
      expect(find.text('Clinical Competence Certification (CCC-SLP)'), findsOneWidget);
      expect(find.text('Child-Safe & Background Clearance'), findsOneWidget);
      expect(find.text('Approved'), findsNWidgets(2));
      expect(find.text('Cleared'), findsOneWidget);

      // Help Banner
      expect(find.byKey(const Key('verification_help_banner')), findsOneWidget);
    });

    testWidgets('Responsive mobile rendering at 320, 360, 390, 430 px without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1200 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestApp(const SpecialistVerificationScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Verification Status'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('SCREEN 3 — HELP & SUPPORT (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistHelpSupportScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.byKey(const Key('help_back_button')), findsOneWidget);

      // Search Bar
      expect(find.byKey(const Key('help_search_field')), findsOneWidget);

      // Browse by Topic 8 Categories
      expect(find.text('Browse by Topic'), findsOneWidget);
      expect(find.text('8 categories'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Learners'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Consent'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);

      // Frequently Asked Questions
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('View all (24)'), findsOneWidget);
      expect(find.text('How do I update my weekly availability hours?'), findsOneWidget);
      expect(find.text('How does learner guardian consent work?'), findsOneWidget);
      expect(find.text('How do I start a live learning session?'), findsOneWidget);
      expect(find.text('How do I edit my professional qualifications?'), findsOneWidget);

      // Still Need Help?
      expect(find.text('Still need help?'), findsOneWidget);
      expect(find.byKey(const Key('help_send_message_button')), findsOneWidget);
      expect(find.byKey(const Key('help_report_problem_button')), findsOneWidget);
      expect(find.byKey(const Key('help_schedule_walkthrough_button')), findsOneWidget);

      // System Status & Footer
      expect(find.text('All Systems Operational'), findsOneWidget);
      expect(find.text('Live Status'), findsOneWidget);
      expect(find.text('SUPPORT DESK HOURS'), findsOneWidget);
      expect(find.text('Mon–Fri, 8 AM–8 PM EST'), findsOneWidget);
      expect(find.text('AVG RESPONSE'), findsOneWidget);
      expect(find.text('< 15 mins during desk hours'), findsOneWidget);
      expect(find.text('Lingua Specialist v2.4.1 (Build 842)'), findsOneWidget);
      expect(find.text('Release Notes'), findsOneWidget);
    });

    testWidgets('Expands FAQ item and filters via search', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistHelpSupportScreen()));
      await tester.pumpAndSettle();

      // Tap FAQ 1 to expand
      final faqFinder = find.byKey(const Key('faq_item_faq_availability'));
      await tester.scrollUntilVisible(
        faqFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(faqFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Navigate to Availability Settings to toggle individual days'), findsOneWidget);

      // Search for non-existent keyword
      await tester.enterText(find.byKey(const Key('help_search_field')), 'xyznonexistent123');
      await tester.pumpAndSettle();
      expect(find.text('No help articles found'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byKey(const Key('help_search_field')), '');
      await tester.pumpAndSettle();
      expect(find.text('How do I update my weekly availability hours?'), findsOneWidget);
    });

    testWidgets('Opens Report Problem sheet and submits issue', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistHelpSupportScreen()));
      await tester.pumpAndSettle();

      // Scroll down to Report a Problem button
      await tester.scrollUntilVisible(
        find.byKey(const Key('help_report_problem_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('help_report_problem_button')));
      await tester.pumpAndSettle();

      expect(find.text('Tell us what went wrong so our technical specialists can investigate.'), findsOneWidget);

      // Fill in description
      await tester.enterText(
        find.byKey(const Key('report_problem_description_field')),
        'Audio sync delay during interactive drill.',
      );
      await tester.tap(find.byKey(const Key('submit_problem_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ticket received!'), findsOneWidget);
    });

    testWidgets('Responsive mobile rendering at 320, 360, 390, 430 px without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1200 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestApp(const SpecialistHelpSupportScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Help & Support'), findsOneWidget);
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
}
