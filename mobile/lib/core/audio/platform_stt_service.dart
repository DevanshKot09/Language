import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'i_stt_service.dart';

/// Real platform implementation of ISpeechToTextService using speech_to_text package.
class PlatformSpeechToTextService implements ISpeechToTextService {
  final stt.SpeechToText _speech;
  final StreamController<SttState> _stateController = StreamController<SttState>.broadcast();
  final StreamController<double> _soundLevelController = StreamController<double>.broadcast();

  bool _isAvailable = false;
  SttState _currentState = SttState.notInitialized;
  bool _isOnDevice = false;

  PlatformSpeechToTextService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get isOnDeviceRecognition => _isOnDevice;

  @override
  Stream<SttState> get stateStream => _stateController.stream;

  @override
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  @override
  Future<bool> initialize() async {
    if (_isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );

      if (_isAvailable) {
        _currentState = SttState.ready;
        // On iOS and modern Android, speech_to_text can check on-device availability
        _isOnDevice = _speech.hasRecognized;
      } else {
        _currentState = SttState.notInitialized;
      }
      _stateController.add(_currentState);
      return _isAvailable;
    } catch (e) {
      debugPrint('[PlatformSpeechToTextService] initialize error: $e');
      _isAvailable = false;
      _currentState = SttState.error;
      _stateController.add(_currentState);
      return false;
    }
  }

  void _handleStatus(String status) {
    switch (status) {
      case 'listening':
        _currentState = SttState.listening;
        break;
      case 'notListening':
        if (_currentState == SttState.listening) {
          _currentState = SttState.processing;
        } else {
          _currentState = SttState.ready;
        }
        break;
      case 'done':
        _currentState = SttState.ready;
        break;
      default:
        break;
    }
    _stateController.add(_currentState);
  }

  void _handleError(SpeechRecognitionError errorNotification) {
    debugPrint('[PlatformSpeechToTextService] error: ${errorNotification.errorMsg}, permanent: ${errorNotification.permanent}');
    _currentState = SttState.error;
    _stateController.add(_currentState);
  }

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(SttError error) onError,
    String? localeId,
    Duration? pauseFor,
    Duration? listenFor,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        onError(const SttError(
          type: SttErrorType.serviceUnavailable,
          message: "Voice input isn't available right now. You can continue by typing.",
        ));
        return;
      }
    }

    try {
      _currentState = SttState.listening;
      _stateController.add(_currentState);

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _currentState = SttState.ready;
            _stateController.add(_currentState);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          onDevice: false,
        ),
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
      );
    } catch (e) {
      debugPrint('[PlatformSpeechToTextService] startListening error: $e');
      _currentState = SttState.error;
      _stateController.add(_currentState);
      onError(SttError(
        type: SttErrorType.unknown,
        message: "We couldn't turn that recording into text. Your recording was not used to judge your ability.",
      ));
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        _currentState = SttState.processing;
        _stateController.add(_currentState);
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[PlatformSpeechToTextService] stopListening error: $e');
    }
  }

  @override
  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
      _currentState = SttState.ready;
      _stateController.add(_currentState);
    } catch (e) {
      debugPrint('[PlatformSpeechToTextService] cancelListening error: $e');
    }
  }

  @override
  void dispose() {
    _stateController.close();
    _soundLevelController.close();
  }
}
