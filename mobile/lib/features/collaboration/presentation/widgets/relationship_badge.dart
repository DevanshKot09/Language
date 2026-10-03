import 'package:flutter/material.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';

class RelationshipBadge extends StatelessWidget {
  final String status;

  const RelationshipBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        bg = LinguaTokens.successLight;
        fg = LinguaTokens.success600;
        label = 'Connected';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        bg = LinguaTokens.warningLight;
        fg = LinguaTokens.warning600;
        label = 'Pending';
        icon = Icons.hourglass_top_outlined;
        break;
      case 'revoked':
        bg = LinguaTokens.dangerLight;
        fg = LinguaTokens.danger600;
        label = 'Revoked';
        icon = Icons.block_outlined;
        break;
      case 'expired':
      default:
        bg = LinguaTokens.paper100;
        fg = LinguaTokens.inkMuted;
        label = 'Expired';
        icon = Icons.history_toggle_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space8, vertical: LinguaTokens.space4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: LinguaTokens.space4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
