import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../app/providers/accessibility_provider.dart';

/// UX-32 ACCESSIBILITY SETTINGS SCREEN
/// Comprehensive WCAG 2.2 AA accessibility control center:
/// Text scaling, Atkinson Hyperlegible / OpenDyslexic font selection,
/// high contrast, TTS read-aloud options, and reduced motion.
class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessibilityProvider);
    final notifier = ref.read(accessibilityProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Center'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Text Preview Card
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                decoration: BoxDecoration(
                  color: state.highContrast ? Colors.white : LinguaTokens.paper100,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                  border: Border.all(
                    color: state.highContrast ? Colors.black : LinguaTokens.borderSubtle,
                    width: state.highContrast ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Readability Preview',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LinguaTokens.inkMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The quick brown fox jumps over the lazy dog. Notice how clear letterforms assist decoding and comprehension.',
                      style: TextStyle(
                        fontFamily: state.fontFamily,
                        fontSize: 16 * state.fontScale,
                        color: state.highContrast ? Colors.black : LinguaTokens.ink900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Section 1: Typography & Text Scaling
              _buildSectionTitle('Typography & Text Scaling'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Text Size', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${(state.fontScale * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: LinguaTokens.primary600),
                          ),
                        ],
                      ),
                      Slider(
                        value: state.fontScale,
                        min: 0.85,
                        max: 1.75,
                        divisions: 9,
                        label: '${(state.fontScale * 100).toInt()}%',
                        onChanged: (val) => notifier.setFontScale(val),
                      ),
                      SwitchListTile(
                        title: const Text('Use OpenDyslexic Font'),
                        subtitle: const Text('Weighted letter bottoms to prevent orientation confusion'),
                        value: state.useDyslexicFont,
                        onChanged: (val) => notifier.toggleDyslexicFont(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 2: Contrast & Visual Clarity
              _buildSectionTitle('Contrast & Visual Clarity'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('High Contrast Mode'),
                      subtitle: const Text('Pure high contrast borders, dark text, and sharp outlines'),
                      value: state.highContrast,
                      onChanged: (val) => notifier.toggleHighContrast(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Reduce Motion'),
                      subtitle: const Text('Disable decorative animations and particle effects'),
                      value: state.reducedMotion,
                      onChanged: (val) => notifier.toggleReducedMotion(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 3: Speech & Audio Assistance
              _buildSectionTitle('Speech & Audio Assistance'),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Speech Playback Rate (TTS)', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${state.speechRate.toStringAsFixed(1)}x',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: LinguaTokens.primary600),
                              ),
                            ],
                          ),
                          Slider(
                            value: state.speechRate,
                            min: 0.5,
                            max: 1.5,
                            divisions: 10,
                            label: '${state.speechRate.toStringAsFixed(1)}x',
                            onChanged: (val) => notifier.setSpeechRate(val),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Auto-Play Audio Instructions'),
                      subtitle: const Text('Read exercise prompts aloud automatically'),
                      value: state.textToSpeechAutoPlay,
                      onChanged: (val) => notifier.toggleTextToSpeechAutoPlay(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Highlight Words as Spoken'),
                      subtitle: const Text('Synchronize audio playback with visual word focus where supported'),
                      value: state.highlightWordsWhileSpoken,
                      onChanged: (val) => notifier.toggleHighlightWords(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              OutlinedButton(
                onPressed: () {
                  notifier.resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Accessibility preferences reset to default.')),
                  );
                },
                child: const Text('Reset All to Standard Defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: LinguaTokens.ink700,
        ),
      ),
    );
  }
}
