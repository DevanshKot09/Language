import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../shared/models/skill_track.dart';
import '../../../../core/widgets/track_badge.dart';
import '../../domain/models/lesson_model.dart';

class LessonCard extends StatelessWidget {
  final LessonSummaryModel lesson;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.isCompleted;
    final isInProgress = lesson.isInProgress;

    final Color statusColor;
    final String statusLabel;

    if (isCompleted) {
      statusColor = LinguaTokens.success600;
      statusLabel = 'Completed';
    } else if (isInProgress) {
      statusColor = LinguaTokens.primary600;
      statusLabel = 'In Progress (${lesson.completedExercises}/${lesson.totalExercises})';
    } else {
      statusColor = LinguaTokens.inkMuted;
      statusLabel = '${lesson.estimatedEffortMinutes} min • ${lesson.totalExercises} activities';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(
          color: isInProgress ? LinguaTokens.primary500 : LinguaTokens.borderSubtle,
          width: isInProgress ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TrackBadge(track: SupportTrackExtension.fromApiId(lesson.track), compact: true),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LinguaTokens.successLight,
                          borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check, size: 14, color: LinguaTokens.success600),
                            SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: LinguaTokens.success600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LinguaTokens.ink700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isInProgress) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: lesson.progressFraction,
                      minHeight: 6,
                      backgroundColor: LinguaTokens.paper100,
                      valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.primary600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
