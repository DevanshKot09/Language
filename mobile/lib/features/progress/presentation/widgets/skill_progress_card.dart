import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/progress_models.dart';

class SkillProgressCard extends StatelessWidget {
  final SkillProgressItem skill;
  final VoidCallback? onTap;

  const SkillProgressCard({
    super.key,
    required this.skill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = skill.track == 'dld_track'
        ? LinguaTokens.dldTrack
        : LinguaTokens.dyslexiaTrack;

    final band = DescriptiveSkillBand.fromString(skill.currentBand);
    final (badgeColor, badgeBg) = _getBandColors(band);

    final progressVal = _getBandProgress(band, skill.accuracy);

    return Container(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      decoration: BoxDecoration(
        color: LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: LinguaTokens.ink900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            skill.domain.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LinguaTokens.inkMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        band.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${skill.attemptCount} activities • ${(skill.accuracy * 100).toInt()}% practice accuracy',
                      style: const TextStyle(
                        fontSize: 12,
                        color: LinguaTokens.ink700,
                      ),
                    ),
                    if (skill.lessonCompletedCount > 0)
                      Text(
                        '${skill.lessonCompletedCount} lessons done',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trackColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressVal,
                  backgroundColor: LinguaTokens.paper100,
                  color: trackColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _getBandColors(DescriptiveSkillBand band) {
    switch (band) {
      case DescriptiveSkillBand.consistent:
        return (LinguaTokens.success600, const Color(0xFFEDF7ED));
      case DescriptiveSkillBand.practicing:
        return (LinguaTokens.primary600, const Color(0xFFE8F1FC));
      case DescriptiveSkillBand.developing:
        return (LinguaTokens.accent600, const Color(0xFFFFF7E6));
      case DescriptiveSkillBand.starting:
        return (LinguaTokens.ink700, const Color(0xFFF1F3F5));
    }
  }

  double _getBandProgress(DescriptiveSkillBand band, double accuracy) {
    switch (band) {
      case DescriptiveSkillBand.consistent:
        return 1.0;
      case DescriptiveSkillBand.practicing:
        return 0.75;
      case DescriptiveSkillBand.developing:
        return accuracy > 0 ? (0.35 + accuracy * 0.3).clamp(0.35, 0.65) : 0.4;
      case DescriptiveSkillBand.starting:
        return 0.2;
    }
  }
}
