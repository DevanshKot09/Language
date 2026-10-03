import 'package:flutter/material.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';

class ReportCard extends StatelessWidget {
  final ReportItem report;
  final VoidCallback? onDownload;

  const ReportCard({
    super.key,
    required this.report,
    this.onDownload,
  });

  String _formatType(String type) {
    switch (type) {
      case 'parent_summary':
        return 'Family Practice Summary';
      case 'teacher_summary':
        return 'Classroom Learning Summary';
      case 'specialist_summary':
        return 'Specialist Support Review';
      default:
        return 'Learning Support Summary';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${report.createdAt.year}-${report.createdAt.month.toString().padLeft(2, '0')}-${report.createdAt.day.toString().padLeft(2, '0')}';

    return Semantics(
      label: 'Report: ${report.title} for ${report.learnerName}. Generated on $dateStr.',
      child: Card(
        margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          side: const BorderSide(color: LinguaTokens.borderSubtle),
        ),
        color: LinguaTokens.paper100,
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
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: LinguaTokens.primary100,
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                    ),
                    child: Text(
                      _formatType(report.reportType),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.primary900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space8),
              Text(
                'Learner: ${report.learnerName} • Created: $dateStr',
                style: const TextStyle(
                  fontSize: 12,
                  color: LinguaTokens.inkMuted,
                ),
              ),
              const SizedBox(height: LinguaTokens.space12),
              // Non-diagnostic notice banner
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space8),
                decoration: BoxDecoration(
                  color: LinguaTokens.warningLight,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                  border: Border.all(color: LinguaTokens.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: LinguaTokens.warning600),
                    SizedBox(width: LinguaTokens.space8),
                    Expanded(
                      child: Text(
                        'Educational learning summary. Not a clinical diagnosis or medical evaluation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: LinguaTokens.warning600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Download PDF Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LinguaTokens.primary700,
                    side: const BorderSide(color: LinguaTokens.primary600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
