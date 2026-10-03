import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../providers/baseline_provider.dart';

/// UX-09 BASELINE COMPLETION & CELEBRATION
/// Celebrates completion with non-punitive messaging and transitions
/// to the descriptive Skill Snapshot.
class BaselineCompletionScreen extends ConsumerWidget {
  const BaselineCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageProfile = ref.watch(ageProfileProvider);
    final baselineAsync = ref.watch(baselineSessionProvider);
    final sessionState = baselineAsync.asData?.value;
    final total = sessionState?.totalActivities ?? 6;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LinguaTokens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Celebration Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: LinguaTokens.successLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: LinguaTokens.success600, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A22C55E),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 52,
                    color: LinguaTokens.success600,
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Title
              Text(
                'Skill Snapshot Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ageProfile.baseFontSize + 10,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: LinguaTokens.space12),

              // Subtitle
              Text(
                'Thank you for completing $total practice activities. We have mapped your learning readiness and strengths across key skill areas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ageProfile.baseFontSize,
                  color: LinguaTokens.ink700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Safety Reminder
              const NonDiagnosticBanner(compact: true),

              const Spacer(),

              // Primary CTA: View Snapshot
              LinguaButton(
                label: 'View My Skill Snapshot',
                minHeight: ageProfile.minTouchTarget,
                onPressed: () {
                  // Invalidate snapshot provider to ensure fresh data
                  ref.invalidate(skillSnapshotProvider);
                  Navigator.pushReplacementNamed(context, AppRoutes.skillSnapshot);
                },
              ),
              const SizedBox(height: LinguaTokens.space12),

              // Secondary CTA: Home
              LinguaButton(
                label: 'Return to Home',
                variant: LinguaButtonVariant.secondary,
                minHeight: ageProfile.minTouchTarget,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
