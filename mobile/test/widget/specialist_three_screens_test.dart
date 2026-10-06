import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_profile_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_notifications_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_consent_sharing_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  final testSpecialistUser = AuthUser(
    id: 'spec-user-id',
    email: 'specialist.maya@lingua.ai',
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

  group('SCREEN 1 — SPECIALIST PROFILE (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistProfileScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      // Segmented Toggle
      expect(find.text('Specialist View'), findsOneWidget);
      expect(find.text('Learner Preview'), findsOneWidget);

      // Hero Card elements
      expect(find.text('Maya Reynolds, M.S.'), findsOneWidget);
      expect(find.text('Learning Support Specialist (CCC-SLP)'), findsOneWidget);
      expect(find.text('VERIFIED SPECIALIST • LINGUA SAFE'), findsOneWidget);
      expect(find.textContaining('San Francisco, CA'), findsOneWidget);
      expect(find.textContaining('new learner spots'), findsOneWidget);

      // 3 Stat tiles
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Active\nLearners'), findsOneWidget);
      expect(find.textContaining('4.9'), findsOneWidget);
      expect(find.text('42 Reviews'), findsOneWidget);
      expect(find.text('5 yrs'), findsOneWidget);
      expect(find.text('Lingua Guide'), findsOneWidget);

      // Cards
      expect(find.text('Profile Visibility'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      expect(find.text('Support Focus Areas'), findsOneWidget);
      expect(find.text('7 Areas'), findsOneWidget);
      expect(find.text('Practice Details'), findsOneWidget);
      expect(find.text('Credentials & Safety'), findsOneWidget);

      // Focus areas chips
      expect(find.text('Reading Fluency'), findsOneWidget);
      expect(find.text('Speech & Pacing'), findsOneWidget);
      expect(find.text('Phonics & Spelling'), findsOneWidget);

      // Practice details items
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('LANGUAGES'), findsOneWidget);
      expect(find.text('LEARNER AGE GROUPS'), findsOneWidget);
      expect(find.text('SUPPORTED FORMATS'), findsOneWidget);

      // Credentials items
      expect(find.text('M.S. in Speech & Hearing Sciences'), findsOneWidget);
      expect(find.text('Clinical Competence Certificate (CCC-SLP)'), findsOneWidget);
      expect(find.text('Lingua AI Child-Safe & HIPAA Verified'), findsOneWidget);

      // Non-diagnostic disclaimer
      expect(
        find.text('Lingua AI provides developmental learning facilitation and educational practice.'),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Edit Specialist Profile'), findsOneWidget);
      expect(find.text('Manage Schedule & Slots'), findsOneWidget);
      expect(
        find.textContaining('Protected by the Lingua AI Child-Safe Guarantee.'),
        findsOneWidget,
      );
    });

    testWidgets('Toggles View Mode between Specialist View and Learner Preview', (tester) async {
      await tester.pumpWidget(createTestApp(const SpecialistProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Learner Preview'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Specialist View'));
      await tester.pumpAndSettle();
    });

    testWidgets('Expands and collapses About Me bio', (tester) async {
      await tester.pumpWidget(createTestApp(const SpecialistProfileScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Read full bio'));
      await tester.pumpAndSettle();
      expect(find.text('Read full bio'), findsOneWidget);
      await tester.tap(find.text('Read full bio'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      expect(find.text('Read full bio'), findsOneWidget);
    });

    testWidgets('Renders responsively without overflow at 320, 360, 390, 430 px widths', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createTestApp(const SpecialistProfileScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'No exception at width $width');
        expect(find.text('My Profile'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('SCREEN 2 — NOTIFICATIONS (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistNotificationsScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      // Filters
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Learners'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Team', skipOffstage: false), findsOneWidget);

      // Today section
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Priority Queue'), findsOneWidget);
      expect(find.text('Live session with Aarav in 30m'), findsOneWidget);
      expect(find.text('Priya Mehta accepted support c...'), findsOneWidget);
      expect(find.text('New note from Mrs. Davies (Tea...'), findsOneWidget);

      // Badges
      expect(find.text('INTERACTIVE AUDIO'), findsOneWidget);
      expect(find.text('CONSENT LOGGED'), findsOneWidget);
      expect(find.text('CLASSROOM SYNERGY'), findsOneWidget);

      // Action buttons
      expect(find.text('Join Session'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Review Details'), findsOneWidget);
      expect(find.text('Open Chat'), findsOneWidget);

      // Yesterday & Earlier section
      expect(find.text('Yesterday & Earlier'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Weekly progress summary gene...'), findsOneWidget);
      expect(find.text('Availability slot approved'), findsOneWidget);
      expect(find.text('View Learning Deck'), findsOneWidget);
      expect(find.text('Manage Schedule'), findsOneWidget);

      // FERPA Compliance
      expect(find.text('Lingua Child-Safe Architecture'), findsOneWidget);
      expect(
        find.textContaining('All speech recordings, transcripts, and learner collaboration logs are end-to-end encrypted & FERPA compliant.'),
        findsOneWidget,
      );
    });

    testWidgets('Filters notifications correctly when tapping filter pills', (tester) async {
      await tester.pumpWidget(createTestApp(const SpecialistNotificationsScreen()));
      await tester.pumpAndSettle();

      // Tap Sessions filter
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();
      expect(find.text('Live session with Aarav in 30m'), findsOneWidget);
      expect(find.text('Priya Mehta accepted support c...'), findsNothing);

      // Tap Messages filter
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('New note from Mrs. Davies (Tea...'), findsOneWidget);
      expect(find.text('Live session with Aarav in 30m'), findsNothing);

      // Tap All filter
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Live session with Aarav in 30m'), findsOneWidget);
      expect(find.text('Priya Mehta accepted support c...'), findsOneWidget);
    });

    testWidgets('Renders responsively without overflow at 320, 360, 390, 430 px widths', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createTestApp(const SpecialistNotificationsScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'No exception at width $width');
        expect(find.text('Notifications'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('SCREEN 3 — CONSENT & SHARING MANAGEMENT (Stitch Visual Reference Tests)', () {
    testWidgets('Renders all primary visual elements matching Stitch design', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SpecialistConsentSharingScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Consent & Sharing'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Subheader
      expect(find.text('Active Circles'), findsOneWidget);
      expect(find.textContaining('Active'), findsWidgets);
      expect(find.text('Connect Learner'), findsOneWidget);

      // Card 1: Aarav Mehta
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('✓ Active'), findsOneWidget);
      expect(find.text('Learner • 10 yrs • Grade 4'), findsOneWidget);
      expect(find.text('SHARED COLLABORATION CIRCLE'), findsOneWidget);
      expect(find.textContaining('Priya Mehta (Guardian)'), findsOneWidget);
      expect(find.textContaining('Mrs. Davies (Teacher)'), findsOneWidget);
      expect(find.textContaining('You (Specialist)'), findsWidgets);

      // Card 1 Scopes
      expect(find.text('Practice Audio & Speech ...'), findsOneWidget);
      expect(find.text('Weekly Progress & Miles...'), findsOneWidget);
      expect(find.text('1-on-1 Practice Session ...'), findsOneWidget);
      expect(find.text('Phonics Games & Word ...'), findsOneWidget);
      expect(find.text('Raw Classroom Ambi...'), findsOneWidget);
      expect(find.text('Not Shared'), findsOneWidget);
      expect(find.textContaining('Consent re-confirmed Oct 12, 2024'), findsOneWidget);
      expect(find.text('Manage Circle'), findsOneWidget);

      // Card 2: Sophia Chen
      expect(find.text('Sophia Chen'), findsWidgets);
      expect(find.text('⇄ Limited'), findsOneWidget);
      expect(find.text('Teen Learner • 15 yrs • Self-directed'), findsOneWidget);
      expect(find.text('COLLABORATION CIRCLE'), findsOneWidget);
      expect(find.text('Reading Fluency & Sum...'), findsOneWidget);
      expect(find.text('Raw Practice Audi...'), findsOneWidget);
      expect(find.text('Learner Private'), findsOneWidget);
      expect(find.text('View Scope'), findsOneWidget);

      // Privacy Reassurance Card
      expect(
        find.textContaining('Learner privacy is our priority.'),
        findsOneWidget,
      );
    });

    testWidgets('Displays confirmation dialog when attempting to toggle a scope', (tester) async {
      await tester.pumpWidget(createTestApp(const SpecialistConsentSharingScreen()));
      await tester.pumpAndSettle();

      // Tap on a shared scope to toggle
      await tester.tap(find.text('Practice Audio & Speech ...'));
      await tester.pumpAndSettle();

      expect(find.text('Restrict Scope Access?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Restrict Scope Access?'), findsNothing);
    });

    testWidgets('Opens Manage Circle modal sheet', (tester) async {
      await tester.pumpWidget(createTestApp(const SpecialistConsentSharingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage Circle'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Manage Circle • Aarav Mehta'), findsOneWidget);
      expect(find.text('View Circle Members'), findsOneWidget);
      expect(find.text('Consent Audit Trail'), findsOneWidget);
    });

    testWidgets('Renders responsively without overflow at 320, 360, 390, 430 px widths', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createTestApp(const SpecialistConsentSharingScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'No exception at width $width');
        expect(find.text('Consent & Sharing'), findsOneWidget);
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
}
