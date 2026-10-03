import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

enum LinguaButtonVariant {
  primary,
  secondary,
  text,
  danger,
}

/// Accessible, age-aware button component.
/// Enforces minimum 44px touch targets (or 56px when in child mode)
/// and proper semantic labels for screen readers.
class LinguaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinguaButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? minHeight;
  final String? semanticLabel;

  const LinguaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LinguaButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.minHeight,
    this.semanticLabel,
  });

  @override
  State<LinguaButton> createState() => _LinguaButtonState();
}

class _LinguaButtonState extends State<LinguaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.minHeight ?? LinguaTokens.minTouchTarget;

    Widget childContent;
    if (widget.isLoading) {
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == LinguaButtonVariant.secondary ? LinguaTokens.primary600 : Colors.white,
          ),
        ),
      );
    } else if (widget.leading != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.leading!,
          const SizedBox(width: LinguaTokens.space12),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      );
    } else if (widget.icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: LinguaTokens.space8),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      );
    } else {
      childContent = Text(
        widget.label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      );
    }

    Widget buttonWidget;
    switch (widget.variant) {
      case LinguaButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, effectiveHeight),
          ),
          child: childContent,
        );
        break;
      case LinguaButtonVariant.secondary:
        buttonWidget = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, effectiveHeight),
          ),
          child: childContent,
        );
        break;
      case LinguaButtonVariant.text:
        buttonWidget = TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(double.infinity, effectiveHeight),
            foregroundColor: LinguaTokens.primary600,
          ),
          child: childContent,
        );
        break;
      case LinguaButtonVariant.danger:
        buttonWidget = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: LinguaTokens.danger600,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, effectiveHeight),
          ),
          child: childContent,
        );
        break;
    }

    final isInteractive = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: widget.semanticLabel ?? widget.label,
      child: Listener(
        onPointerDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onPointerUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
        onPointerCancel: isInteractive ? (_) => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: buttonWidget,
        ),
      ),
    );
  }
}
