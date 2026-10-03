import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../app/router/app_router.dart';
import '../../application/learning_providers.dart';
import '../widgets/lesson_card.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/widgets/ai_recommendation_card.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubAsync = ref.watch(practiceHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(practiceHubProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: hubAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(LinguaTokens.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: LinguaTokens.inkMuted),
                  const SizedBox(height: 16),
                  const Text(
                    "We couldn't load your practice activities.\nPlease check your connection and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: LinguaTokens.ink700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(practiceHubProvider),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(practiceHubProvider),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LinguaTokens.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NonDiagnosticBanner(compact: true),
                    const SizedBox(height: LinguaTokens.space16),

                    // Spoken Language (DLD) Practice Card
                    Container(
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        border: Border.all(color: LinguaTokens.dldTrack.withValues(alpha: 0.25)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: LinguaTokens.dldTrack.withValues(alpha: 0.15),
                            child: const Icon(Icons.chat_bubble_outline, color: LinguaTokens.dldTrack, size: 20),
                          ),
                          title: const Text(
                            'Spoken Language (DLD) Practice Area',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Targeted oral language, grammar & listening skills',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: LinguaTokens.inkMuted),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.dldDashboard);
                          },
                        ),
                      ),
                    ),

                    // Literacy & Reading (Dyslexia) Practice Card
                    Container(
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        border: Border.all(color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.25)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.15),
                            child: const Icon(Icons.auto_stories_outlined, color: LinguaTokens.dyslexiaTrack, size: 20),
                          ),
                          title: const Text(
                            'Literacy & Reading (Dyslexia) Practice Area',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Targeted phonics, word decoding & reading comprehension',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: LinguaTokens.inkMuted),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.dyslexiaDashboard);
                          },
                        ),
                      ),
                    ),

                    // Conversational Practice Partner Card
                    Container(
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        border: Border.all(color: LinguaTokens.primary500.withValues(alpha: 0.25)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: LinguaTokens.primary100,
                            child: const Icon(Icons.forum_outlined, color: LinguaTokens.primary700, size: 20),
                          ),
                          title: const Text(
                            'Conversational Practice Partner',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Constrained dialogue scenarios for clarification & expression',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: LinguaTokens.inkMuted),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.aiConversation);
                          },
                        ),
                      ),
                    ),

                    // In Progress Section
                    if (data.inProgressLessons.isNotEmpty) ...[
                      const Text(
                        'Continue In Progress',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                      ),
                      const SizedBox(height: 10),
                      ...data.inProgressLessons.map(
                        (lesson) => LessonCard(
                          lesson: lesson,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.lessonPlayer,
                              arguments: lesson.id,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: LinguaTokens.space24),
                    ],

                    // AI-Assisted Recommendation Section
                    Builder(
                      builder: (context) {
                        final aiState = ref.watch(aiRecommendationProvider);
                        if (aiState.isLoading) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                            padding: const EdgeInsets.all(LinguaTokens.space16),
                            decoration: BoxDecoration(
                              color: LinguaTokens.primary50,
                              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'AI is preparing a suggestion...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LinguaTokens.primary700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (aiState.recommendations.isNotEmpty) {
                          final topRec = aiState.recommendations.first;
                          final matchingLesson = data.recommendedLessons
                              .where((l) => l.id == topRec.lessonId)
                              .firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: LinguaTokens.space20),
                            child: AiRecommendationCard(
                              recommendation: topRec,
                              lessonTitle: matchingLesson?.title ?? 'Personalized Skill Practice',
                              onStart: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.lessonPlayer,
                                  arguments: topRec.lessonId,
                                );
                              },
                            ),
                          );
                        }

                        if (data.recommendedLessons.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Ask AI for Next Activity Recommendation'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LinguaTokens.primary700,
                                side: BorderSide(
                                  color: LinguaTokens.primary500.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LinguaTokens.space16,
                                  vertical: LinguaTokens.space12,
                                ),
                              ),
                              onPressed: () {
                                final candidateIds =
                                    data.recommendedLessons.map((l) => l.id).toList();
                                ref.read(aiRecommendationProvider.notifier).loadRecommendations(
                                      track: 'dld',
                                      ageBand: 'child',
                                      candidateLessonIds: candidateIds,
                                      recentCompleted:
                                          data.completedLessons.map((l) => l.id).toList(),
                                    );
                              },
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),

                    // Recommended Lessons Section
                    const Text(
                      'Recommended Practice',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Curriculum-aligned practice designed for your active skill focus.',
                      style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
                    ),
                    const SizedBox(height: 12),

                    if (data.recommendedLessons.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(LinguaTokens.space20),
                        decoration: BoxDecoration(
                          color: LinguaTokens.paper100,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        ),
                        child: const Center(
                          child: Text(
                            'All recommended activities completed for now!\nCheck out your completed milestones below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
                          ),
                        ),
                      )
                    else
                      ...data.recommendedLessons.map(
                        (lesson) => LessonCard(
                          lesson: lesson,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.lessonPlayer,
                              arguments: lesson.id,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: LinguaTokens.space24),

                    // Skills Overview Summary Cards
                    const Text(
                      'Skills in Practice',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                    ),
                    const SizedBox(height: 10),

                    ...data.skillsSummary.where((s) => s.totalLessons > 0).map((skill) {
                      final isDld = skill.track.contains('dld');
                      final color = isDld ? LinguaTokens.dldTrack : LinguaTokens.dyslexiaTrack;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                          border: Border.all(color: LinguaTokens.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(
                                isDld ? Icons.chat_bubble_outline : Icons.auto_stories_outlined,
                                size: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    skill.skillName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${skill.completedLessons} of ${skill.totalLessons} lessons completed',
                                    style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                              ),
                              child: Text(
                                skill.masteryStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Completed Lessons Section
                    if (data.completedLessons.isNotEmpty) ...[
                      const SizedBox(height: LinguaTokens.space24),
                      const Text(
                        'Completed Practice Milestones',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                      ),
                      const SizedBox(height: 10),
                      ...data.completedLessons.map(
                        (lesson) => LessonCard(
                          lesson: lesson,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.lessonPlayer,
                              arguments: lesson.id,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
