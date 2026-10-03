import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// Interactive selection card with visible focus/active outline,
/// icon container, title, subtitle, and check/radio indicator.
class LinguaSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? activeColor;
  final Color? activeBackgroundColor;

  const LinguaSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.icon,
    required this.isSelected,
    required this.onSelected,
    this.activeColor,
    this.activeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? LinguaTokens.primary600;
    final effectiveBg = activeBackgroundColor ?? LinguaTokens.primary50;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title, ${subtitle ?? ""}',
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
          padding: const EdgeInsets.all(LinguaTokens.space16),
          decoration: BoxDecoration(
            color: isSelected ? effectiveBg : LinguaTokens.surfaceCard,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(
              color: isSelected ? effectiveColor : LinguaTokens.borderSubtle,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : LinguaTokens.paper100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? effectiveColor : LinguaTokens.ink700, size: 22),
                ),
                const SizedBox(width: LinguaTokens.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? LinguaTokens.primary900 : LinguaTokens.ink900,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: effectiveColor, size: 22)
                        else
                          Icon(Icons.radio_button_unchecked, color: LinguaTokens.inkMuted, size: 22),
                      ],
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? effectiveColor : LinguaTokens.inkMuted,
                        ),
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
