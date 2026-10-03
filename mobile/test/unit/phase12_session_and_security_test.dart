import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_ai/app/providers/auth_provider.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 12 Mobile Session Hardening & State Isolation Tests', () {
    test('UserSessionState default unauthenticated state prevents access', () {
      const state = UserSessionState();
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.currentUser, isNull);
      expect(state.profile, isNull);
      expect(state.currentRole, equals(UserRole.learner));
      expect(state.activeTrack, equals(SupportTrack.dldSpokenLanguage));
    });

    test('UserSessionState authenticated state holds credentials correctly', () {
      final user = AuthUser(
        id: 'u-secure-1',
        email: 'learner@lingua.ai',
        role: UserRole.learner,
        status: 'active',
        createdAt: DateTime.parse('2026-09-30T10:00:00Z'),
      );
      final profile = UserProfile(
        id: 'p-secure-1',
        userId: 'u-secure-1',
        displayName: 'Sam',
        ageBand: AgeBand.child,
        supportFocus: SupportTrack.dldSpokenLanguage,
        guardianConsentStatus: 'verified',
      );

      final state = UserSessionState(
        status: SessionStatus.authenticated,
        currentUser: user,
        profile: profile,
        currentRole: UserRole.learner,
        activeTrack: SupportTrack.dldSpokenLanguage,
        isOnboardingCompleted: true,
        learnerName: 'Sam',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.currentUser?.id, equals('u-secure-1'));
      expect(state.profile?.guardianConsentStatus, equals('verified'));
      expect(state.currentRole, equals(UserRole.learner));
    });

    test('ProviderContainer logout invalidates session state to prevent cross-user leak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read session
      final sessionNotifier = container.read(userSessionProvider.notifier);

      // Verify initial state
      expect(container.read(userSessionProvider).isAuthenticated, isFalse);

      // Set role and age band
      sessionNotifier.setRole(UserRole.specialist);
      expect(container.read(userSessionProvider).currentRole, equals(UserRole.specialist));

      sessionNotifier.setAgeBand(AgeBand.adult);
      expect(container.read(userSessionProvider).activeTrack, equals(SupportTrack.dldSpokenLanguage));

      // Execute logout
      await sessionNotifier.logout();

      // State must be unauthenticated and scrubbed of any user session details
      final scrubbedState = container.read(userSessionProvider);
      expect(scrubbedState.isAuthenticated, isFalse);
      expect(scrubbedState.currentUser, isNull);
      expect(scrubbedState.profile, isNull);
      expect(scrubbedState.status, equals(SessionStatus.unauthenticated));
    });

    test('AgeBand and SupportTrack respect non-diagnostic educational boundaries', () {
      expect(AgeBand.child.name, equals('child'));
      expect(AgeBand.teen.name, equals('teen'));
      expect(AgeBand.adult.name, equals('adult'));

      expect(SupportTrack.dldSpokenLanguage.shortLabel, equals('DLD Spoken Track'));
      expect(SupportTrack.dyslexiaLiteracy.shortLabel, equals('Dyslexia Reading Track'));

      // Ensure no diagnostic or medical terms in user-facing labels
      for (final track in SupportTrack.values) {
        expect(track.title.toLowerCase(), isNot(contains('severity')));
        expect(track.title.toLowerCase(), isNot(contains('clinical diagnosis')));
        expect(track.title.toLowerCase(), isNot(contains('prognosis')));
        expect(track.title.toLowerCase(), isNot(contains('medical treatment')));
      }
    });

    test('Google Account A to Google Account B preserves complete session and state isolation', () async {
      final mockAuth = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userSessionProvider.notifier);

      // Sign in as Google Account A
      await notifier.signInWithGoogle();
      final stateA = container.read(userSessionProvider);
      expect(stateA.isAuthenticated, isTrue);
      expect(stateA.learnerName, equals('Alex'));
      expect(stateA.currentRole, equals(UserRole.learner));

      // Modify role in session A
      notifier.setRole(UserRole.parent);
      expect(container.read(userSessionProvider).currentRole, equals(UserRole.parent));

      // Logout Account A
      await notifier.logout();
      final stateLoggedOut = container.read(userSessionProvider);
      expect(stateLoggedOut.isAuthenticated, isFalse);
      expect(stateLoggedOut.currentUser, isNull);
      expect(stateLoggedOut.profile, isNull);

      // Sign in as Account B (defaults to fresh learner role)
      await notifier.signInWithGoogle();
      final stateB = container.read(userSessionProvider);
      expect(stateB.isAuthenticated, isTrue);
      expect(stateB.currentRole, equals(UserRole.learner));
      expect(stateB.currentUser?.email, isNotNull);
    });
  });
}
