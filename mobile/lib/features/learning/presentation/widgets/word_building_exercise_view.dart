import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';

class WordBuildingExerciseView extends StatefulWidget {
  final ExerciseModel exercise;
  final List<String> currentTiles;
  final ValueChanged<List<String>> onTilesChanged;
  final bool isLocked;

  const WordBuildingExerciseView({
    super.key,
    required this.exercise,
    required this.currentTiles,
    required this.onTilesChanged,
    this.isLocked = false,
  });

  @override
  State<WordBuildingExerciseView> createState() => _WordBuildingExerciseViewState();
}

class _WordBuildingExerciseViewState extends State<WordBuildingExerciseView> {
  late List<String> _assembledTiles;
  late List<String> _availablePool;

  @override
  void initState() {
    super.initState();
    _assembledTiles = List.from(widget.currentTiles);
    _initializePool();
  }

  void _initializePool() {
    final pool = List<String>.from(widget.exercise.tiles);
    // If tiles in content is empty, try splitting target word or prompt tokens
    if (pool.isEmpty) {
      final target = widget.exercise.targetWord ?? '';
      if (target.isNotEmpty) {
        pool.addAll(target.split(''));
        pool.shuffle();
      }
    }
    _availablePool = pool;
  }

  void _addTile(int poolIndex) {
    if (widget.isLocked || poolIndex < 0 || poolIndex >= _availablePool.length) return;
    final tile = _availablePool.removeAt(poolIndex);
    setState(() {
      _assembledTiles.add(tile);
    });
    widget.onTilesChanged(_assembledTiles);
  }

  void _removeTile(int assembledIndex) {
    if (widget.isLocked || assembledIndex < 0 || assembledIndex >= _assembledTiles.length) return;
    final tile = _assembledTiles.removeAt(assembledIndex);
    setState(() {
      _availablePool.add(tile);
    });
    widget.onTilesChanged(_assembledTiles);
  }

  void _moveTileLeft(int index) {
    if (widget.isLocked || index <= 0) return;
    setState(() {
      final item = _assembledTiles.removeAt(index);
      _assembledTiles.insert(index - 1, item);
    });
    widget.onTilesChanged(_assembledTiles);
  }

  void _moveTileRight(int index) {
    if (widget.isLocked || index >= _assembledTiles.length - 1) return;
    setState(() {
      final item = _assembledTiles.removeAt(index);
      _assembledTiles.insert(index + 1, item);
    });
    widget.onTilesChanged(_assembledTiles);
  }

  void _clearAll() {
    if (widget.isLocked) return;
    setState(() {
      _availablePool.addAll(_assembledTiles);
      _assembledTiles.clear();
    });
    widget.onTilesChanged(_assembledTiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.dyslexiaTrackBg,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            border: Border.all(color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spellcheck, size: 18, color: LinguaTokens.dyslexiaTrack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.dyslexiaTrack,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Prompt
        Text(
          widget.exercise.prompt,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LinguaTokens.ink900,
          ),
        ),
        const SizedBox(height: LinguaTokens.space20),

        // Constructed Word Stage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.4), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Constructed Word',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LinguaTokens.inkMuted),
                  ),
                  if (_assembledTiles.isNotEmpty && !widget.isLocked)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.restart_alt, size: 16, color: LinguaTokens.inkMuted),
                      label: const Text('Reset', style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted)),
                      onPressed: _clearAll,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_assembledTiles.isEmpty)
                Container(
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LinguaTokens.paper100,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    border: Border.all(color: LinguaTokens.borderSubtle, style: BorderStyle.solid),
                  ),
                  child: const Text(
                    'Tap letter tiles below to build the word',
                    style: TextStyle(color: LinguaTokens.inkMuted, fontSize: 14),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_assembledTiles.length, (index) {
                    final tile = _assembledTiles[index];
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: LinguaTokens.dyslexiaTrackBg,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                        border: Border.all(color: LinguaTokens.dyslexiaTrack),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tile,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: LinguaTokens.dyslexiaTrack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Accessible Reordering & Removal Controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0)
                                InkWell(
                                  onTap: () => _moveTileLeft(index),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.arrow_left, size: 18, color: LinguaTokens.ink700),
                                  ),
                                ),
                              InkWell(
                                onTap: () => _removeTile(index),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.close, size: 14, color: LinguaTokens.danger600)),
                              ),
                              if (index < _assembledTiles.length - 1)
                                InkWell(
                                  onTap: () => _moveTileRight(index),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.arrow_right, size: 18, color: LinguaTokens.ink700),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space24),

        // Available Tile Pool
        const Text(
          'Available Sound & Letter Tiles',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
        ),
        const SizedBox(height: 10),

        if (_availablePool.isEmpty)
          const Text('All tiles placed above.', style: TextStyle(color: LinguaTokens.inkMuted, fontSize: 13))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_availablePool.length, (index) {
              final tile = _availablePool[index];
              return InkWell(
                onTap: widget.isLocked ? null : () => _addTile(index),
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    border: Border.all(color: LinguaTokens.borderSubtle, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    tile,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: LinguaTokens.ink900,
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
