import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../core/widgets/track_badge.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../../../app/providers/session_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../providers/baseline_provider.dart';

/// UX-06 SKILL BASELINE INTRODUCTION
/// Non-diagnostic introduction to the initial skill baseline.
/// Clarifies purpose, establishes safety boundary, and sets expectations.
class BaselineIntroScreen extends ConsumerWidget {
  const BaselineIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageProfile = ref.watch(ageProfileProvider);
    final session = ref.watch(userSessionProvider);
    final baselineState = ref.watch(baselineSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Baseline'),
        actions: [
          IconButton(
            tooltip: 'Accessibility Settings',
            icon: const Icon(Icons.accessibility_new),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.accessibility),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Safety & Non-Diagnostic Banner
              const NonDiagnosticBanner(),
              const SizedBox(height: LinguaTokens.space20),

              // Track & Purpose Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Your Skill Snapshot',
                      style: TextStyle(
                        fontSize: ageProfile.baseFontSize + 8,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                  ),
                  TrackBadge(track: session.activeTrack, compact: true),
                ],
              ),
              const SizedBox(height: LinguaTokens.space12),

              Text(
                'Let\'s find your comfortable learning starting point. This quick practice activity helps us suggest the best exercises for you.',
                style: TextStyle(
                  fontSize: ageProfile.baseFontSize,
                  color: LinguaTokens.ink700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Informative Cards
              _buildInfoTile(
                icon: Icons.timer_outlined,
                title: 'Short & Gentle',
                subtitle: 'Takes about 4–6 minutes. You can pause anytime.',
                color: LinguaTokens.primary600,
                bg: LinguaTokens.primary100,
              ),
              const SizedBox(height: LinguaTokens.space12),

              _buildInfoTile(
                icon: Icons.favorite_border,
                title: 'No Pressure or Grades',
                subtitle: 'Every response is helpful. There are no failing scores or medical tests.',
                color: LinguaTokens.success600,
                bg: LinguaTokens.successLight,
              ),
              const SizedBox(height: LinguaTokens.space12),

              _buildInfoTile(
                icon: Icons.explore_outlined,
                title: 'Personalized Practice',
                subtitle: 'Builds your custom learning path tailored to your age and learning style.',
                color: LinguaTokens.accent600,
                bg: LinguaTokens.accent100,
              ),

              const SizedBox(height: LinguaTokens.space32),

              // Action Buttons
              LinguaButton(
                label: baselineState.isLoading ? 'Preparing Activities...' : 'Start Skill Snapshot',
                isLoading: baselineState.isLoading,
                minHeight: ageProfile.minTouchTarget,
                onPressed: baselineState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(baselineSessionProvider.notifier).startOrResumeSession();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, AppRoutes.baselineActivity);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not load snapshot activities: $e'),
                                backgroundColor: LinguaTokens.danger600,
                              ),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaButton(
                label: 'Do This Later',
                variant: LinguaButtonVariant.secondary,
                minHeight: ageProfile.minTouchTarget,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: LinguaTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LinguaTokens.ink700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
