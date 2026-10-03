import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../application/progress_providers.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/skill_progress_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/achievement_card.dart';
import '../widgets/timeline_item_tile.dart';
import '../widgets/progress_chart_card.dart';
import '../widgets/ai_progress_insight_card.dart';

/// UX-28 PROGRESS & LEARNING ANALYTICS DASHBOARD
/// Complete educational progress overview tracking observable practice,
/// goals, achievements, and descriptive skill readiness bands.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageProfile = ref.watch(ageProfileProvider);
    final progressAsync = ref.watch(progressDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Learning Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh progress',
            onPressed: () => ref.invalidate(progressDashboardProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildErrorState(context, ref),
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.refresh(progressDashboardProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(LinguaTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NonDiagnosticBanner(compact: true),
                  const SizedBox(height: LinguaTokens.space16),

                  // Greeting & Header
                  Text(
                    _getHeaderTitle(ageProfile.ageBand.name),
                    style: TextStyle(
                      fontSize: ageProfile.baseFontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: LinguaTokens.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getHeaderSubtitle(ageProfile.ageBand.name),
                    style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700),
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  // 1. Core Summary Metrics Card
                  ProgressSummaryCard(
                    summary: data.summary,
                    showStreaks: ageProfile.showStreaks,
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  // 2. AI Progress Insight Card (with assistive disclosure & fallback)
                  if (data.aiInsightSummary != null) ...[
                    AiProgressInsightCard(
                      summary: data.aiInsightSummary!,
                      details: data.aiInsightDetails,
                      fallbackUsed: data.aiFallbackUsed,
                    ),
                    const SizedBox(height: LinguaTokens.space20),
                  ],

                  // 3. Weekly Activity Trend Chart (with text alternative)
                  ProgressChartCard(trend: data.trend),
                  const SizedBox(height: LinguaTokens.space24),

                  // 4. Skills Progress Breakdown (Separation of DLD & Dyslexia)
                  _buildSkillsSection(context, data),
                  const SizedBox(height: LinguaTokens.space24),

                  // 5. Goals Section
                  _buildGoalsSection(context, data),
                  const SizedBox(height: LinguaTokens.space24),

                  // 6. Milestone Achievements Preview
                  _buildAchievementsSection(context, data),
                  const SizedBox(height: LinguaTokens.space24),

                  // 7. Activity Timeline Preview
                  _buildTimelineSection(context, data),
                  const SizedBox(height: LinguaTokens.space32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context, dynamic data) {
    final hasDld = data.dldSkills.isNotEmpty;
    final hasDyslexia = data.dyslexiaSkills.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Skill Readiness & Practice',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.skillDetail),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: LinguaTokens.space8),

        // Spoken Language (DLD) Skills
        if (hasDld && (data.activeTrack == 'dld_track' || data.activeTrack == 'both_track')) ...[
          const Text(
            'Spoken Language Skills (DLD Track)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.dldTrack),
          ),
          const SizedBox(height: LinguaTokens.space8),
          ...data.dldSkills.take(3).map((s) => SkillProgressCard(
                skill: s,
                onTap: () => Navigator.pushNamed(context, AppRoutes.skillDetail),
              )),
          const SizedBox(height: LinguaTokens.space12),
        ],

        // Literacy & Reading (Dyslexia) Skills
        if (hasDyslexia && (data.activeTrack == 'dyslexia_track' || data.activeTrack == 'both_track')) ...[
          const Text(
            'Literacy & Reading Skills (Dyslexia Track)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.dyslexiaTrack),
          ),
          const SizedBox(height: LinguaTokens.space8),
          ...data.dyslexiaSkills.take(3).map((s) => SkillProgressCard(
                skill: s,
                onTap: () => Navigator.pushNamed(context, AppRoutes.skillDetail),
              )),
        ],
      ],
    );
  }

  Widget _buildGoalsSection(BuildContext context, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Learning Goals',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.goals),
              child: const Text('Manage Goals'),
            ),
          ],
        ),
        const SizedBox(height: LinguaTokens.space8),
        if (data.activeGoals.isEmpty)
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.surfaceCard,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(Icons.flag_outlined, size: 32, color: LinguaTokens.primary600),
                const SizedBox(height: 8),
                const Text(
                  'No active goals right now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create a small goal to guide your learning practice.',
                  style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                LinguaButton(
                  label: 'Set a Practice Goal',
                  variant: LinguaButtonVariant.secondary,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createGoal),
                ),
              ],
            ),
          )
        else ...[
          ...data.activeGoals.take(2).map((g) => GoalCard(goal: g)),
          LinguaButton(
            label: '+ Set New Goal',
            variant: LinguaButtonVariant.secondary,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createGoal),
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Milestones & Achievements',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.achievements),
              child: const Text('All Badges'),
            ),
          ],
        ),
        const SizedBox(height: LinguaTokens.space8),
        if (data.recentAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.surfaceCard,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: LinguaTokens.accent600, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complete your first learning activity to unlock your first milestone badge!',
                    style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: LinguaTokens.space12,
              mainAxisSpacing: LinguaTokens.space12,
              childAspectRatio: 1.4,
            ),
            itemCount: data.recentAchievements.length.clamp(0, 4),
            itemBuilder: (context, i) {
              return AchievementCard(
                achievement: data.recentAchievements[i],
                onTap: () => Navigator.pushNamed(context, AppRoutes.achievements),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Learning Activity',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.timeline),
              child: const Text('Full History'),
            ),
          ],
        ),
        const SizedBox(height: LinguaTokens.space8),
        if (data.timeline.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Your learning activity will appear here once you start practicing.',
              style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
            ),
          )
        else
          ...data.timeline.take(4).map((item) => TimelineItemTile(item: item)),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: LinguaTokens.danger600),
            const SizedBox(height: 16),
            const Text(
              'Progress Unavailable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t load your progress right now. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
            ),
            const SizedBox(height: 20),
            LinguaButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(progressDashboardProvider),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderTitle(String ageBand) {
    switch (ageBand.toLowerCase()) {
      case 'child':
        return 'Your Practice Stars & Journey!';
      case 'adult':
        return 'Learning Analytics & Progress';
      case 'teen':
      default:
        return 'Your Practice & Growth Journey';
    }
  }

  String _getHeaderSubtitle(String ageBand) {
    switch (ageBand.toLowerCase()) {
      case 'child':
        return 'Look at all the wonderful reading and speaking activities you explored!';
      case 'adult':
        return 'Objective tracking of practice sessions, skill automaticity, and self-directed goals.';
      case 'teen':
      default:
        return 'Tracking skill mastery, consistency, and independence over time.';
    }
  }
}
