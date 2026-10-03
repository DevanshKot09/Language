import 'dart:async';

/// Callback signature when speech synthesis progress changes
typedef TtsProgressCallback = void Function(String text, int startOffset, int endOffset, String word);

/// State of TTS player
enum TtsPlaybackState {
  stopped,
  playing,
  paused,
}

/// Abstract interface for Text-To-Speech services.
/// Keeps presentation layer decoupled from platform plugins.
abstract class ITtsService {
  /// Speaks the given text string.
  Future<void> speak(String text);

  /// Pauses playback if supported by platform.
  Future<void> pause();

  /// Resumes playback if supported by platform.
  Future<void> resume();

  /// Stops playback immediately.
  Future<void> stop();

  /// Replays the last spoken text.
  Future<void> replay();

  /// Sets playback speech rate (0.5 to 1.5).
  Future<void> setSpeechRate(double rate);

  /// Sets volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Sets voice language locale (e.g. 'en-US').
  Future<void> setLanguage(String languageCode);

  /// Stream of current playback state.
  Stream<TtsPlaybackState> get stateStream;

  /// Current playback state.
  TtsPlaybackState get currentState;

  /// Stream of word highlighting progress if platform supports it.
  Stream<TtsProgressCallback?> get progressStream;

  /// Whether current engine supports word-level progress events.
  bool get supportsWordProgress;

  /// Release resources.
  void dispose();
}
