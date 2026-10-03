import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// LINGUA AI Brand Identity Logo & Mark
/// Displays the official geometric speech-growth and AI intelligence glyph.
class LinguaBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const LinguaBrandLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/lingua_app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: LinguaTokens.primary600,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.record_voice_over_rounded,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.32),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LINGUA AI',
              style: TextStyle(
                fontSize: size * 0.52,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: textColor ?? LinguaTokens.ink900,
                height: 1.1,
              ),
            ),
            Text(
              'Speech & Literacy',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w500,
                color: (textColor ?? LinguaTokens.ink700).withValues(alpha: 0.75),
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
