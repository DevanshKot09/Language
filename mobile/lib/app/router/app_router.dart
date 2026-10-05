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
