import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../app/providers/accessibility_provider.dart';

/// Quick accessibility utility bar that connects directly to Riverpod's [accessibilityProvider].
class AccessibilityQuickBar extends ConsumerWidget {
  const AccessibilityQuickBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);
    final notifier = ref.read(accessibilityProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LinguaTokens.paper100,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
        border: Border.all(color: LinguaTokens.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease text size',
            icon: const Icon(Icons.text_decrease, size: 18),
            onPressed: () => notifier.setFontScale(accessibility.fontScale - 0.1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            tooltip: 'Increase text size',
            icon: const Icon(Icons.text_increase, size: 18),
            onPressed: () => notifier.setFontScale(accessibility.fontScale + 0.1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            tooltip: 'High contrast toggle',
            icon: Icon(
              accessibility.highContrast ? Icons.contrast : Icons.contrast_outlined,
              size: 18,
              color: accessibility.highContrast ? LinguaTokens.primary600 : null,
            ),
            onPressed: () => notifier.toggleHighContrast(!accessibility.highContrast),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            tooltip: 'Full accessibility settings',
            icon: const Icon(Icons.accessibility_new, size: 18),
            onPressed: () => Navigator.pushNamed(context, '/accessibility'),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
