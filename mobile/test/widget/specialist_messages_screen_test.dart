import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_messages_screen.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  const mockConversations = [
    // 1. Priority Pinned Support Circle (Child with Parent + Teacher + Specialist)
    SpecialistConversationItem(
      id: 'group_aarav',
      conversationType: 'group',
      category: 'teams',
      title: 'Aarav\'s Support Circle',
      subtitle: 'Parent · Teacher · Specialist',
      roles: ['Parent', 'Teacher', 'Specialist'],
      lastMessageSender: 'Priya M.',
      lastMessageText: 'Can we discuss tomorrow\'s phonics practice...',
      lastMessageTime: '10:42 AM',
      unreadCount: 2,
      isPinned: true,
      isOnline: true,
      consentStatus: 'verified',
      isLocked: false,
      targetLearnerId: 'learner-aarav',
      targetLearnerName: 'Aarav Sharma',
      avatarType: 'dual',
      avatarBadge: 'online',
    ),
    // 2. Maya's Learning Circle (Adult Learner + Teacher + Specialist)
    SpecialistConversationItem(
      id: 'group_maya',
      conversationType: 'group',
      category: 'teams',
      title: 'Maya\'s Learning Circle',
      subtitle: 'Adult Learner · Teacher · Specialist',
      roles: ['Adult Learner', 'Teacher', 'Specialist'],
      lastMessageSender: 'David W.',
      lastMessageText: 'Next week\'s fluency review is ready.',
      lastMessageTime: 'Yesterday',
      unreadCount: 0,
      isPinned: false,
      isOnline: false,
      consentStatus: 'verified',
      isLocked: false,
      targetLearnerId: 'learner-maya',
      targetLearnerName: 'Maya Lin',
      avatarType: 'team_teal',
      avatarBadge: 'team',
    ),
    // 3. Priya Mehta (Direct contact with parent)
    SpecialistConversationItem(
      id: 'direct_parent_priya',
      conversationType: 'direct',
      category: 'learners',
      title: 'Priya Mehta',
      subtitle: 'Aarav\'s Primary Guardian',
      roles: ['Parent'],
      lastMessageSender: null,
      lastMessageText: 'Thank you for the quick turn summary! Aarav loved the star activity.',
      lastMessageTime: 'Oct 16',
      unreadCount: 0,
      isPinned: false,
      isOnline: true,
      consentStatus: 'verified',
      isLocked: false,
      targetLearnerId: 'learner-aarav',
      targetLearnerName: 'Aarav Sharma',
      avatarType: 'parent_online',
      avatarBadge: 'online',
    ),
    // 4. Sofia's Support Circle (Guardian Consent Pending Locked State)
    SpecialistConversationItem(
      id: 'group_sofia',
      conversationType: 'group',
      category: 'teams',
      title: 'Sofia\'s Support Circle',
      subtitle: 'Guardian Consent Pending',
      roles: ['Parent', 'Teacher', 'Specialist'],
      lastMessageSender: null,
      lastMessageText: 'Audio turns and session notes locked until guardian sign-off.',
      lastMessageTime: 'Oct 15',
      unreadCount: 0,
      isPinned: false,
      isOnline: false,
      consentStatus: 'pending',
      isLocked: true,
      lockReason: 'Audio turns and session notes locked until guardian sign-off.',
      targetLearnerId: 'learner-sofia',
      targetLearnerName: 'Sofia Patel',
      avatarType: 'locked_child',
      avatarBadge: 'locked',
    ),
    // 5. Mrs. Eleanor Davies (Direct contact with educator)
    SpecialistConversationItem(
      id: 'direct_teacher_davies',
      conversationType: 'direct',
      category: 'learners',
      title: 'Mrs. Eleanor Davies',
      subtitle: 'Classroom Educator · Oakridge Elementary',
      roles: ['Teacher'],
      lastMessageSender: null,
      lastMessageText: 'Shared classroom reading observations and notes.',
      lastMessageTime: 'Oct 14',
      unreadCount: 0,
      isPinned: false,
      isOnline: false,
      consentStatus: 'verified',
      isLocked: false,
      targetLearnerId: 'learner-aarav',
      targetLearnerName: 'Aarav Sharma',
      avatarType: 'teacher_book',
      avatarBadge: 'book',
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
    List<SpecialistConversationItem> conversations = mockConversations,
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
              currentRole: UserRole.specialist,
              activeTrack: SupportTrack.dldSpokenLanguage,
              isOnboardingCompleted: true,
              learnerName: 'Dr. Maya',
            ),
          ),
        ),
        specialistConversationsProvider.overrideWith((ref, query) async {
          var filtered = List<SpecialistConversationItem>.from(conversations);
          if (query.filter == 'unread') {
            filtered = filtered.where((c) => c.unreadCount > 0).toList();
          } else if (query.filter == 'teams') {
            filtered = filtered.where((c) => c.category == 'teams').toList();
          } else if (query.filter == 'learners') {
            filtered = filtered.where((c) => c.category == 'learners').toList();
          }
          if (query.search != null && query.search!.isNotEmpty) {
            final q = query.search!.toLowerCase();
            filtered = filtered.where((c) =>
                c.title.toLowerCase().contains(q) ||
                c.subtitle.toLowerCase().contains(q) ||
                c.lastMessageText.toLowerCase().contains(q)).toList();
          }
          return filtered;
        }),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const SpecialistMessagesScreen(showBottomNav: true),
        ),
      ),
    );
  }

  testWidgets('Renders Specialist Messages Header and Subtitle', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsNWidgets(2)); // Header + Bottom Nav
    expect(find.text('Your support conversations'), findsOneWidget);
  });

  testWidgets('Renders all filter chips with correct labels', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Learners'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
  });

  testWidgets('Renders Priority Collaboration section with pinned Aarav card', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('PRIORITY COLLABORATION'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('Aarav\'s Support Circle'), findsOneWidget);
    expect(find.text('Parent · Teacher · Specialist'), findsOneWidget);
    expect(find.text('2 unread'), findsOneWidget);
  });

  testWidgets('Renders Recent Conversations with Maya, Priya, Sofia, and Eleanor', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('RECENT CONVERSATIONS'), findsOneWidget);
    expect(find.text('Maya\'s Learning Circle'), findsOneWidget);
    expect(find.text('Priya Mehta'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Sofia\'s Support Circle'), findsOneWidget);
    expect(find.text('Mrs. Eleanor Davies'), findsOneWidget);
  });

  testWidgets('Renders Guardian Consent Pending locked state with Review & Prompt button', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Guardian Consent Pending'), findsOneWidget);
    expect(find.text('Review & Prompt'), findsOneWidget);
    expect(find.text('Audio turns and session notes locked until guardian sign-off.'), findsOneWidget);
  });

  testWidgets('Filter chip selection filters conversations', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    // Tap Unread chip
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();

    // Aarav has 2 unread, so Aarav is visible
    expect(find.text('Aarav\'s Support Circle'), findsOneWidget);
    // Maya has 0 unread, so Maya is not visible
    expect(find.text('Maya\'s Learning Circle'), findsNothing);
  });

  testWidgets('Search filtering finds specific conversation', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    // Tap search icon button to expand search field
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.pumpAndSettle();

    expect(find.text('Maya\'s Learning Circle'), findsOneWidget);
    expect(find.text('Priya Mehta'), findsNothing);
  });

  testWidgets('Renders empty state when caseload has no conversations', (tester) async {
    await tester.pumpWidget(createTestWidget(conversations: [], screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('No support conversations yet'), findsOneWidget);
  });

  testWidgets('Renders cleanly on small mobile viewports (320px, 360px, 430px) without overflow', (tester) async {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      await tester.pumpWidget(createTestWidget(screenSize: Size(width, 900)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Must not throw at width $width');
      expect(find.text('Messages'), findsNWidgets(2));
    }
  });

  testWidgets('Bottom navigation renders 4 items with Messages selected', (tester) async {
    await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Caseload'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Messages'), findsNWidgets(2));
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
