import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/track_badge.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_animated_card.dart';
import '../../app/providers/age_profile_provider.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';
import '../learning/application/learning_providers.dart';
import '../progress/application/progress_providers.dart';

/// UX-12 LEARNER HOME / LEARNING DASHBOARD
/// Daily learning overview with hero next-action card, separate track
/// progress cards, non-punitive reward badges, and bottom navigation.
class LearnerHomeScreen extends ConsumerStatefulWidget {
  const LearnerHomeScreen({super.key});

  @override
  ConsumerState<LearnerHomeScreen> createState() => _LearnerHomeScreenState();
}

class _LearnerHomeScreenState extends ConsumerState<LearnerHomeScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ageProfile = ref.watch(ageProfileProvider);
    final session = ref.watch(userSessionProvider);
    final progressData = ref.watch(progressDashboardProvider).asData?.value;

    final double dldProgress = progressData?.dldTrackSummary != null && progressData!.dldTrackSummary!.totalLessons > 0
        ? (progressData.dldTrackSummary!.completedLessons / progressData.dldTrackSummary!.totalLessons).clamp(0.0, 1.0)
        : (progressData?.dldTrackSummary?.averageAccuracy ?? 0.78);
    final String dldLabel = '${(dldProgress * 100).toInt()}% Readiness';

    final double dyslexiaProgress = progressData?.dyslexiaTrackSummary != null && progressData!.dyslexiaTrackSummary!.totalLessons > 0
        ? (progressData.dyslexiaTrackSummary!.completedLessons / progressData.dyslexiaTrackSummary!.totalLessons).clamp(0.0, 1.0)
        : (progressData?.dyslexiaTrackSummary?.averageAccuracy ?? 0.65);
    final String dyslexiaLabel = '${(dyslexiaProgress * 100).toInt()}% Readiness';

    final activeGoal = progressData?.activeGoals.isNotEmpty == true ? progressData!.activeGoals.first : null;
    final streakDays = progressData?.summary.consistencyStreakDays ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Role Workspaces',
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () => _showRoleSwitchModal(context),
          ),
          IconButton(
            tooltip: 'Accessibility',
            icon: const Icon(Icons.accessibility_new),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.accessibility),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting & Active Profile Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${session.learnerName}!',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: LinguaTokens.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ageProfile.displayName} • ${ageProfile.ageRangeLabel}',
                          style: const TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LinguaTokens.space8),
                  TrackBadge(track: session.activeTrack, compact: true),
                ],
              ),
              const SizedBox(height: LinguaTokens.space12),

              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              // Hero: Next Best Action Card (Baseline & Lesson Aware)
              Builder(
                builder: (context) {
                  final baselineStatus = session.profile?.baselineStatus ?? 'not_started';
                  final hubData = ref.watch(practiceHubProvider).asData?.value;

                  final String tag;
                  final String title;
                  final String subtitle;
                  final String btnLabel;
                  final VoidCallback onAction;

                  if (baselineStatus == 'in_progress') {
                    tag = 'IN PROGRESS';
                    title = 'Continue Skill Snapshot';
                    subtitle = 'Pick up where you left off. Your activities are safely saved.';
                    btnLabel = 'Continue Skill Snapshot';
                    onAction = () => Navigator.pushNamed(context, AppRoutes.baselineActivity);
                  } else if (baselineStatus == 'completed') {
                    // Check if there is an in-progress lesson
                    final inProgressLesson = (hubData != null && hubData.inProgressLessons.isNotEmpty)
                        ? hubData.inProgressLessons.first
                        : null;

                    if (inProgressLesson != null) {
                      tag = 'PRACTICE IN PROGRESS';
                      title = 'Resume: ${inProgressLesson.title}';
                      subtitle = '${inProgressLesson.completedExercises} of ${inProgressLesson.totalExercises} activities completed. Pick up your practice.';
                      btnLabel = 'Resume Lesson';
                      onAction = () => Navigator.pushNamed(
                            context,
                            AppRoutes.lessonPlayer,
                            arguments: inProgressLesson.id,
                          );
                    } else {
                      tag = 'DAILY PRACTICE READY';
                      title = 'Start Your Learning Practice';
                      subtitle = 'Explore curriculum activities designed for your active skill focus.';
                      btnLabel = 'Open Practice Hub';
                      onAction = () => Navigator.pushNamed(context, AppRoutes.practice);
                    }
                  } else {
                    tag = 'INITIAL SETUP';
                    title = 'Build your Skill Snapshot';
                    subtitle = 'Complete a gentle 4-minute baseline to personalize your learning exercises.';
                    btnLabel = 'Start Skill Snapshot';
                    onAction = () => Navigator.pushNamed(context, AppRoutes.baselineIntro);
                  }

                  return LinguaAnimatedCard(
                    padding: const EdgeInsets.all(LinguaTokens.space20),
                    backgroundColor: LinguaTokens.primary700,
                    borderRadius: LinguaTokens.radiusHero,
                    borderColor: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: LinguaTokens.space12),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: (ageProfile.baseFontSize + 4).clamp(16.0, 22.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: (ageProfile.baseFontSize - 2).clamp(13.0, 16.0),
                            color: Colors.white,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: LinguaTokens.space16),
                        LinguaButton(
                          label: btnLabel,
                          minHeight: ageProfile.minTouchTarget,
                          onPressed: onAction,
                          variant: LinguaButtonVariant.secondary,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: LinguaTokens.space24),

              // Separate Track Cards
              const Text(
                'Your Active Skill Tracks',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaAnimatedCard(
                animationDelayMs: 60,
                backgroundColor: LinguaTokens.dldTrackBg,
                borderColor: LinguaTokens.dldTrack.withValues(alpha: 0.3),
                onTap: () => Navigator.pushNamed(context, AppRoutes.dldDashboard),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.chat_bubble_outline, color: LinguaTokens.dldTrack, size: 20),
                    ),
                    const SizedBox(width: LinguaTokens.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spoken Language (DLD Track)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Vocabulary breadth • Morphosyntax',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: dldProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.dldTrack),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: LinguaTokens.space12),
                    Text(
                      dldLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LinguaTokens.dldTrack),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LinguaTokens.space12),

              LinguaAnimatedCard(
                animationDelayMs: 120,
                backgroundColor: LinguaTokens.dyslexiaTrackBg,
                borderColor: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.3),
                onTap: () => Navigator.pushNamed(context, AppRoutes.dyslexiaDashboard),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.auto_stories_outlined, color: LinguaTokens.dyslexiaTrack, size: 20),
                    ),
                    const SizedBox(width: LinguaTokens.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Literacy & Reading (Dyslexia Track)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Phonological blending • Decoding',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: dyslexiaProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.dyslexiaTrack),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: LinguaTokens.space12),
                    Text(
                      dyslexiaLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LinguaTokens.dyslexiaTrack),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LinguaTokens.space20),

              // Milestone / Goal Focus Card
              LinguaAnimatedCard(
                animationDelayMs: 180,
                backgroundColor: LinguaTokens.accent100,
                borderColor: LinguaTokens.accent500.withValues(alpha: 0.3),
                onTap: () => Navigator.pushNamed(
                  context,
                  activeGoal != null ? AppRoutes.goals : AppRoutes.achievements,
                ),
                child: Row(
                  children: [
                    Icon(
                      activeGoal != null ? Icons.flag : Icons.star,
                      color: LinguaTokens.accent600,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeGoal != null
                                ? 'Active Goal: ${activeGoal.title}'
                                : 'Consistent Effort Milestone',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LinguaTokens.ink900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeGoal != null
                                ? '${activeGoal.targetCount} practice target (${activeGoal.targetFrequency})'
                                : (streakDays > 0
                                    ? 'You have practiced $streakDays day${streakDays > 1 ? "s" : ""} recently. Great habit!'
                                    : 'Start your practice session to build your habit!'),
                            style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: LinguaTokens.inkMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (index) {
          setState(() => _bottomNavIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.path);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.progress);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.alt_route_outlined), selectedIcon: Icon(Icons.alt_route), label: 'Path'),
          NavigationDestination(icon: Icon(Icons.trending_up), selectedIcon: Icon(Icons.trending_up), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showRoleSwitchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: LinguaTokens.space16, horizontal: LinguaTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Switch Role Workspace',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access different role dashboards and management tools.',
                style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space16),
              ListTile(
                leading: const Icon(Icons.school, color: LinguaTokens.primary600),
                title: const Text('Learner Workspace'),
                subtitle: const Text('Daily lessons, practice, and skill tracking'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.family_restroom, color: LinguaTokens.success600),
                title: const Text('Parent Workspace'),
                subtitle: const Text('Connected children, progress & home activities'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.parentDashboard);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: LinguaTokens.dldTrack),
                title: const Text('Educator / Teacher Workspace'),
                subtitle: const Text('Classroom students, assignments & trends'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.teacherDashboard);
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety, color: LinguaTokens.dyslexiaTrack),
                title: const Text('Specialist Caseload'),
                subtitle: const Text('Clinical caseload, goals & AI review'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.specialistDashboard);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
