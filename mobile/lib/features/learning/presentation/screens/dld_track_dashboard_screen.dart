import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../app/router/app_router.dart';
import '../../application/learning_providers.dart';
import '../widgets/lesson_card.dart';

class DldTrackDashboardScreen extends ConsumerStatefulWidget {
  const DldTrackDashboardScreen({super.key});

  @override
  ConsumerState<DldTrackDashboardScreen> createState() => _DldTrackDashboardScreenState();
}

class _DldTrackDashboardScreenState extends ConsumerState<DldTrackDashboardScreen> {
  String _selectedAgeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final hubAsync = ref.watch(practiceHubProvider);
    final lessonsAsync = ref.watch(lessonsListProvider('dld_track'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spoken Language (DLD)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(practiceHubProvider);
              ref.invalidate(lessonsListProvider('dld_track'));
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
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              // Track Intro Hero Card
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusHero),
                  border: Border.all(color: LinguaTokens.dldTrack.withValues(alpha: 0.3)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: LinguaTokens.dldTrack.withValues(alpha: 0.15),
                          child: const Icon(Icons.chat_bubble_outline, color: LinguaTokens.dldTrack, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Spoken Language Learning Area',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: LinguaTokens.ink900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LinguaTokens.space12),
                    const Text(
                      'Targeted everyday language practice across vocabulary, morphosyntax, sentence construction, listening comprehension, and social communication.',
                      style: TextStyle(fontSize: 14, height: 1.45, color: LinguaTokens.ink700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // DLD Skill Practice Domains
              const Text(
                'DLD Practice Domains',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Skill development across key spoken language components',
                style: TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
              ),
              const SizedBox(height: LinguaTokens.space12),

              hubAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                )),
                error: (e, st) => const Text('Skill overview available upon connection.'),
                data: (hub) {
                  final dldSkills = hub.skillsSummary.where((s) => s.track.contains('dld')).toList();
                  if (dldSkills.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: dldSkills.map((skill) {
                      final progressFraction = skill.totalLessons > 0
                          ? skill.completedLessons / skill.totalLessons
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                          border: Border.all(color: LinguaTokens.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    skill.skillName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: LinguaTokens.dldTrack.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                                  ),
                                  child: Text(
                                    skill.masteryStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: LinguaTokens.dldTrack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressFraction,
                                minHeight: 6,
                                backgroundColor: LinguaTokens.paper100,
                                valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.dldTrack),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${skill.completedLessons} of ${skill.totalLessons} lessons completed',
                              style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Filterable DLD Lessons Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available DLD Lessons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                  ),
                  DropdownButton<String>(
                    value: _selectedAgeFilter,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LinguaTokens.ink700),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Ages')),
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'teen', child: Text('Teen')),
                      DropdownMenuItem(value: 'adult', child: Text('Adult')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedAgeFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // DLD Lesson Cards List
              lessonsAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                )),
                error: (e, st) => Center(
                  child: Text(
                    "Couldn't load DLD lessons. Please check connection.",
                    style: const TextStyle(color: LinguaTokens.ink700),
                  ),
                ),
                data: (lessons) {
                  final filtered = _selectedAgeFilter == 'all'
                      ? lessons
                      : lessons.where((l) => l.ageBand == _selectedAgeFilter || l.ageBand == 'all').toList();

                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: LinguaTokens.paper100,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                      ),
                      child: const Center(
                        child: Text(
                          'No lessons found for this age band.',
                          style: TextStyle(color: LinguaTokens.inkMuted),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filtered.map((lesson) {
                      return LessonCard(
                        lesson: lesson,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.lessonPlayer,
                            arguments: lesson.id,
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
