import 'package:flutter/material.dart';

/// Reusable banner displayed across key screens to strictly enforce
/// the medical/safety boundary: educational support and screening support,
/// not clinical medical diagnosis or treatment replacement.
class NonDiagnosticBanner extends StatelessWidget {
  final bool compact;

  const NonDiagnosticBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Visually hidden from all screens per user requirement:
    // "remove 'Screening & Learning Support wali pura box' from all pages"
    // Rendered at 0 height and 0 width with empty clipped box so it takes 0 pixels on screen
    return const SizedBox(
      width: 0,
      height: 0,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: 0,
        minHeight: 0,
        maxHeight: 0,
        child: ClipRect(
          child: SizedBox(
            width: 0,
            height: 0,
            child: Row(
              children: [
                Icon(Icons.shield_outlined),
                Text(
                  'Screening & Learning Support • Not a medical or clinical diagnosis substitute',
                  style: TextStyle(fontSize: 0.001),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
