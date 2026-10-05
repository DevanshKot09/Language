import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_failure.dart';
import '../../shared/models/age_profile.dart';
import '../../shared/models/auth_user.dart';
import '../../shared/models/skill_track.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/user_role.dart';
import 'age_profile_provider.dart';
import 'auth_provider.dart';
import 'storage_provider.dart';

enum SessionStatus {
  initial,
  restoring,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class UserSessionState {
  final SessionStatus status;
  final AuthUser? currentUser;
  final UserProfile? profile;
  final String? errorMessage;
  final UserRole currentRole;
  final SupportTrack activeTrack;
  final bool isOnboardingCompleted;
  final String learnerName;

  const UserSessionState({
    this.status = SessionStatus.initial,
    this.currentUser,
    this.profile,
    this.errorMessage,
    this.currentRole = UserRole.learner,
    this.activeTrack = SupportTrack.dldSpokenLanguage,
    this.isOnboardingCompleted = false,
    this.learnerName = 'Alex',
  });

  bool get isAuthenticated => status == SessionStatus.authenticated;
  bool get isLoading => status == SessionStatus.loading || status == SessionStatus.restoring;

  UserSessionState copyWith({
    SessionStatus? status,
    AuthUser? currentUser,
    UserProfile? profile,
    String? errorMessage,
    UserRole? currentRole,
    SupportTrack? activeTrack,
    bool? isOnboardingCompleted,
    String? learnerName,
  }) {
    return UserSessionState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      currentRole: currentRole ?? this.currentRole,
      activeTrack: activeTrack ?? this.activeTrack,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      learnerName: learnerName ?? this.learnerName,
    );
  }
}

class UserSessionNotifier extends Notifier<UserSessionState> {
  StreamSubscription? _authSubscription;
  bool _disposed = false;

