import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/skill_track.dart';

/// Accessible badge distinguishing DLD vs. Dyslexia support tracks.
class TrackBadge extends StatelessWidget {
  final SupportTrack track;
  final bool compact;

  const TrackBadge({
    super.key,
    required this.track,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? LinguaTokens.space8 : LinguaTokens.space12,
        vertical: compact ? 2 : LinguaTokens.space4,
      ),
      decoration: BoxDecoration(
        color: track.backgroundColor,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
        border: Border.all(color: track.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: track.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? track.shortLabel : track.title,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: LinguaTokens.ink900,
            ),
          ),
        ],
      ),
    );
  }
}
