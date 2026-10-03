import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/achievement_models.dart';
import '../../application/progress_providers.dart';
import '../widgets/achievement_card.dart';

class AchievementCenterScreen extends ConsumerWidget {
  const AchievementCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestone Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh achievements',
            onPressed: () => ref.invalidate(achievementsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: achievementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Failed to load achievements: $err'),
          ),
          data: (achievements) {
            final unlockedCount = achievements.where((a) => a.isUnlocked).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(LinguaTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encouraging banner
                  Container(
                    padding: const EdgeInsets.all(LinguaTokens.space16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 36, color: Color(0xFFD97706)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$unlockedCount of ${achievements.length} Milestones Celebrated',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: LinguaTokens.ink900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Milestones celebrate practice consistency and exploration. There are no penalties or rankings.',
                                style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: LinguaTokens.space12,
                      mainAxisSpacing: LinguaTokens.space12,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, i) {
                      final ach = achievements[i];
                      return AchievementCard(
                        achievement: ach,
                        onTap: () => _showAchievementDetail(context, ach),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, AchievementItem ach) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              ach.isUnlocked ? Icons.verified : Icons.lock_outline,
              color: ach.isUnlocked ? LinguaTokens.success600 : LinguaTokens.inkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(ach.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ach.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text(
              'Category: ${ach.category.toUpperCase()} • Tier: ${ach.badgeTier.toUpperCase()}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LinguaTokens.inkMuted),
            ),
            const SizedBox(height: 8),
            Text(
              ach.isUnlocked
                  ? 'Status: Achieved! Excellent practice effort.'
                  : 'Progress: ${ach.progressValue} of ${ach.threshold} activities completed.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ach.isUnlocked ? LinguaTokens.success600 : LinguaTokens.ink700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
