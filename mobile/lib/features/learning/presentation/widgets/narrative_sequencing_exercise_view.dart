import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';

class NarrativeSequencingExerciseView extends StatefulWidget {
  final ExerciseModel exercise;
  final List<String> currentOrder; // List of event IDs in arranged order
  final ValueChanged<List<String>> onOrderChanged;
  final bool isLocked;

  const NarrativeSequencingExerciseView({
    super.key,
    required this.exercise,
    required this.currentOrder,
    required this.onOrderChanged,
    this.isLocked = false,
  });

  @override
  State<NarrativeSequencingExerciseView> createState() => _NarrativeSequencingExerciseViewState();
}

class _NarrativeSequencingExerciseViewState extends State<NarrativeSequencingExerciseView> {
  late List<Map<String, String>> _orderedEvents;

  @override
  void initState() {
    super.initState();
    _initEvents();
  }

  @override
  void didUpdateWidget(covariant NarrativeSequencingExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _initEvents();
    }
  }

  void _initEvents() {
    final rawEvents = widget.exercise.narrativeEvents;
    if (widget.currentOrder.isNotEmpty) {
      final mapById = {for (var e in rawEvents) e['id']!: e};
      _orderedEvents = widget.currentOrder
          .map((id) => mapById[id])
          .whereType<Map<String, String>>()
          .toList();
      for (final ev in rawEvents) {
        if (!_orderedEvents.any((x) => x['id'] == ev['id'])) {
          _orderedEvents.add(ev);
        }
      }
    } else {
      _orderedEvents = List.from(rawEvents);
      widget.onOrderChanged(_orderedEvents.map((e) => e['id']!).toList());
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (widget.isLocked) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _orderedEvents.removeAt(oldIndex);
      _orderedEvents.insert(newIndex, item);
      widget.onOrderChanged(_orderedEvents.map((e) => e['id']!).toList());
    });
  }

  void _moveItem(int currentIndex, int targetIndex) {
    if (widget.isLocked) return;
    if (targetIndex < 0 || targetIndex >= _orderedEvents.length) return;
    setState(() {
      final item = _orderedEvents.removeAt(currentIndex);
      _orderedEvents.insert(targetIndex, item);
      widget.onOrderChanged(_orderedEvents.map((e) => e['id']!).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.reorder, size: 18, color: LinguaTokens.accent600),
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
        const SizedBox(height: 8),
        const Text(
          'Drag the handle (☰) or move steps into order from first to last:',
          style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
        ),
        const SizedBox(height: LinguaTokens.space16),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderedEvents.length,
          // ignore: deprecated_member_use
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final event = _orderedEvents[index];
            return Container(
              key: ValueKey(event['id']),
              margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
              padding: const EdgeInsets.all(LinguaTokens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                border: Border.all(color: LinguaTokens.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: LinguaTokens.primary100,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.primary700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      event['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: LinguaTokens.ink900,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!widget.isLocked) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      tooltip: 'Move step up',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: index > 0 ? () => _moveItem(index, index - 1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      tooltip: 'Move step down',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: index < _orderedEvents.length - 1 ? () => _moveItem(index, index + 1) : null,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_handle, color: LinguaTokens.inkMuted),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
