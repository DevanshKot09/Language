import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/age_profile.dart';
import '../../../../shared/models/auth_session.dart';
import '../../../../shared/models/skill_track.dart';
import '../../../../shared/models/user_role.dart';

abstract class IAuthRepository {
  Stream<fb.User?> get authStateChanges;
  fb.User? get currentUser;
  Future<String?> getIdToken([bool forceRefresh = false]);

  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<fb.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<fb.UserCredential> signInWithGoogle();
  Future<AuthSession> signInWithGoogleAndSync();

  Future<void> signOut();

  Future<AuthSession> syncWithBackend({
    UserRole role = UserRole.learner,
    AgeBand ageBand = AgeBand.teen,
    SupportTrack supportFocus = SupportTrack.dldSpokenLanguage,
    String? displayName,
    bool termsAcknowledged = true,
    bool nonDiagnosticAcknowledged = true,
  });

  Future<AuthSession> getApplicationSession();

  Future<void> sendPasswordResetEmail(String email);
}

class AuthRepository implements IAuthRepository {
  final fb.FirebaseAuth? _firebaseAuth;
  final IApiClient _apiClient;

  AuthRepository(this._apiClient, [this._firebaseAuth]);

  fb.FirebaseAuth get _auth {
    try {
      return _firebaseAuth ?? fb.FirebaseAuth.instance;
    } catch (_) {
      throw StateError('Firebase has not been initialized.');
    }
  }

  @override
  Stream<fb.User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  fb.User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<fb.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  static bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: '960393036210-a66svqibar5a4p1nn0vhm8k982oomh1b.apps.googleusercontent.com',
        );
        _googleSignInInitialized = true;
      } catch (_) {
        _googleSignInInitialized = true;
      }
    }
  }

  @override
  Future<fb.UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        return await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignInInitialized();
        final account = await GoogleSignIn.instance.authenticate();
        final auth = account.authentication;
        final idToken = auth.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw const ValidationFailure(
            userMessage: "We couldn't complete Google sign-in. Please try again.",
            technicalDetails: 'Missing Google ID token from native authentication.',
          );
        }

        final credential = fb.GoogleAuthProvider.credential(
          idToken: idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ValidationFailure(
          userMessage: 'Google sign-in was cancelled.',
          technicalDetails: 'User cancelled Google sign-in dialog.',
        );
      }
      throw UnknownFailure(
        userMessage: "We couldn't complete Google sign-in. Please try again.",
        technicalDetails: e.description ?? e.code.toString(),
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        throw const ValidationFailure(
          userMessage: 'Google sign-in was cancelled.',
          technicalDetails: 'Popup closed by user.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw const NetworkFailure(
          technicalDetails: 'Network error during Google authentication.',
        );
      }
      throw _mapFirebaseAuthException(e);
    } on Failure {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort')) {
        throw const ValidationFailure(
          userMessage: 'Google sign-in was cancelled.',
          technicalDetails: 'Operation cancelled.',
        );
      }
      throw UnknownFailure(
        userMessage: "We couldn't complete Google sign-in. Please try again.",
        technicalDetails: e.toString(),
      );
    }
  }

  @override
  Future<AuthSession> signInWithGoogleAndSync() async {
    await signInWithGoogle();
    return await syncWithBackend();
  }

  @override
  Future<void> signOut() async {
    try {
      await _apiClient.post(ApiEndpoints.logout, body: {'reason': 'user_sign_out'});
    } catch (_) {
      // Best-effort backend audit notification
    } finally {
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      try {
        await _auth.signOut();
      } catch (_) {}
    }
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
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authSync,
        body: {
          'role': role.name,
          'age_band': ageBand.name,
          'support_focus': supportFocus.apiId,
          'display_name': displayName,
          'terms_acknowledged': termsAcknowledged,
          'non_diagnostic_acknowledged': nonDiagnosticAcknowledged,
        },
      );
      return AuthSession.fromJson(response as Map<String, dynamic>);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<AuthSession> getApplicationSession() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      return AuthSession.fromJson(response as Map<String, dynamic>);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final targetEmail = email.trim();
    if (targetEmail.isEmpty || !targetEmail.contains('@')) {
      throw const ValidationFailure(
        userMessage: 'Enter a valid email address.',
        technicalDetails: 'Empty or invalid email passed to sendPasswordResetEmail.',
      );
    }

    try {
      await _apiClient.post(
        ApiEndpoints.forgotPassword,
        body: {'email': targetEmail},
      );
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      // Offline or network fallback to Firebase password reset
      try {
        await _auth.sendPasswordResetEmail(email: targetEmail);
      } on fb.FirebaseAuthException catch (fbError) {
        throw _mapFirebaseAuthException(fbError);
      } catch (_) {
        throw const NetworkFailure(
          userMessage: 'Something went wrong. Please check your connection and try again.',
          technicalDetails: 'Both FastAPI reset endpoint and Firebase fallback failed.',
        );
      }
    }
  }

  Failure _mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const UnauthorizedFailure(
          userMessage: 'The email or password does not match our records. Please try again.',
          technicalDetails: 'The email or password does not match our records. Please try again.',
        );
      case 'email-already-in-use':
        return const ValidationFailure(
          userMessage: 'This email is already registered. Please sign in instead.',
          technicalDetails: 'An account with this email address already exists. Please sign in.',
        );
      case 'invalid-email':
        return const ValidationFailure(
          userMessage: 'Please enter a valid email address.',
          technicalDetails: 'Please enter a valid email address.',
        );
      case 'weak-password':
        return const ValidationFailure(
          userMessage: 'The password provided is too weak. Please use at least 8 characters.',
          technicalDetails: 'The password provided is too weak. Please use at least 8 characters.',
        );
      case 'network-request-failed':
        return const NetworkFailure(
          userMessage: 'Network connection failed. Please check your internet connection.',
          technicalDetails: 'Network connection failed. Please check your internet connection.',
        );
      case 'user-disabled':
        return const UnauthorizedFailure(
          userMessage: 'This account has been disabled. Please contact support.',
          technicalDetails: 'This account has been disabled. Please contact support.',
        );
      default:
        return UnknownFailure(
          userMessage: e.message != null && e.message!.isNotEmpty
              ? e.message!
              : 'Authentication error occurred. Please try again.',
          technicalDetails: e.message ?? 'Authentication error occurred.',
        );
    }
  }
}
