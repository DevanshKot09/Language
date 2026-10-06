import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/user_role.dart';
import 'animated_error_character.dart';
import 'error_state_type.dart';

/// Reusable, animated Error State screen for LINGUA AI.
///
/// Displayed when:
/// - A route is not found (404 / notFound)
/// - The device has no internet connection (noInternet)
/// - A server or network API call fails on initial load (serverError)
/// - Any unexpected unhandled error occurs (generic)
///
/// Features:
/// - Prominent top error badge / code (404, OFFLINE, 500, ERROR)
/// - Procedurally animated "Volt-E" character (unplugged wire + gentle humor + zap)
/// - Clean typography matching the LINGUA AI design system
/// - Primary action ("Try again" or "Go to Home")
/// - Contextual secondary "Go to Home" action (routes to /specialist if specialist, else /login)
/// - Accessible semantics labels & automatic support for `disableAnimations`.
class ErrorStateView extends ConsumerWidget {
  final ErrorStateType type;
  final String? title;
  final String? message;
  final String? errorCode;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final bool showHomeButton;
  final bool isFullScreen;

  const ErrorStateView({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.errorCode,
    this.onRetry,
    this.onGoHome,
    this.showHomeButton = true,
    this.isFullScreen = true,
  });

  /// Navigates to the appropriate safe home screen:
  /// - /specialist if logged in as Specialist
  /// - /login if unauthenticated or any other role
  /// (Strict rule: Never /home).
  static void navigateSafeHome(BuildContext context, WidgetRef ref) {
    final session = ref.read(userSessionProvider);
    final targetRoute = (session.isAuthenticated && session.currentRole == UserRole.specialist)
        ? AppRoutes.specialistDashboard
        : AppRoutes.login;

    Navigator.of(context).pushNamedAndRemoveUntil(
      targetRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = title ?? type.defaultTitle;
    final resolvedMessage = message ?? type.defaultMessage;
    final resolvedBadge = errorCode ?? type.defaultBadge;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Top Error Badge / Code
                _buildTopBadge(context, resolvedBadge, isDark),

                const SizedBox(height: 20),

                // 2. Animated Volt-E Character (Unplugged wire + curiosity + zap)
                Semantics(
                  label: 'Illustration of a robot inspecting an unplugged power cable',
                  image: true,
                  child: AnimatedErrorCharacter(
                    size: 230,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Bold Friendly Title
                Semantics(
                  header: true,
                  child: Text(
                    resolvedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: LinguaTokens.fontPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : LinguaTokens.ink900,
                      letterSpacing: -0.4,
                      height: 1.25,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. Short Explanatory Message Line
                Text(
                  resolvedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: LinguaTokens.fontPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF94A3B8) : LinguaTokens.inkMuted,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // 5. Actions (Primary Retry or Home + Secondary Home)
                _buildActionButtons(context, ref),
              ],
            ),
          ),
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : LinguaTokens.paper50,
        body: content,
      );
    }

    return content;
  }

  Widget _buildTopBadge(BuildContext context, String badgeText, bool isDark) {
    final Color badgeBg;
    final Color badgeFg;
    final Color borderColor;

    switch (type) {
      case ErrorStateType.notFound:
        badgeBg = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEDE9FE);
        badgeFg = LinguaTokens.primary600;
        borderColor = LinguaTokens.primary500.withValues(alpha: 0.3);
        break;
      case ErrorStateType.noInternet:
        badgeBg = isDark ? const Color(0xFF332A15) : const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFD97706);
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        break;
      case ErrorStateType.serverError:
        badgeBg = isDark ? const Color(0xFF3B1D22) : const Color(0xFFFFE4E6);
        badgeFg = const Color(0xFFE11D48);
        borderColor = const Color(0xFFF43F5E).withValues(alpha: 0.35);
        break;
      case ErrorStateType.generic:
        badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        badgeFg = const Color(0xFF475569);
        borderColor = const Color(0xFF64748B).withValues(alpha: 0.3);
        break;
    }

    return Semantics(
      label: 'Error status code: $badgeText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 16, color: badgeFg),
            const SizedBox(width: 7),
            Text(
              badgeText,
              style: TextStyle(
                fontFamily: LinguaTokens.fontPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: badgeFg,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final isNotFound = type == ErrorStateType.notFound;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Button
        if (isNotFound) ...[
          // For notFound, primary button goes home
          ElevatedButton.icon(
            key: const Key('error_state_go_home_primary_button'),
            onPressed: () {
              if (onGoHome != null) {
                onGoHome!();
              } else {
                navigateSafeHome(context, ref);
              }
            },
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              elevation: 0,
            ),
          ),
        ] else ...[
          // For network / server errors, primary button tries again
          ElevatedButton.icon(
            key: const Key('error_state_retry_button'),
            onPressed: onRetry ?? () {},
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              elevation: 0,
            ),
          ),
        ],

        // Secondary "Go Home" Button (when onRetry is primary and showHomeButton is true)
        if (!isNotFound && showHomeButton) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('error_state_go_home_secondary_button'),
            onPressed: () {
              if (onGoHome != null) {
                onGoHome!();
              } else {
                navigateSafeHome(context, ref);
              }
            },
            icon: const Icon(Icons.home_outlined, size: 19),
            label: const Text('Go to Home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LinguaTokens.ink700,
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: LinguaTokens.borderSubtle, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              ),
              textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
