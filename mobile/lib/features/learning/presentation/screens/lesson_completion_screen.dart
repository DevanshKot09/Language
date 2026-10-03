import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../core/widgets/track_badge.dart';
import '../../../../shared/models/skill_track.dart';
import '../../domain/models/lesson_model.dart';

class LessonCompletionScreen extends StatelessWidget {
  final LessonDetailModel lesson;
  final VoidCallback onContinue;

  const LessonCompletionScreen({
    super.key,
    required this.lesson,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
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
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: LinguaTokens.successLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: LinguaTokens.success600, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: LinguaTokens.success600,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              const Text(
                'Lesson Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Great effort practicing "${lesson.title}". Every practice session strengthens language and literacy.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: LinguaTokens.ink700,
                ),
              ),
              const SizedBox(height: LinguaTokens.space32),

              // Practice Summary Card (Strictly Non-Diagnostic)
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusHero),
                  border: Border.all(color: LinguaTokens.borderSubtle),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Practice Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                        ),
                        TrackBadge(track: SupportTrackExtension.fromApiId(lesson.track), compact: true),
                      ],
                    ),
                    const Divider(height: 24, color: LinguaTokens.borderSubtle),

                    _buildSummaryRow(
                      icon: Icons.school_outlined,
                      label: 'Skill Practiced',
                      value: lesson.skillName ?? 'Language & Literacy Skill',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      icon: Icons.checklist_rounded,
                      label: 'Activities Finished',
                      value: '${lesson.totalExercises} activities completed',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      icon: Icons.timer_outlined,
                      label: 'Practice Time',
                      value: '~${lesson.estimatedEffortMinutes} minutes focused',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              LinguaButton(
                label: 'Continue Learning',
                icon: Icons.arrow_forward,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: LinguaTokens.primary600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
          ],
        ),
      ],
    );
  }
}
