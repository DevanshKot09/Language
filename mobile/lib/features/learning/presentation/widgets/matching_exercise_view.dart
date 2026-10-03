import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';

class MatchingExerciseView extends StatefulWidget {
  final ExerciseModel exercise;
  final Map<String, String> currentMatches;
  final ValueChanged<Map<String, String>> onMatchesChanged;
  final bool isLocked;

  const MatchingExerciseView({
    super.key,
    required this.exercise,
    required this.currentMatches,
    required this.onMatchesChanged,
    this.isLocked = false,
  });

  @override
  State<MatchingExerciseView> createState() => _MatchingExerciseViewState();
}

class _MatchingExerciseViewState extends State<MatchingExerciseView> {
  String? _selectedKey;

  void _onTapKey(String key) {
    if (widget.isLocked) return;
    setState(() {
      if (_selectedKey == key) {
        _selectedKey = null;
      } else {
        _selectedKey = key;
      }
    });
  }

  void _onTapValue(String value) {
    if (widget.isLocked || _selectedKey == null) return;
    final updated = Map<String, String>.from(widget.currentMatches);
    updated[_selectedKey!] = value;
    setState(() {
      _selectedKey = null;
    });
    widget.onMatchesChanged(updated);
  }

  void _removeMatch(String key) {
    if (widget.isLocked) return;
    final updated = Map<String, String>.from(widget.currentMatches)..remove(key);
    widget.onMatchesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.exercise.matchingPairs;
    final allKeys = pairs.map((p) => p['key']!).toList();
    final allValues = pairs.map((p) => p['value']!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.accent100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_alt, size: 18, color: LinguaTokens.accent600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.instruction,
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

        Text(
          widget.exercise.prompt,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LinguaTokens.ink900,
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Step 1: Select left item
        const Text(
          '1. Select an item from Column A:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allKeys.map((key) {
            final isMatched = widget.currentMatches.containsKey(key);
            final isCurrentSelection = _selectedKey == key;
            return ChoiceChip(
              label: Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentSelection ? Colors.white : LinguaTokens.ink900,
                ),
              ),
              selected: isCurrentSelection,
              selectedColor: LinguaTokens.primary600,
              backgroundColor: isMatched ? LinguaTokens.paper100 : Colors.white,
              avatar: isMatched ? const Icon(Icons.check, size: 16, color: LinguaTokens.success600) : null,
              onSelected: widget.isLocked ? null : (_) => _onTapKey(key),
            );
          }).toList(),
        ),

        const SizedBox(height: LinguaTokens.space16),

        // Step 2: Select right item
        Text(
          _selectedKey != null
              ? '2. Now tap the matching partner for "$_selectedKey":'
              : '2. Select the matching partner from Column B:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _selectedKey != null ? LinguaTokens.primary700 : LinguaTokens.ink700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allValues.map((val) {
            final isMatched = widget.currentMatches.containsValue(val);
            return ActionChip(
              label: Text(
                val,
                style: TextStyle(
                  color: isMatched ? LinguaTokens.inkMuted : LinguaTokens.ink900,
                ),
              ),
              backgroundColor: isMatched ? LinguaTokens.paper100 : Colors.white,
              side: BorderSide(
                color: _selectedKey != null && !isMatched
                    ? LinguaTokens.primary500
                    : LinguaTokens.borderSubtle,
              ),
              onPressed: widget.isLocked || _selectedKey == null || isMatched
                  ? null
                  : () => _onTapValue(val),
            );
          }).toList(),
        ),

        const SizedBox(height: LinguaTokens.space20),

        // Matched Pairs Summary
        if (widget.currentMatches.isNotEmpty) ...[
          const Text(
            'Your Connected Pairs:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: 8),
          ...widget.currentMatches.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: LinguaTokens.primary50,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                border: Border.all(color: LinguaTokens.primary100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: LinguaTokens.primary600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.key}  →  ${entry.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                  ),
                  if (!widget.isLocked)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: LinguaTokens.ink700),
                      tooltip: 'Remove connection',
                      onPressed: () => _removeMatch(entry.key),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
