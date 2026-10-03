import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../application/progress_providers.dart';
import '../widgets/timeline_item_tile.dart';

class ActivityTimelineScreen extends ConsumerWidget {
  const ActivityTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(activityTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh timeline',
            onPressed: () => ref.invalidate(activityTimelineProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Failed to load timeline: $err'),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(LinguaTokens.space24),
                  child: Text(
                    'Your learning activity will appear here once you start practicing.',
                    style: TextStyle(fontSize: 14, color: LinguaTokens.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(LinguaTokens.space16),
              children: [
                Container(
                  padding: const EdgeInsets.all(LinguaTokens.space12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    border: Border.all(color: LinguaTokens.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: LinguaTokens.ink700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Privacy-Protected Activity Stream. Only educational practice events are recorded.',
                          style: TextStyle(fontSize: 11, color: LinguaTokens.ink700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LinguaTokens.space16),
                ...items.map((item) => TimelineItemTile(item: item)),
              ],
            );
          },
        ),
      ),
    );
  }
}
