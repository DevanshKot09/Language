import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_dashboard_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  const mockCaseload = [
    SpecialistCaseloadItem(
      relationshipId: 'rel-1',
      learnerId: 'lr-1',
      displayName: 'Aarav M.',
      ageBand: 'child',
      supportFocus: 'dld_track',
      baselineStatus: 'completed',
      pendingAiRecommendations: 2,
      status: 'active',
      organization: 'Speech Horizons',
    ),
    SpecialistCaseloadItem(
      relationshipId: 'rel-2',
      learnerId: 'lr-2',
      displayName: 'Anaya P.',
      ageBand: 'child',
      supportFocus: 'both_track',
      baselineStatus: 'in_progress',
      pendingAiRecommendations: 1,
      status: 'active',
      organization: 'Speech Horizons',
    ),
  ];

  final specialistUser = AuthUser(
    id: 'spec-user-id',
    email: 'specialist.maya@lingua.ai',
    role: UserRole.specialist,
    status: 'active',
    createdAt: DateTime.now(),
  );

  const specialistProfile = UserProfile(
    id: 'prof-spec-001',
    userId: 'spec-user-id',
    displayName: 'Dr. Maya',
    ageBand: AgeBand.adult,
    supportFocus: SupportTrack.multimodalBoth,
    baselineStatus: 'completed',
  );

  Widget createTestWidget({
    UserRole role = UserRole.specialist,
    Size screenSize = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        userSessionProvider.overrideWith(
          () => _MockUserSessionNotifier(
            UserSessionState(
              status: SessionStatus.authenticated,
              currentUser: specialistUser,
              profile: specialistProfile,
              currentRole: role,
            ),
          ),
        ),
        specialistCaseloadProvider.overrideWith((ref) => Future.value(mockCaseload)),
        relationshipsProvider.overrideWith((ref) => Future.value([])),
        invitationsProvider.overrideWith((ref) => Future.value([])),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const SpecialistDashboardScreen(),
        ),
      ),
    );
  }

  group('LINGUA AI Specialist Dashboard - Stitch Reference UI & Interaction Tests', () {
    testWidgets('Renders complete Stitch visual hierarchy and branding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Top Brand Header
      expect(find.text('Lingua AI'), findsOneWidget);
      expect(find.text('SPECIALIST'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // 2. Personalized Greeting & Subtitle
      expect(find.textContaining('Dr. Maya'), findsOneWidget);
      expect(find.text("Here's what needs your attention today."), findsOneWidget);


      // 4. Metric Cards (Caseload & Practices)
      expect(find.text('Specialist Caseload'), findsOneWidget);
      expect(find.text('Practices'), findsOneWidget);
      expect(find.text('active'), findsOneWidget);
      expect(find.text('Learners assigned'), findsOneWidget);
      expect(find.text('View caseload'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('today'), findsOneWidget);
      expect(find.text('Audio turns logged'), findsOneWidget);
      expect(find.text('Speech feed'), findsOneWidget);

      // 5. Today's Schedule Card
      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('• 2 sessions'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Aarav M.'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('• Upcoming'), findsOneWidget);

      expect(find.text('2:00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Anaya P.'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      // 6. QUICK TOOLS Section
      expect(find.text('QUICK TOOLS'), findsOneWidget);
      expect(find.text('Caseload'), findsWidgets);
      expect(find.text('Booking'), findsOneWidget);

      // 7. AI Suggestions Card
      expect(find.text('AI Suggestions'), findsOneWidget);
      expect(find.text('Human review required'), findsOneWidget);
      expect(find.text('New Pacing Exercise for Aarav'), findsOneWidget);
      expect(find.text("Based on yesterday's recorded play session"), findsOneWidget);
      expect(find.text('Focus: /s/ blends'), findsOneWidget);
      expect(find.text('Toybox card game'), findsOneWidget);
      expect(
        find.text("Specialist approval needed to push to child's device."),
        findsOneWidget,
      );
      expect(find.text('Review plan'), findsOneWidget);

      // 8. Recent Activity Section
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Weekly summary sent to parent (Aarav M.)'), findsOneWidget);
      expect(find.text('45 minutes ago • Phoneme game completed'), findsOneWidget);
      expect(find.text('Consent granted by guardian (Liam K.)'), findsOneWidget);
      expect(find.text('2 hours ago • Audio recording permissions'), findsOneWidget);

      // 9. Bottom Navigation Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget); // Bottom nav
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('Tapping "Review plan" opens AI plan review modal with oversight actions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to AI Suggestions card if needed
      await tester.ensureVisible(find.text('Review plan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review plan'));
      await tester.pumpAndSettle();

      expect(find.text('AI Recommendation Oversight'), findsOneWidget);
      expect(find.text('Approve & Push to Child Device'), findsOneWidget);
      expect(find.text('Modify Parameters'), findsOneWidget);

      // Tap approve
      await tester.tap(find.text('Approve & Push to Child Device'));
      await tester.pumpAndSettle();

      expect(find.text('Plan approved! New pacing exercise pushed to Aarav.'), findsOneWidget);
    });

    testWidgets('Tapping session opens session detail bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Aarav M.'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aarav M.'));
      await tester.pumpAndSettle();

      expect(find.text('Session: Aarav M.'), findsOneWidget);
      expect(find.text('View Learner Progress Dossier'), findsOneWidget);
    });

    testWidgets('Tapping notifications bell opens notifications modal', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Specialist Notifications'), findsOneWidget);
      expect(find.text('Consent request pending for Liam K.'), findsOneWidget);
    });

    testWidgets('Tapping specialist avatar opens profile bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Maya'), findsWidgets);
      expect(find.text('Speech-Language Pathologist (SLP)'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Tapping Booking tool opens appointment scheduling modal', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Booking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Booking'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Clinical / Support Session'), findsOneWidget);
      expect(find.text('Confirm & Send Session Invite'), findsOneWidget);
    });

    testWidgets('Switching to Caseload tab displays Caseload search and learner cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Caseload tab via Bottom Nav
      await tester.tap(find.text('Caseload').last);
      await tester.pumpAndSettle();

      expect(find.text('Specialist Caseload'), findsOneWidget);
      expect(find.text('Aarav M.'), findsOneWidget);
      expect(find.text('Anaya P.'), findsOneWidget);
      expect(find.text('Spoken Language (DLD)'), findsOneWidget);
    });

    testWidgets('Restricted role displays security notice and switch workspace button', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.learner));
      await tester.pumpAndSettle();

      expect(find.text('Specialist Workspace Restricted'), findsOneWidget);
      expect(find.text('Return to Login'), findsOneWidget);
    });

    testWidgets('Responsive Layout: No overflow on 320px, 360px, 390px, 430px widths', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];

      for (final width in widths) {
        await tester.pumpWidget(
          createTestWidget(screenSize: Size(width, 844)),
        );
        await tester.pumpAndSettle();

        // Verify zero RenderFlex overflows
        expect(tester.takeException(), isNull);
        expect(find.text('Lingua AI'), findsOneWidget);
        expect(find.text('SPECIALIST'), findsOneWidget);
      }
    });

    testWidgets('Caseload Tab Responsive Layout: No overflow on 320px, 360px, 390px, 430px widths', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];

      for (final width in widths) {
        await tester.pumpWidget(
          createTestWidget(screenSize: Size(width, 844)),
        );
        await tester.pumpAndSettle();

        // Switch to Caseload Tab
        await tester.tap(find.text('Caseload').last);
        await tester.pumpAndSettle();

        // Verify zero RenderFlex overflows on Caseload tab
        expect(tester.takeException(), isNull);
        expect(find.text('My Learners'), findsOneWidget);
        expect(find.text('People & families you support collaboratively'), findsOneWidget);
        expect(find.text('Search learners by name or tag...'), findsOneWidget);
        expect(find.textContaining('All ('), findsOneWidget);
        expect(find.textContaining('Youth ('), findsOneWidget);
        expect(find.textContaining('Adults ('), findsOneWidget);
        expect(find.text('Invite New Learner'), findsOneWidget);
      }
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
