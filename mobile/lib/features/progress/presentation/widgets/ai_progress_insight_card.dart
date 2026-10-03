import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';

class AiProgressInsightCard extends StatelessWidget {
  final String summary;
  final List<String>? details;
  final bool fallbackUsed;

  const AiProgressInsightCard({
    super.key,
    required this.summary,
    this.details,
    this.fallbackUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.primary600.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: LinguaTokens.primary600, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI-Assisted Practice Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.ink900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: LinguaTokens.borderSubtle),
                ),
                child: Text(
                  fallbackUsed ? 'PRACTICE STATS' : 'ASSISTIVE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.primary600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              color: LinguaTokens.ink900,
              height: 1.4,
            ),
          ),
          if (details != null && details!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details!.map((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: LinguaTokens.primary600, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Informational summary generated from your stored learning statistics. Non-diagnostic.',
            style: TextStyle(fontSize: 10, color: LinguaTokens.inkMuted),
          ),
        ],
      ),
    );
  }
}
