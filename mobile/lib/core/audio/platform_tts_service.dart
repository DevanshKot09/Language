import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'i_tts_service.dart';

/// Real platform implementation of ITtsService using flutter_tts.
class PlatformTtsService implements ITtsService {
  final FlutterTts _flutterTts;
  final StreamController<TtsPlaybackState> _stateController = StreamController<TtsPlaybackState>.broadcast();
  final StreamController<TtsProgressCallback?> _progressController = StreamController<TtsProgressCallback?>.broadcast();

  TtsPlaybackState _currentState = TtsPlaybackState.stopped;
  String _lastSpokenText = '';
  double _currentRate = 0.5; // FlutterTts normal speech rate is around 0.5
  double _currentVolume = 1.0;
  String _currentLanguage = 'en-US';
  bool _initialized = false;

  PlatformTtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts() {
    _initHandlers();
  }

  void _initHandlers() {
    _flutterTts.setStartHandler(() {
      _currentState = TtsPlaybackState.playing;
      _stateController.add(_currentState);
    });

    _flutterTts.setCompletionHandler(() {
      _currentState = TtsPlaybackState.stopped;
      _stateController.add(_currentState);
    });

    _flutterTts.setPauseHandler(() {
      _currentState = TtsPlaybackState.paused;
      _stateController.add(_currentState);
    });

    _flutterTts.setContinueHandler(() {
      _currentState = TtsPlaybackState.playing;
      _stateController.add(_currentState);
    });

    _flutterTts.setErrorHandler((dynamic msg) {
      debugPrint('[PlatformTtsService] TTS error: $msg');
      _currentState = TtsPlaybackState.stopped;
      _stateController.add(_currentState);
    });

    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      // Stream word progress callback
    });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_currentRate);
      await _flutterTts.setVolume(_currentVolume);
      await _flutterTts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('[PlatformTtsService] Error initializing TTS: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    _lastSpokenText = text;
    try {
      await _flutterTts.speak(text);
      _currentState = TtsPlaybackState.playing;
      _stateController.add(_currentState);
    } catch (e) {
      debugPrint('[PlatformTtsService] speak error: $e');
      _currentState = TtsPlaybackState.stopped;
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _currentState = TtsPlaybackState.paused;
      _stateController.add(_currentState);
    } catch (e) {
      debugPrint('[PlatformTtsService] pause error: $e');
    }
  }

  @override
  Future<void> resume() async {
    if (_currentState == TtsPlaybackState.paused) {
      try {
        await _flutterTts.speak(_lastSpokenText);
      } catch (e) {
        debugPrint('[PlatformTtsService] resume error: $e');
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _currentState = TtsPlaybackState.stopped;
      _stateController.add(_currentState);
    } catch (e) {
      debugPrint('[PlatformTtsService] stop error: $e');
    }
  }

  @override
  Future<void> replay() async {
    if (_lastSpokenText.isNotEmpty) {
      await stop();
      await speak(_lastSpokenText);
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Convert 0.5 - 1.5 multiplier to flutter_tts scale (approx 0.25 - 0.75, default ~0.5)
    _currentRate = (rate * 0.5).clamp(0.2, 0.9);
    try {
      await _flutterTts.setSpeechRate(_currentRate);
    } catch (e) {
      debugPrint('[PlatformTtsService] setSpeechRate error: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    try {
      await _flutterTts.setVolume(_currentVolume);
    } catch (e) {
      debugPrint('[PlatformTtsService] setVolume error: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      debugPrint('[PlatformTtsService] setLanguage error: $e');
    }
  }

  @override
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  @override
  TtsPlaybackState get currentState => _currentState;

  @override
  Stream<TtsProgressCallback?> get progressStream => _progressController.stream;

  @override
  bool get supportsWordProgress {
    // Word highlighting callback is supported on iOS and newer Android TTS engines, but not guaranteed uniformly
    return !kIsWeb;
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}
