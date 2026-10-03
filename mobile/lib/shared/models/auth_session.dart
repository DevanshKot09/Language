import 'auth_user.dart';
import 'user_profile.dart';
import 'onboarding_status.dart';

/// Complete authenticated session payload
class AuthSession {
  final AuthUser user;
  final UserProfile profile;
  final OnboardingStatus onboarding;
  final String? accessToken;
  final String? refreshToken;

  const AuthSession({
    required this.user,
    required this.profile,
    required this.onboarding,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final onboardingJson = json['onboarding'] as Map<String, dynamic>? ?? {};
    final tokensJson = json['tokens'] as Map<String, dynamic>?;

    return AuthSession(
      user: AuthUser.fromJson(userJson),
      profile: UserProfile.fromJson(profileJson),
      onboarding: OnboardingStatus.fromJson(onboardingJson),
      accessToken: tokensJson?['access_token'] as String?,
      refreshToken: tokensJson?['refresh_token'] as String?,
    );
  }
}
