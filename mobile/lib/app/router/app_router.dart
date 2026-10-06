import 'package:flutter/material.dart';
import '../../features/welcome/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/signup_screen.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_dashboard_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_learner_detail_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_schedule_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_messages_screen.dart';
import '../../features/collaboration/presentation/screens/collaboration_chat_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_live_session_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_session_summary_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_profile_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_notifications_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_consent_sharing_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_availability_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_verification_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_help_support_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_settings_screen.dart';

/// Central route constants for LINGUA AI.
class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Specialist Workspace & Collaboration
  static const String specialistDashboard = '/specialist';
  static const String specialistLearnerDetail = '/specialist/learner';
  static const String specialistSchedule = '/specialist/schedule';
  static const String specialistMessages = '/specialist/messages';
  static const String chatThread = '/collaboration/chat';
  static const String specialistLiveSession = '/specialist/live-session';
  static const String specialistSessionSummary = '/specialist/session-summary';
  static const String specialistProfile = '/specialist/profile';
  static const String specialistNotifications = '/specialist/notifications';
  static const String specialistConsentSharing = '/specialist/consent-sharing';
  static const String specialistAvailabilitySettings =
      '/specialist/availability-settings';
  static const String specialistVerificationStatus =
      '/specialist/verification-status';
  static const String specialistHelpSupport = '/specialist/help-support';
  static const String specialistSettings = '/specialist/settings';
}

/// Central route generator for LINGUA AI.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case AppRoutes.welcome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.signup:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignupScreen(),
        );
      case AppRoutes.forgotPassword:
        final initialEmail = settings.arguments as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ForgotPasswordScreen(initialEmail: initialEmail),
        );
      case AppRoutes.specialistDashboard:
        final initialTab = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SpecialistDashboardScreen(initialTab: initialTab),
        );
      case AppRoutes.specialistLearnerDetail:
        final learnerId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SpecialistLearnerDetailScreen(learnerId: learnerId),
        );
      case AppRoutes.specialistSchedule:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistScheduleScreen(showBottomNav: true),
        );
      case AppRoutes.specialistMessages:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistMessagesScreen(showBottomNav: true),
        );
      case AppRoutes.chatThread:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CollaborationChatScreen(
            conversationId: args['conversation_id'] as String? ?? 'conv-default',
            title: args['title'] as String? ?? 'Collaboration Thread',
            subtitle: args['subtitle'] as String?,
            targetLearnerId: args['target_learner_id'] as String?,
            roles: (args['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
            isLocked: args['is_locked'] as bool? ?? false,
          ),
        );
      case AppRoutes.specialistLiveSession:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SpecialistLiveSessionScreen(
            sessionOrLearner: settings.arguments,
          ),
        );
      case AppRoutes.specialistSessionSummary:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SpecialistSessionSummaryScreen(
            sessionOrSummary: settings.arguments,
          ),
        );
      case AppRoutes.specialistProfile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistProfileScreen(),
        );
      case AppRoutes.specialistNotifications:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistNotificationsScreen(),
        );
      case AppRoutes.specialistConsentSharing:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistConsentSharingScreen(),
        );
      case AppRoutes.specialistAvailabilitySettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistAvailabilityScreen(),
        );
      case AppRoutes.specialistVerificationStatus:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistVerificationScreen(),
        );
      case AppRoutes.specialistHelpSupport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistHelpSupportScreen(),
        );
      case AppRoutes.specialistSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SpecialistSettingsScreen(),
        );

      default:

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
