import 'package:flutter/material.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/relationship_badge.dart';

class LearnerCardTile extends StatelessWidget {
  final String displayName;
  final String ageBand;
  final String supportFocus;
  final String status;
  final String? subtitle;
  final VoidCallback? onTap;

  const LearnerCardTile({
    super.key,
    required this.displayName,
    required this.ageBand,
    required this.supportFocus,
    required this.status,
    this.subtitle,
    this.onTap,
  });

  String _formatTrack(String track) {
    if (track.contains('dld')) return 'Spoken Language (DLD)';
    if (track.contains('dyslexia')) return 'Literacy & Reading';
    return 'Comprehensive Support';
  }

  Color _trackColor(String track) {
    if (track.contains('dld')) return LinguaTokens.dldTrack;
    if (track.contains('dyslexia')) return LinguaTokens.dyslexiaTrack;
    return LinguaTokens.primary600;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$displayName, ${ageBand.toUpperCase()} learner on ${_formatTrack(supportFocus)}. Status: $status',
      button: onTap != null,
      child: Card(
        margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          side: const BorderSide(color: LinguaTokens.borderSubtle),
        ),
        color: LinguaTokens.paper100,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LinguaTokens.ink900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RelationshipBadge(status: status),
                  ],
                ),
                const SizedBox(height: LinguaTokens.space8),
                Row(
                  children: [
                    // Age band chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LinguaTokens.paper50,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                      ),
                      child: Text(
                        ageBand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: LinguaTokens.ink700,
                        ),
                      ),
                    ),
                    const SizedBox(width: LinguaTokens.space8),
                    // Track chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _trackColor(supportFocus).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                      ),
                      child: Text(
                        _formatTrack(supportFocus),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _trackColor(supportFocus),
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: LinguaTokens.space8),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LinguaTokens.inkMuted,
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
