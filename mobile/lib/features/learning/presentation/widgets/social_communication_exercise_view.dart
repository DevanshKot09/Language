import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';

class SocialCommunicationExerciseView extends StatelessWidget {
  final ExerciseModel exercise;
  final String? selectedOption;
  final ValueChanged<String> onSelectOption;
  final bool isLocked;

  const SocialCommunicationExerciseView({
    super.key,
    required this.exercise,
    required this.selectedOption,
    required this.onSelectOption,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final scenarioText = exercise.scenario ?? exercise.prompt;
    final questionText = exercise.question ?? 'Which response is most appropriate in this scenario?';
    final options = exercise.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.dldTrack.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            border: Border.all(color: LinguaTokens.dldTrack.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 18, color: LinguaTokens.dldTrack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.dldTrack,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Context / Scenario Card
        Container(
          padding: const EdgeInsets.all(LinguaTokens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(color: LinguaTokens.borderSubtle),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.groups_outlined, size: 20, color: LinguaTokens.ink700),
                  SizedBox(width: 8),
                  Text(
                    'Real-World Scenario',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LinguaTokens.ink900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space8),
              Text(
                scenarioText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: LinguaTokens.ink900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space20),

        // Decision Prompt
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: LinguaTokens.ink900,
            height: 1.3,
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Interactive Choice Cards
        ...options.map((option) {
          final isSelected = selectedOption == option;
          return Container(
            margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
            decoration: BoxDecoration(
              color: isSelected ? LinguaTokens.primary50 : Colors.white,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(
                color: isSelected ? LinguaTokens.primary600 : LinguaTokens.borderSubtle,
                width: isSelected ? 2.0 : 1.0,
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
                onTap: isLocked ? null : () => onSelectOption(option),
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? LinguaTokens.primary600 : LinguaTokens.inkMuted,
                            width: 2,
                          ),
                          color: isSelected ? LinguaTokens.primary600 : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? LinguaTokens.primary900 : LinguaTokens.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
