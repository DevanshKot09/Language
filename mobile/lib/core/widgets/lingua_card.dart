import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// Reusable surface card with restrained elevation and clear borders.
class LinguaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  const LinguaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? LinguaTokens.borderSubtle,
      width: borderWidth ?? 1.0,
    );

    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: backgroundColor ?? LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
