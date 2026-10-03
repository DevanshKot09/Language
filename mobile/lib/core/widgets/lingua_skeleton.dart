import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// Clean, subtle shimmer skeleton loader for content-first loading states.
class LinguaSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const LinguaSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = LinguaTokens.radiusSmall,
  });

  const LinguaSkeleton.card({
    super.key,
    this.width,
    this.height = 100,
    this.borderRadius = LinguaTokens.radiusCard,
  });

  @override
  State<LinguaSkeleton> createState() => _LinguaSkeletonState();
}

class _LinguaSkeletonState extends State<LinguaSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: LinguaTokens.paper100.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: LinguaTokens.borderSubtle.withValues(alpha: 0.5)),
          ),
        );
      },
    );
  }
}
