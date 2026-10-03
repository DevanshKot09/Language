import 'package:flutter/material.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';

/// AI Recommendation Review Card for Specialist Human Oversight
/// Explicitly distinguishes:
/// AI suggestion -> Human review -> Decision -> Status
class AiReviewCard extends StatelessWidget {
  final String recommendationId;
  final String lessonTitle;
  final String explanation;
  final String humanStatus; // none, approved, modified, rejected
  final Function(String status)? onAction;

  const AiReviewCard({
    super.key,
    required this.recommendationId,
    required this.lessonTitle,
    required this.explanation,
    required this.humanStatus,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = humanStatus == 'approved';
    final isRejected = humanStatus == 'rejected';
    final isModified = humanStatus == 'modified';

    final statusBg = isApproved
        ? LinguaTokens.successLight
        : isRejected
            ? LinguaTokens.dangerLight
            : isModified
                ? LinguaTokens.primary100
                : LinguaTokens.warningLight;

    final statusColor = isApproved
        ? LinguaTokens.success600
        : isRejected
            ? LinguaTokens.danger600
            : isModified
                ? LinguaTokens.primary700
                : LinguaTokens.warning600;

    final statusLabel = isApproved
        ? 'APPROVED'
        : isRejected
            ? 'REJECTED'
            : isModified
                ? 'MODIFIED'
                : 'PENDING REVIEW';

    return Container(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: LinguaTokens.ink900.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: LinguaTokens.accent100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 14, color: LinguaTokens.accent600),
                    ),
                    const SizedBox(width: LinguaTokens.space8),
                    const Text(
                      'AI Practice Suggestion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LinguaTokens.primary700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LinguaTokens.space12),
            Text(
              lessonTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: LinguaTokens.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: LinguaTokens.ink700,
              ),
            ),
            const SizedBox(height: LinguaTokens.space16),

            // Human Decision Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAction != null ? () => onAction!('approved') : null,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      foregroundColor: LinguaTokens.success600,
                      side: BorderSide(
                        color: isApproved ? LinguaTokens.success600 : LinguaTokens.borderSubtle,
                        width: isApproved ? 1.8 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: LinguaTokens.space8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAction != null ? () => onAction!('modified') : null,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      foregroundColor: LinguaTokens.primary700,
                      side: BorderSide(
                        color: isModified ? LinguaTokens.primary600 : LinguaTokens.borderSubtle,
                        width: isModified ? 1.8 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Modify', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: LinguaTokens.space8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAction != null ? () => onAction!('rejected') : null,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      foregroundColor: LinguaTokens.danger600,
                      side: BorderSide(
                        color: isRejected ? LinguaTokens.danger600 : LinguaTokens.borderSubtle,
                        width: isRejected ? 1.8 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
