import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:lingua_ai/core/errors/app_failure.dart';
import 'package:lingua_ai/features/authentication/data/auth_repository.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_session.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/onboarding_status.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

class MockAuthRepository implements IAuthRepository {
  final _controller = StreamController<fb.User?>.broadcast();
  fb.User? _mockUser;
  bool shouldFail = false;

  void emitUser(fb.User? user) {
    _mockUser = user;
    _controller.add(user);
  }

  @override
  Stream<fb.User?> get authStateChanges => _controller.stream;

  @override
  fb.User? get currentUser => _mockUser;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_id_token_123';

  @override
  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception('Mock authentication failure');
    }
    return _createMockCredential(email);
  }

  @override
  Future<fb.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception('Mock signup failure');
    }
    return _createMockCredential(email);
  }

  bool shouldCancelGoogle = false;

  @override
  Future<fb.UserCredential> signInWithGoogle() async {
    if (shouldCancelGoogle) {
      throw const ValidationFailure(
        userMessage: 'Google sign-in was cancelled.',
        technicalDetails: 'User cancelled Google sign-in dialog.',
      );
    }
    if (shouldFail) {
      throw const UnknownFailure(
        userMessage: "We couldn't complete Google sign-in. Please try again.",
        technicalDetails: 'Mock Google sign-in failure',
      );
    }
    return _createMockCredential('alex.google@lingua.ai');
  }

  @override
  Future<AuthSession> signInWithGoogleAndSync() async {
    await signInWithGoogle();
    return await syncWithBackend();
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _controller.add(null);
  }

  @override
  Future<AuthSession> syncWithBackend({
    UserRole role = UserRole.learner,
    AgeBand ageBand = AgeBand.teen,
    SupportTrack supportFocus = SupportTrack.dldSpokenLanguage,
    String? displayName,
    bool termsAcknowledged = true,
    bool nonDiagnosticAcknowledged = true,
  }) async {
    return AuthSession(
      user: const AuthUser(
        id: 'mock_uid_1',
        email: 'alex@lingua.ai',
        role: UserRole.learner,
        status: 'active',
      ),
      profile: UserProfile(
        id: 'mock_profile_1',
        userId: 'mock_uid_1',
        displayName: displayName ?? 'Alex',
        ageBand: ageBand,
        supportFocus: supportFocus,
        guardianConsentStatus: ageBand == AgeBand.child ? 'pending' : 'not_required',
      ),
      onboarding: const OnboardingStatus(isCompleted: false, currentStep: 'role_selection'),
    );
  }

  @override
  Future<AuthSession> getApplicationSession() async {
    return const AuthSession(
      user: AuthUser(
        id: 'mock_uid_1',
        email: 'alex@lingua.ai',
        role: UserRole.learner,
        status: 'active',
      ),
      profile: UserProfile(
        id: 'mock_profile_1',
        userId: 'mock_uid_1',
        displayName: 'Alex',
        ageBand: AgeBand.teen,
        supportFocus: SupportTrack.dldSpokenLanguage,
        guardianConsentStatus: 'not_required',
      ),
      onboarding: OnboardingStatus(isCompleted: true, currentStep: 'completed'),
    );
  }

  String? lastResetEmailRequested;
  bool shouldFailReset = false;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmailRequested = email;
    if (shouldFailReset) {
      throw const UnknownFailure(
        userMessage: 'Something went wrong. Please try again.',
        technicalDetails: 'Mock reset failure',
      );
    }
  }

  fb.UserCredential _createMockCredential(String email) {
    return FakeUserCredential();
  }

  void dispose() {
    _controller.close();
  }
}

class FakeUserCredential implements fb.UserCredential {
  @override
  fb.AdditionalUserInfo? get additionalUserInfo => null;

  @override
  fb.AuthCredential? get credential => null;

  @override
  fb.User? get user => null;
}