  @override
  UserSessionState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _authSubscription?.cancel();
    });

    final authRepo = ref.read(authRepositoryProvider);

    // Listen to Firebase client authentication state changes
    _authSubscription = authRepo.authStateChanges.listen((firebaseUser) {
      if (_disposed) return;
      // Do not interrupt in-flight operations (login, signup, logout)
      if (state.isLoading) return;

      if (firebaseUser != null) {
        if (!state.isAuthenticated || state.currentUser == null) {
          restoreSession();
        }
      } else {
        // Firebase user unauthenticated
        _setUnauthenticatedState();
      }
    });

    // Initial session restoration check
    Future.microtask(() {
      if (!_disposed && !state.isLoading) {
        restoreSession();
      }
    });

    return const UserSessionState();
  }

  Future<void> _setUnauthenticatedState() async {
    if (_disposed) return;
    final storage = ref.read(preferencesStorageProvider);
    final completed = await storage.isOnboardingCompleted();
    if (_disposed) return;
    state = state.copyWith(
      status: SessionStatus.unauthenticated,
      currentUser: null,
      profile: null,
      isOnboardingCompleted: completed,
      errorMessage: null,
    );
  }

  /// Restores authenticated session from Firebase Auth + FastAPI /me endpoint
  Future<void> restoreSession() async {
    if (_disposed) return;
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUser == null) {
      await _setUnauthenticatedState();
      return;
    }

    if (state.status != SessionStatus.authenticated) {
      state = state.copyWith(status: SessionStatus.restoring, errorMessage: null);
    }
    try {
      final session = await authRepo.getApplicationSession();
      if (_disposed) return;

      state = state.copyWith(
        status: SessionStatus.authenticated,
        currentUser: session.user,
        profile: session.profile,
        currentRole: session.user.role,
        activeTrack: session.profile.supportFocus,
        isOnboardingCompleted: session.onboarding.isCompleted,
        learnerName: session.profile.displayName,
      );

      // Synchronize active age profile configuration
      ref.read(ageProfileProvider.notifier).setAgeBand(session.profile.ageBand);
    } on Failure {
      if (!_disposed) {
        state = state.copyWith(
          status: SessionStatus.unauthenticated,
          errorMessage: null,
        );
      }
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(
          status: SessionStatus.unauthenticated,
          errorMessage: null,
        );
      }
    }
  }

  /// Authenticate an existing user via Firebase Email/Password + sync with FastAPI
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: SessionStatus.loading, errorMessage: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(email: email, password: password);
      final session = await authRepo.syncWithBackend();

      state = state.copyWith(
        status: SessionStatus.authenticated,
        currentUser: session.user,
        profile: session.profile,
        currentRole: session.user.role,
        activeTrack: session.profile.supportFocus,
        isOnboardingCompleted: session.onboarding.isCompleted,
        learnerName: session.profile.displayName,
      );

      ref.read(ageProfileProvider.notifier).setAgeBand(session.profile.ageBand);
    } on Failure catch (failure) {
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      rethrow;
    } catch (e) {
      final failure = UnknownFailure(technicalDetails: e.toString());
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      throw failure;
    }
  }

  /// Authenticate via Google Sign-In + synchronize profile with FastAPI
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: SessionStatus.loading, errorMessage: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final session = await authRepo.signInWithGoogleAndSync();

      state = state.copyWith(
        status: SessionStatus.authenticated,
        currentUser: session.user,
        profile: session.profile,
        currentRole: session.user.role,
        activeTrack: session.profile.supportFocus,
        isOnboardingCompleted: session.onboarding.isCompleted,
        learnerName: session.profile.displayName,
      );

      ref.read(ageProfileProvider.notifier).setAgeBand(session.profile.ageBand);
    } on Failure catch (failure) {
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      rethrow;
    } catch (e) {
      final failure = UnknownFailure(
        userMessage: "We couldn't complete Google sign-in. Please try again.",
        technicalDetails: e.toString(),
      );
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      throw failure;
    }
  }

  /// Clear transient error message from previous flows
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Register a new account with Firebase Auth + initialize Supabase profile via FastAPI
  Future<void> signup({
    required String email,
    required String password,
    required String confirmPassword,
    UserRole role = UserRole.learner,
    AgeBand ageBand = AgeBand.teen,
    SupportTrack supportFocus = SupportTrack.dldSpokenLanguage,
    String? displayName,
    required bool termsAcknowledged,
    required bool nonDiagnosticAcknowledged,
  }) async {
    if (password != confirmPassword) {
      const failure = ValidationFailure(
        userMessage: 'Passwords do not match. Please verify and try again.',
        technicalDetails: 'Passwords do not match.',
      );
      state = state.copyWith(status: SessionStatus.error, errorMessage: failure.userMessage);
      throw failure;
    }
    if (!termsAcknowledged || !nonDiagnosticAcknowledged) {
      const failure = ValidationFailure(
        userMessage: 'You must acknowledge the terms and non-diagnostic policy to continue.',
        technicalDetails: 'You must acknowledge the terms and non-diagnostic policy.',
      );
      state = state.copyWith(status: SessionStatus.error, errorMessage: failure.userMessage);
      throw failure;
    }

    state = state.copyWith(status: SessionStatus.loading, errorMessage: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.createUserWithEmailAndPassword(email: email, password: password);
      final session = await authRepo.syncWithBackend(
        role: role,
        ageBand: ageBand,
        supportFocus: supportFocus,
        displayName: displayName,
        termsAcknowledged: termsAcknowledged,
        nonDiagnosticAcknowledged: nonDiagnosticAcknowledged,
      );

      state = state.copyWith(
        status: SessionStatus.authenticated,
        currentUser: session.user,
        profile: session.profile,
        currentRole: session.user.role,
        activeTrack: session.profile.supportFocus,
        isOnboardingCompleted: session.onboarding.isCompleted,
        learnerName: session.profile.displayName,
      );

      ref.read(ageProfileProvider.notifier).setAgeBand(session.profile.ageBand);
    } on Failure catch (failure) {
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      rethrow;
    } catch (e) {
      final failure = UnknownFailure(technicalDetails: e.toString());
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: failure.userMessage,
      );
      throw failure;
    }
  }

  /// Sign out from Firebase Auth and clear local application session
  Future<void> logout() async {
    state = state.copyWith(status: SessionStatus.loading);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
    } finally {
      state = const UserSessionState(status: SessionStatus.unauthenticated);
    }
  }

  /// Updates active user role and synchronizes with backend if authenticated
  void setRole(UserRole role) {
    state = state.copyWith(currentRole: role);
    if (state.isAuthenticated) {
      final profileRepo = ref.read(profileRepositoryProvider);
      profileRepo.updateOnboarding(role: role).ignore();
    }
  }

  /// Updates support track and synchronizes with backend if authenticated
  void setTrack(SupportTrack track) {
    state = state.copyWith(activeTrack: track);
    if (state.isAuthenticated) {
      final profileRepo = ref.read(profileRepositoryProvider);
      profileRepo.updateProfile(supportFocus: track).ignore();
    }
  }

  /// Updates age band and synchronizes with ageProfileProvider and backend
  void setAgeBand(AgeBand band) {
    ref.read(ageProfileProvider.notifier).setAgeBand(band);
    if (state.isAuthenticated) {
      final profileRepo = ref.read(profileRepositoryProvider);
      profileRepo.updateProfile(ageBand: band).ignore();
    }
  }

  /// Finalizes learner onboarding locally and in the backend
  Future<void> completeOnboarding() async {
    state = state.copyWith(isOnboardingCompleted: true);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setOnboardingCompleted(true);

    if (state.isAuthenticated) {
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        await profileRepo.updateOnboarding(
          isCompleted: true,
          currentStep: 'completed',
          role: state.currentRole,
          supportFocus: state.activeTrack,
        );
      } catch (_) {}
    }
  }
}

final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSessionState>(
  UserSessionNotifier.new,
);
