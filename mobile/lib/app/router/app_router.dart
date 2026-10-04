import 'package:flutter/material.dart';
import '../../features/welcome/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/role_selection/role_selection_screen.dart';
import '../../features/age_selection/age_selection_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/signup_screen.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/learner_home/learner_home_screen.dart';
import '../../features/learning_path/learning_path_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/accessibility/accessibility_settings_screen.dart';
import '../../features/speech/presentation/screens/voice_privacy_center_screen.dart';
import '../../features/baseline/presentation/screens/baseline_intro_screen.dart';
import '../../features/baseline/presentation/screens/baseline_activity_screen.dart';
import '../../features/baseline/presentation/screens/baseline_completion_screen.dart';
import '../../features/baseline/presentation/screens/skill_snapshot_screen.dart';
import '../../features/learning/presentation/screens/practice_hub_screen.dart';
import '../../features/learning/presentation/screens/lesson_player_screen.dart';
import '../../features/learning/presentation/screens/dld_track_dashboard_screen.dart';
import '../../features/learning/presentation/screens/dyslexia_track_dashboard_screen.dart';
import '../../features/ai/presentation/screens/ai_conversation_screen.dart';
import '../../features/progress/presentation/screens/skill_progress_detail_screen.dart';
import '../../features/progress/presentation/screens/activity_timeline_screen.dart';
import '../../features/progress/presentation/screens/goals_dashboard_screen.dart';
import '../../features/progress/presentation/screens/create_goal_screen.dart';
import '../../features/progress/presentation/screens/achievement_center_screen.dart';
import '../../features/collaboration/presentation/screens/parent_dashboard_screen.dart';
import '../../features/collaboration/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/collaboration/presentation/screens/create_assignment_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_dashboard_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_learner_detail_screen.dart';
import '../../features/collaboration/presentation/screens/learner_report_screen.dart';
import '../../features/collaboration/presentation/screens/specialist_schedule_screen.dart';
import '../../features/collaboration/presentation/screens/relationships_screen.dart';
import '../../features/collaboration/presentation/screens/invite_collaborator_screen.dart';

/// Central route constants for LINGUA AI.
class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/';
  static const String roles = '/roles';
  static const String ageMode = '/age-mode';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String path = '/path';
  static const String practice = '/practice';
  static const String dldDashboard = '/dld/dashboard';
  static const String dyslexiaDashboard = '/dyslexia/dashboard';
  static const String lessonPlayer = '/lesson/player';
  static const String progress = '/progress';
  static const String skillDetail = '/progress/skills';
  static const String timeline = '/progress/timeline';
  static const String goals = '/goals';
  static const String createGoal = '/goals/create';
  static const String achievements = '/achievements';
  static const String settings = '/settings';
  static const String accessibility = '/accessibility';
  static const String voicePrivacy = '/voice-privacy';
  static const String baselineIntro = '/baseline/intro';
  static const String baselineActivity = '/baseline/activity';
  static const String baselineCompletion = '/baseline/completion';
  static const String skillSnapshot = '/baseline/snapshot';
  static const String aiConversation = '/ai-conversation';

  // Phase 11 Collaboration Workspaces & Reports
  static const String parentDashboard = '/parent';
  static const String teacherDashboard = '/teacher';
  static const String createAssignment = '/teacher/assignments/create';
  static const String specialistDashboard = '/specialist';
  static const String specialistLearnerDetail = '/specialist/learner';
  static const String specialistSchedule = '/specialist/schedule';
  static const String reportBuilder = '/reports/builder';
  static const String learnerReport = '/reports/learner';
  static const String relationships = '/relationships';
  static const String inviteCollaborator = '/relationships/invite';
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
      case AppRoutes.roles:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RoleSelectionScreen(),
        );
      case AppRoutes.ageMode:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AgeSelectionScreen(),
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
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
      case AppRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LearnerHomeScreen(),
        );
      case AppRoutes.path:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LearningPathScreen(),
        );
      case AppRoutes.progress:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProgressScreen(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      case AppRoutes.accessibility:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AccessibilitySettingsScreen(),
        );
      case AppRoutes.voicePrivacy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VoicePrivacyCenterScreen(),
        );
      case AppRoutes.baselineIntro:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BaselineIntroScreen(),
        );
      case AppRoutes.baselineActivity:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BaselineActivityScreen(),
        );
      case AppRoutes.baselineCompletion:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BaselineCompletionScreen(),
        );
      case AppRoutes.skillSnapshot:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SkillSnapshotScreen(),
        );
      case AppRoutes.practice:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PracticeHubScreen(),
        );
      case AppRoutes.dldDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DldTrackDashboardScreen(),
        );
      case AppRoutes.dyslexiaDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DyslexiaTrackDashboardScreen(),
        );
      case AppRoutes.aiConversation:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AiConversationScreen(),
        );
      case AppRoutes.lessonPlayer:
        final lessonId = settings.arguments as String? ?? 'lesson-dld-001';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LessonPlayerScreen(lessonId: lessonId),
        );
      case AppRoutes.skillDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SkillProgressDetailScreen(),
        );
      case AppRoutes.timeline:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ActivityTimelineScreen(),
        );
      case AppRoutes.goals:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GoalsDashboardScreen(),
        );
      case AppRoutes.createGoal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateGoalScreen(),
        );
      case AppRoutes.achievements:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AchievementCenterScreen(),
        );

      case AppRoutes.parentDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ParentDashboardScreen(),
        );
      case AppRoutes.teacherDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TeacherDashboardScreen(),
        );
      case AppRoutes.createAssignment:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateAssignmentScreen(),
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
      case AppRoutes.reportBuilder:
      case AppRoutes.learnerReport:
        final learnerId = settings.arguments as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LearnerReportScreen(learnerId: learnerId),
        );
      case AppRoutes.relationships:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RelationshipsScreen(),
        );
      case AppRoutes.inviteCollaborator:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InviteCollaboratorScreen(),
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
