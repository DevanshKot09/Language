import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/age_profile.dart';
import '../errors/app_exception.dart';

/// Abstract interface for client-side device preference storage.
///
/// PRIVACY & ARCHITECTURE BOUNDARY:
/// Only non-sensitive device configuration preferences may be stored here.
/// Clinical screening results, voice recordings, and sensitive child health data
/// MUST NEVER be stored in standard local device preferences.
abstract class IPreferencesStorage {
  Future<AgeBand> getAgeBand();
  Future<void> setAgeBand(AgeBand band);

  Future<double> getFontScale();
  Future<void> setFontScale(double scale);

  Future<bool> getHighContrast();
  Future<void> setHighContrast(bool enabled);

  Future<bool> getReducedMotion();
  Future<void> setReducedMotion(bool enabled);

  Future<bool> getUseDyslexicFont();
  Future<void> setUseDyslexicFont(bool enabled);

  Future<bool> getTtsAutoPlay();
  Future<void> setTtsAutoPlay(bool enabled);

  Future<double> getSpeechRate();
  Future<void> setSpeechRate(double rate);

  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);

  Future<void> clearPreferences();
}

/// SharedPreferences implementation of [IPreferencesStorage]
class SharedPreferencesStorage implements IPreferencesStorage {
  static const String _keyAgeBand = 'lingua_pref_age_band';
  static const String _keyFontScale = 'lingua_pref_font_scale';
  static const String _keyHighContrast = 'lingua_pref_high_contrast';
  static const String _keyReducedMotion = 'lingua_pref_reduced_motion';
  static const String _keyUseDyslexicFont = 'lingua_pref_dyslexic_font';
  static const String _keyTtsAutoPlay = 'lingua_pref_tts_autoplay';
  static const String _keySpeechRate = 'lingua_pref_speech_rate';
  static const String _keyOnboardingCompleted = 'lingua_pref_onboarding_completed';

  final SharedPreferences? _prefs;

  SharedPreferencesStorage([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _prefs;
    if (prefs != null) return prefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      throw StorageException('Failed to initialize SharedPreferences', e.toString());
    }
  }

  @override
  Future<AgeBand> getAgeBand() async {
    final prefs = await _getPrefs();
    final value = prefs.getString(_keyAgeBand);
    if (value != null) {
      for (final band in AgeBand.values) {
        if (band.name == value) return band;
      }
    }
    return AgeBand.teen; // Default fallback
  }

  @override
  Future<void> setAgeBand(AgeBand band) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAgeBand, band.name);
  }

  @override
  Future<double> getFontScale() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyFontScale) ?? 1.0;
  }

  @override
  Future<void> setFontScale(double scale) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyFontScale, scale);
  }

  @override
  Future<bool> getHighContrast() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyHighContrast) ?? false;
  }

  @override
  Future<void> setHighContrast(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyHighContrast, enabled);
  }

  @override
  Future<bool> getReducedMotion() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyReducedMotion) ?? false;
  }

  @override
  Future<void> setReducedMotion(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyReducedMotion, enabled);
  }

  @override
  Future<bool> getUseDyslexicFont() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyUseDyslexicFont) ?? false;
  }

  @override
  Future<void> setUseDyslexicFont(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyUseDyslexicFont, enabled);
  }

  @override
  Future<bool> getTtsAutoPlay() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyTtsAutoPlay) ?? false;
  }

  @override
  Future<void> setTtsAutoPlay(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyTtsAutoPlay, enabled);
  }

  @override
  Future<double> getSpeechRate() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keySpeechRate) ?? 1.0;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keySpeechRate, rate);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  @override
  Future<void> clearPreferences() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
