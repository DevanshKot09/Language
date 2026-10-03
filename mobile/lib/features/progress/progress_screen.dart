import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_card.dart';

/// UX-28 PROGRESS & SKILL TRENDS SCREEN
/// Multi-dimensional progress metrics avoiding medical gauges or deficit scoring.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Growth & Trends'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              const Text(
                'Your Practice Journey',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tracking skill mastery, consistency, and independence over time.',
                style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Overview Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Practice Time',
                      value: '42 mins',
                      subtitle: 'This week',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: LinguaTokens.space12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Independent Rate',
                      value: '84%',
                      subtitle: 'Without hints',
                      icon: Icons.verified_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Spoken Language (DLD) Skill Growth
              const Text(
                'Spoken Language Skills (DLD Track)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: LinguaTokens.space12),

              _buildSkillProgressRow('Vocabulary Breadth & Depth', 0.85, 'Proficient (85%)', LinguaTokens.dldTrack),
              _buildSkillProgressRow('Morphosyntax & Grammar', 0.72, 'Developing (72%)', LinguaTokens.dldTrack),
              _buildSkillProgressRow('Listening Comprehension', 0.90, 'Mastered (90%)', LinguaTokens.dldTrack),
              _buildSkillProgressRow('Oral Narrative Retell', 0.60, 'Practicing (60%)', LinguaTokens.dldTrack),

              const SizedBox(height: LinguaTokens.space24),

              // Literacy & Reading (Dyslexia) Skill Growth
              const Text(
                'Literacy & Reading Skills (Dyslexia Track)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: LinguaTokens.space12),

              _buildSkillProgressRow('Phonemic Blending & Segmentation', 0.92, 'Mastered (92%)', LinguaTokens.dyslexiaTrack),
              _buildSkillProgressRow('Word Decoding & Recognition', 0.75, 'Proficient (75%)', LinguaTokens.dyslexiaTrack),
              _buildSkillProgressRow('Reading Fluency & Pacing', 0.68, 'Developing (68%)', LinguaTokens.dyslexiaTrack),
              _buildSkillProgressRow('Spelling & Orthographic Patterns', 0.64, 'Practicing (64%)', LinguaTokens.dyslexiaTrack),

              const SizedBox(height: LinguaTokens.space24),

              LinguaButton(
                label: 'Share Summary with Parent or Specialist',
                variant: LinguaButtonVariant.secondary,
                icon: Icons.share_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress report export options opened.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return LinguaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LinguaTokens.primary600, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LinguaTokens.ink900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LinguaTokens.ink700)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: LinguaTokens.inkMuted)),
        ],
      ),
    );
  }

  Widget _buildSkillProgressRow(String skillName, double progress, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
        border: Border.all(color: LinguaTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skillName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LinguaTokens.ink900)),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: LinguaTokens.paper100,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
