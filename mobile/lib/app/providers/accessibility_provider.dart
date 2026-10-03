import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

/// Immutable accessibility state representation
class AccessibilityState {
  final double fontScale;
  final bool highContrast;
  final bool reducedMotion;
  final bool useDyslexicFont;
  final bool textToSpeechAutoPlay;
  final double speechRate;
  final bool highlightWordsWhileSpoken;

  const AccessibilityState({
    this.fontScale = 1.0,
    this.highContrast = false,
    this.reducedMotion = false,
    this.useDyslexicFont = false,
    this.textToSpeechAutoPlay = false,
    this.speechRate = 1.0,
    this.highlightWordsWhileSpoken = true,
  });

  String get fontFamily => useDyslexicFont ? 'OpenDyslexic' : 'Atkinson Hyperlegible';

  AccessibilityState copyWith({
    double? fontScale,
    bool? highContrast,
    bool? reducedMotion,
    bool? useDyslexicFont,
    bool? textToSpeechAutoPlay,
    double? speechRate,
    bool? highlightWordsWhileSpoken,
  }) {
    return AccessibilityState(
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      useDyslexicFont: useDyslexicFont ?? this.useDyslexicFont,
      textToSpeechAutoPlay: textToSpeechAutoPlay ?? this.textToSpeechAutoPlay,
      speechRate: speechRate ?? this.speechRate,
      highlightWordsWhileSpoken: highlightWordsWhileSpoken ?? this.highlightWordsWhileSpoken,
    );
  }
}

/// Riverpod 3 Notifier managing WCAG 2.2 AA accessibility preferences
class AccessibilityNotifier extends Notifier<AccessibilityState> {
  @override
  AccessibilityState build() {
    _loadFromStorage();
    return const AccessibilityState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(preferencesStorageProvider);
      final fontScale = await storage.getFontScale();
      final highContrast = await storage.getHighContrast();
      final reducedMotion = await storage.getReducedMotion();
      final useDyslexicFont = await storage.getUseDyslexicFont();
      final ttsAutoPlay = await storage.getTtsAutoPlay();
      final speechRate = await storage.getSpeechRate();

      state = state.copyWith(
        fontScale: fontScale,
        highContrast: highContrast,
        reducedMotion: reducedMotion,
        useDyslexicFont: useDyslexicFont,
        textToSpeechAutoPlay: ttsAutoPlay,
        speechRate: speechRate,
      );
    } catch (_) {}
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.75);
    state = state.copyWith(fontScale: clamped);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setFontScale(clamped);
  }

  Future<void> toggleHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setHighContrast(value);
  }

  Future<void> toggleReducedMotion(bool value) async {
    state = state.copyWith(reducedMotion: value);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setReducedMotion(value);
  }

  Future<void> toggleDyslexicFont(bool value) async {
    state = state.copyWith(useDyslexicFont: value);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setUseDyslexicFont(value);
  }

  Future<void> toggleTextToSpeechAutoPlay(bool value) async {
    state = state.copyWith(textToSpeechAutoPlay: value);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setTtsAutoPlay(value);
  }

  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.5, 1.5);
    state = state.copyWith(speechRate: clamped);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setSpeechRate(clamped);
  }

  Future<void> toggleHighlightWords(bool value) async {
    state = state.copyWith(highlightWordsWhileSpoken: value);
  }

  Future<void> resetToDefaults() async {
    state = const AccessibilityState();
    final storage = ref.read(preferencesStorageProvider);
    await storage.clearPreferences();
  }
}

/// Global provider for accessibility preferences
final accessibilityProvider = NotifierProvider<AccessibilityNotifier, AccessibilityState>(
  AccessibilityNotifier.new,
);
