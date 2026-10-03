import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/ai_review_card.dart';

class SpecialistLearnerDetailScreen extends ConsumerStatefulWidget {
  final String learnerId;

  const SpecialistLearnerDetailScreen({super.key, required this.learnerId});

  @override
  ConsumerState<SpecialistLearnerDetailScreen> createState() => _SpecialistLearnerDetailScreenState();
}

class _SpecialistLearnerDetailScreenState extends ConsumerState<SpecialistLearnerDetailScreen> {
  final _goalTitleController = TextEditingController();
  final _goalDescController = TextEditingController();

  @override
  void dispose() {
    _goalTitleController.dispose();
    _goalDescController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Specialist Support Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goalTitleController,
              decoration: const InputDecoration(labelText: 'Goal Title (e.g. Practice 3 Lessons)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalDescController,
              decoration: const InputDecoration(labelText: 'Clinical/Support Rationale'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_goalTitleController.text.trim().isEmpty) return;
              try {
                final repo = ref.read(collaborationRepositoryProvider);
                await repo.createSpecialistGoal(
                  widget.learnerId,
                  title: _goalTitleController.text.trim(),
                  description: _goalDescController.text.trim(),
                  goalType: 'complete_lessons',
                  targetCount: 3,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ref.invalidate(specialistLearnerDetailProvider(widget.learnerId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Specialist support goal created.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create goal: $e')),
                  );
                }
              }
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(specialistLearnerDetailProvider(widget.learnerId));

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Learner Dossier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Generate Report',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.reportBuilder),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading learner dossier: $e')),
        data: (data) {
          final displayName = data['display_name'] ?? 'Learner';
          final ageBand = (data['age_band'] ?? 'teen').toString().toUpperCase();
          final supportFocus = (data['support_focus'] ?? 'dld_track').toString().replaceFirst('_', ' ').toUpperCase();
          final baselineStatus = (data['baseline_status'] ?? 'not_started').toString().toUpperCase();
          final metrics = data['progress_summary'] ?? {};
          final skills = (data['skills'] as List<dynamic>?) ?? [];
          final goals = (data['goals'] as List<dynamic>?) ?? [];
          final recs = (data['ai_recommendations'] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                    side: const BorderSide(color: LinguaTokens.borderSubtle),
                  ),
                  color: LinguaTokens.paper100,
                  child: Padding(
                    padding: const EdgeInsets.all(LinguaTokens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: LinguaTokens.space8),
                        Text(
                          'Age Band: $ageBand • Support Track: $supportFocus',
                          style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                        ),
                        Text(
                          'Baseline Assessment: $baselineStatus',
                          style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                        ),
                        const Divider(height: LinguaTokens.space24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Lessons', '${metrics['total_lessons_completed'] ?? 0}'),
                            _buildStat('Attempts', '${metrics['total_exercises_attempted'] ?? 0}'),
                            _buildStat('Practice Min', '${metrics['total_practice_time_minutes'] ?? 0}'),
                            _buildStat('Ind. Rate', '${metrics['independent_rate'] ?? 0.0}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: LinguaTokens.space16),

                // Skill Readiness Bands
                const Text('Curriculum Skill Bands', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: LinguaTokens.space8),
                if (skills.isEmpty)
                  const Text('No skill attempts recorded yet.', style: TextStyle(color: LinguaTokens.inkMuted))
                else
                  ...skills.map((s) => Card(
                        margin: const EdgeInsets.only(bottom: LinguaTokens.space8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                          side: const BorderSide(color: LinguaTokens.borderSubtle),
                        ),
                        color: LinguaTokens.paper100,
                        child: ListTile(
                          title: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text('Band: ${(s['current_band'] ?? '').toString().toUpperCase()} • Attempts: ${s['attempt_count']}'),
                          trailing: Text('${(s['accuracy'] ?? 0.0).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )),
                const SizedBox(height: LinguaTokens.space16),

                // Goals & Specialist Target
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Learning & Support Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showAddGoalDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Goal'),
                    ),
                  ],
                ),
                if (goals.isEmpty)
                  const Text('No goals currently active.', style: TextStyle(color: LinguaTokens.inkMuted))
                else
                  ...goals.map((g) => Card(
                        margin: const EdgeInsets.only(bottom: LinguaTokens.space8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                          side: const BorderSide(color: LinguaTokens.borderSubtle),
                        ),
                        color: LinguaTokens.paper100,
                        child: ListTile(
                          leading: const Icon(Icons.flag_outlined, color: LinguaTokens.success600),
                          title: Text(g['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(g['description'] ?? 'Target goal'),
                        ),
                      )),
                const SizedBox(height: LinguaTokens.space16),

                // AI Recommendations Pending Review
                const Text('AI Suggestions for Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: LinguaTokens.space8),
                if (recs.isEmpty)
                  const Text('No pending recommendations.', style: TextStyle(color: LinguaTokens.inkMuted))
                else
                  ...recs.map((r) => AiReviewCard(
                        recommendationId: r['id'] ?? '',
                        lessonTitle: r['lesson_title'] ?? 'Lesson',
                        explanation: r['short_explanation'] ?? '',
                        humanStatus: r['human_status'] ?? 'none',
                        onAction: (newStatus) async {
                          final repo = ref.read(collaborationRepositoryProvider);
                          await repo.reviewAiRecommendation(r['id'] ?? '', humanStatus: newStatus);
                          ref.invalidate(specialistLearnerDetailProvider(widget.learnerId));
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.primary700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: LinguaTokens.inkMuted)),
      ],
    );
  }
}
