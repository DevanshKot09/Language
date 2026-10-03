import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// A polished, modern card with subtle entrance animation, clean border,
/// restrained elevation, and accessible interactive feedback.
class LinguaAnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final int animationDelayMs;

  const LinguaAnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.animationDelayMs = 0,
  });

  @override
  State<LinguaAnimatedCard> createState() => _LinguaAnimatedCardState();
}

class _LinguaAnimatedCardState extends State<LinguaAnimatedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isHoveredOrPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animationDelayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.animationDelayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? LinguaTokens.radiusCard;
    final effectiveBorder = Border.all(
      color: widget.borderColor ?? LinguaTokens.borderSubtle,
      width: widget.borderWidth ?? 1.0,
    );

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: effectiveBorder,
        boxShadow: _isHoveredOrPressed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: widget.child,
    );

    Widget interactiveCard = cardContent;
    if (widget.onTap != null) {
      interactiveCard = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (mounted) setState(() => _isHoveredOrPressed = highlighted);
          },
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: cardContent,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: interactiveCard,
      ),
    );
  }
}
