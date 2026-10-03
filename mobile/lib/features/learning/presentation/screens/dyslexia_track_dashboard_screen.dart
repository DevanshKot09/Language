import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../app/router/app_router.dart';
import '../../application/learning_providers.dart';
import '../widgets/lesson_card.dart';

class DyslexiaTrackDashboardScreen extends ConsumerStatefulWidget {
  const DyslexiaTrackDashboardScreen({super.key});

  @override
  ConsumerState<DyslexiaTrackDashboardScreen> createState() => _DyslexiaTrackDashboardScreenState();
}

class _DyslexiaTrackDashboardScreenState extends ConsumerState<DyslexiaTrackDashboardScreen> {
  String _selectedAgeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final hubAsync = ref.watch(practiceHubProvider);
    final lessonsAsync = ref.watch(lessonsListProvider('dyslexia_track'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Literacy & Reading (Dyslexia)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(practiceHubProvider);
              ref.invalidate(lessonsListProvider('dyslexia_track'));
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
                  border: Border.all(color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.3)),
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
                          backgroundColor: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.15),
                          child: const Icon(Icons.auto_stories_outlined, color: LinguaTokens.dyslexiaTrack, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Literacy & Reading Learning Area',
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
                      'Targeted reading science practice across phonological awareness, systematic phonics, word decoding, spelling patterns, and text comprehension.',
                      style: TextStyle(fontSize: 14, height: 1.45, color: LinguaTokens.ink700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Dyslexia Skill Practice Domains
              const Text(
                'Literacy Practice Domains',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Skill development across key written-language components',
                style: TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
              ),
              const SizedBox(height: LinguaTokens.space12),

              hubAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => const Text('Skill overview available upon connection.'),
                data: (hub) {
                  final dysSkills = hub.skillsSummary.where((s) => s.track.contains('dyslexia')).toList();
                  if (dysSkills.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: dysSkills.map((skill) {
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
                                    color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                                  ),
                                  child: Text(
                                    skill.masteryStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: LinguaTokens.dyslexiaTrack,
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
                                valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.dyslexiaTrack),
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

              // Filterable Dyslexia Lessons Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Literacy Lessons',
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

              // Dyslexia Lesson Cards List
              lessonsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Text(
                    "Couldn't load Literacy lessons. Please check connection.",
                    style: TextStyle(color: LinguaTokens.inkMuted),
                  ),
                ),
                data: (lessons) {
                  final filtered = _selectedAgeFilter == 'all'
                      ? lessons
                      : lessons.where((l) => l.ageBand == _selectedAgeFilter || l.ageBand == 'all').toList();

                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text(
                        'No lessons found for this age band.',
                        style: TextStyle(color: LinguaTokens.inkMuted),
                      ),
                    );
                  }

                  return Column(
                    children: filtered.map((lesson) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
                        child: LessonCard(
                          lesson: lesson,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.lessonPlayer,
                              arguments: lesson.id,
                            );
                          },
                        ),
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
