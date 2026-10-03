import 'package:flutter/material.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentItem assignment;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return LinguaTokens.success600;
      case 'in_progress':
        return LinguaTokens.primary600;
      case 'overdue':
        return LinguaTokens.danger600;
      case 'assigned':
      default:
        return LinguaTokens.warning600;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return LinguaTokens.successLight;
      case 'in_progress':
        return LinguaTokens.primary100;
      case 'overdue':
        return LinguaTokens.dangerLight;
      case 'assigned':
      default:
        return LinguaTokens.warningLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Assignment: ${assignment.title} for ${assignment.studentName}. Status: ${assignment.status}.',
      button: onTap != null,
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
                      assignment.title,
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
                      color: _statusBg(assignment.status),
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                    ),
                    child: Text(
                      assignment.status.replaceFirst('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(assignment.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space8),
              Text(
                'Student: ${assignment.studentName} • Lesson: ${assignment.lessonTitle}',
                style: const TextStyle(
                  fontSize: 12,
                  color: LinguaTokens.ink700,
                ),
              ),
              if (assignment.instructions != null && assignment.instructions!.isNotEmpty) ...[
                const SizedBox(height: LinguaTokens.space4),
                Text(
                  assignment.instructions!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: LinguaTokens.inkMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
