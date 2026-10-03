import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_selection_card.dart';
import '../../domain/models/exercise_model.dart';

class MultipleChoiceExerciseView extends StatelessWidget {
  final ExerciseModel exercise;
  final String? selectedOption;
  final ValueChanged<String> onSelectOption;
  final bool isLocked;

  const MultipleChoiceExerciseView({
    super.key,
    required this.exercise,
    required this.selectedOption,
    required this.onSelectOption,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = exercise.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.accent100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app_outlined, size: 18, color: LinguaTokens.accent600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.ink700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Prompt Card
        Container(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(color: LinguaTokens.borderSubtle),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            exercise.prompt,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LinguaTokens.ink900,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: LinguaTokens.space20),

        // Options List
        ...options.map((opt) {
          final isSelected = selectedOption == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
            child: LinguaSelectionCard(
              title: opt,
              isSelected: isSelected,
              onSelected: isLocked ? () {} : () => onSelectOption(opt),
            ),
          );
        }),
      ],
    );
  }
}
