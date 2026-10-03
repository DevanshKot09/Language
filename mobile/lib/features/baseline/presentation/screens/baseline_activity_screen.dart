import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/track_badge.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/models/skill_track.dart';
import '../../providers/baseline_provider.dart';

/// UX-07 & UX-08 BASELINE ACTIVITY SCREEN
/// Interactive question card with accessible options, hint support,
/// read-aloud affordance, and pause/resume modal.
class BaselineActivityScreen extends ConsumerStatefulWidget {
  const BaselineActivityScreen({super.key});

  @override
  ConsumerState<BaselineActivityScreen> createState() => _BaselineActivityScreenState();
}

class _BaselineActivityScreenState extends ConsumerState<BaselineActivityScreen> {
  bool _showHint = false;

  void _showPauseDialog() {
    final ageProfile = ref.read(ageProfileProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        ),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: LinguaTokens.primary600, size: 28),
            SizedBox(width: 10),
            Text('Taking a Break?'),
          ],
        ),
        content: const Text(
          'Your progress is safely saved. You can resume this practice snapshot at any time from your home screen.',
          style: TextStyle(fontSize: 14, height: 1.4, color: LinguaTokens.ink700),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            child: const Text('Save & Exit to Home'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              foregroundColor: Colors.white,
              minimumSize: Size(120, ageProfile.minTouchTarget),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Resume Activity'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ageProfile = ref.watch(ageProfileProvider);
    final baselineAsync = ref.watch(baselineSessionProvider);

    return baselineAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Baseline Activity')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: LinguaTokens.danger600),
                const SizedBox(height: 16),
                Text(
                  'Unable to load activity',
                  style: TextStyle(fontSize: ageProfile.baseFontSize + 2, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
                ),
                const SizedBox(height: 24),
                LinguaButton(
                  label: 'Retry',
                  onPressed: () => ref.read(baselineSessionProvider.notifier).startOrResumeSession(),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) {
        final activity = state.currentActivity;
        final session = state.session;

        // If completed, navigate to completion screen
        if (state.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.baselineCompletion);
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (activity == null || session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Baseline Activity')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No activities available for this track.'),
                  const SizedBox(height: 16),
                  LinguaButton(
                    label: 'Return to Home',
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                  ),
                ],
              ),
            ),
          );
        }

        final currentNumber = state.currentIndex + 1;
        final totalActivities = state.totalActivities;
        final hasSubmitted = state.lastResult != null;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.pause),
              tooltip: 'Pause activity',
              onPressed: _showPauseDialog,
            ),
            title: Text('Activity $currentNumber of $totalActivities'),
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: 'Read question aloud',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reading: "${activity.prompt}"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LinguaTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: (currentNumber) / totalActivities,
                    backgroundColor: LinguaTokens.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.primary600),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: LinguaTokens.space16),

                  // Track & Domain Pill
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LinguaTokens.primary100,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                        ),
                        child: Text(
                          activity.domain.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LinguaTokens.primary700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      TrackBadge(track: SupportTrackExtension.fromApiId(activity.track), compact: true),
                    ],
                  ),
                  const SizedBox(height: LinguaTokens.space16),

                  // Plain-Language Instruction
                  Text(
                    activity.instruction,
                    style: TextStyle(
                      fontSize: ageProfile.baseFontSize,
                      fontWeight: FontWeight.w600,
                      color: LinguaTokens.ink700,
                    ),
                  ),
                  const SizedBox(height: LinguaTokens.space12),

                  // Prompt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(LinguaTokens.space20),
                    decoration: BoxDecoration(
                      color: LinguaTokens.surfaceCard,
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                      border: Border.all(color: LinguaTokens.borderSubtle),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      activity.prompt,
                      style: TextStyle(
                        fontSize: ageProfile.baseFontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  // Interactive Options
                  ...activity.options.map((option) {
                    final isSelected = state.selectedOption == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
                      child: _buildOptionCard(
                        option: option,
                        isSelected: isSelected,
                        hasSubmitted: hasSubmitted,
                        isCorrect: state.lastResult?.correctAnswer == option,
                        minTouchTarget: ageProfile.minTouchTarget,
                        fontSize: ageProfile.baseFontSize,
                        onTap: hasSubmitted
                            ? null
                            : () => ref.read(baselineSessionProvider.notifier).selectOption(option),
                      ),
                    );
                  }),

                  // Optional Hint Accordion
                  if (activity.hint != null && activity.hint!.isNotEmpty) ...[
                    const SizedBox(height: LinguaTokens.space8),
                    InkWell(
                      onTap: () => setState(() => _showHint = !_showHint),
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                              color: LinguaTokens.accent600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showHint ? 'Hide Clue' : 'Need a clue?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: LinguaTokens.accent600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showHint)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(LinguaTokens.space12),
                        decoration: BoxDecoration(
                          color: LinguaTokens.accent100,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                          border: Border.all(color: LinguaTokens.accent500.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          activity.hint!,
                          style: const TextStyle(fontSize: 13, color: LinguaTokens.ink900),
                        ),
                      ),
                  ],

                  // Feedback Banner (after submission)
                  if (hasSubmitted) ...[
                    const SizedBox(height: LinguaTokens.space16),
                    Container(
                      padding: const EdgeInsets.all(LinguaTokens.space12),
                      decoration: BoxDecoration(
                        color: state.lastResult!.isCorrect
                            ? LinguaTokens.successLight
                            : LinguaTokens.primary100,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        border: Border.all(
                          color: state.lastResult!.isCorrect
                              ? LinguaTokens.success600
                              : LinguaTokens.primary500,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.lastResult!.isCorrect
                                ? Icons.check_circle
                                : Icons.lightbulb_outline,
                            color: state.lastResult!.isCorrect
                                ? LinguaTokens.success600
                                : LinguaTokens.primary700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.lastResult!.isCorrect
                                  ? 'Well done! Recorded.'
                                  : 'Good try! Practicing this helps us customize your path.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: state.lastResult!.isCorrect
                                    ? LinguaTokens.success600
                                    : LinguaTokens.primary700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: LinguaTokens.space24),

                  // Bottom Action: Submit or Continue
                  if (!hasSubmitted)
                    LinguaButton(
                      label: 'Check Answer',
                      isLoading: state.isSubmitting,
                      minHeight: ageProfile.minTouchTarget,
                      onPressed: state.selectedOption == null
                          ? null
                          : () => ref.read(baselineSessionProvider.notifier).submitAnswer(),
                    )
                  else
                    LinguaButton(
                      label: currentNumber >= totalActivities
                          ? 'Finish Skill Snapshot'
                          : 'Next Activity',
                      isLoading: state.isSubmitting,
                      minHeight: ageProfile.minTouchTarget,
                      onPressed: () async {
                        setState(() => _showHint = false);
                        await ref.read(baselineSessionProvider.notifier).nextActivity();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String option,
    required bool isSelected,
    required bool hasSubmitted,
    required bool isCorrect,
    required double minTouchTarget,
    required double fontSize,
    required VoidCallback? onTap,
  }) {
    Color borderColor = LinguaTokens.borderSubtle;
    Color bgColor = Colors.white;

    if (isSelected) {
      borderColor = LinguaTokens.primary600;
      bgColor = LinguaTokens.primary100.withValues(alpha: 0.4);
    }

    if (hasSubmitted) {
      if (isSelected && isCorrect) {
        borderColor = LinguaTokens.success600;
        bgColor = LinguaTokens.successLight;
      } else if (isSelected && !isCorrect) {
        borderColor = LinguaTokens.primary600;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
      child: Container(
        constraints: BoxConstraints(minHeight: minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: LinguaTokens.space16,
          vertical: LinguaTokens.space12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? LinguaTokens.primary600 : LinguaTokens.inkMuted,
                  width: 2,
                ),
                color: isSelected ? LinguaTokens.primary600 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: LinguaTokens.space16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: LinguaTokens.ink900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
