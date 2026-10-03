import 'package:flutter/material.dart';

/// Manages runtime accessibility overrides adhering to WCAG 2.2 AA.
/// Allows the learner, educator, or specialist to adjust visual and auditory
/// presentation independently of device-level settings.
class AccessibilityManager extends ChangeNotifier {
  double _fontScale = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _textToSpeechAutoPlay = false;
  double _speechRate = 1.0;
  bool _highlightWordsWhileSpoken = true;
  final String _fontFamily = 'Atkinson Hyperlegible';
  bool _useDyslexicFont = false;

  double get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  bool get textToSpeechAutoPlay => _textToSpeechAutoPlay;
  double get speechRate => _speechRate;
  bool get highlightWordsWhileSpoken => _highlightWordsWhileSpoken;
  String get fontFamily => _useDyslexicFont ? 'OpenDyslexic' : _fontFamily;
  bool get useDyslexicFont => _useDyslexicFont;

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.85, 1.75);
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  void toggleReducedMotion(bool value) {
    _reducedMotion = value;
    notifyListeners();
  }

  void toggleTextToSpeechAutoPlay(bool value) {
    _textToSpeechAutoPlay = value;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    notifyListeners();
  }

  void toggleHighlightWords(bool value) {
    _highlightWordsWhileSpoken = value;
    notifyListeners();
  }

  void toggleDyslexicFont(bool value) {
    _useDyslexicFont = value;
    notifyListeners();
  }

  void resetToDefaults() {
    _fontScale = 1.0;
    _highContrast = false;
    _reducedMotion = false;
    _textToSpeechAutoPlay = false;
    _speechRate = 1.0;
    _highlightWordsWhileSpoken = true;
    _useDyslexicFont = false;
    notifyListeners();
  }
}
