import 'dart:async';

/// Speech-to-text recognition state
enum SttState {
  notInitialized,
  ready,
  listening,
  processing,
  error,
}

/// Recognition error types with safe, non-judgmental descriptions
enum SttErrorType {
  permissionDenied,
  serviceUnavailable,
  noSpeechDetected,
  networkError,
  unsupportedPlatform,
  unknown,
}

class SttError {
  final SttErrorType type;
  final String message;
  final bool permanent;

  const SttError({
    required this.type,
    required this.message,
    this.permanent = false,
  });
}

/// Abstract interface for Speech-to-Text services.
abstract class ISpeechToTextService {
  /// Initializes the speech recognizer and checks platform availability.
  Future<bool> initialize();

  /// Whether speech recognition is available on this device/platform.
  bool get isAvailable;

  /// Whether the microphone is currently active and listening.
  bool get isListening;

  /// Starts listening for a short spoken utterance.
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(SttError error) onError,
    String? localeId,
    Duration? pauseFor,
    Duration? listenFor,
  });

  /// Stops listening and triggers final processing of captured speech.
  Future<void> stopListening();

  /// Cancels listening and discards temporary audio.
  Future<void> cancelListening();

  /// Stream of STT status state changes.
  Stream<SttState> get stateStream;

  /// Stream of sound level changes (for accessible audio visualizers).
  Stream<double> get soundLevelStream;

  /// Whether speech processing is verified to run on-device.
  bool get isOnDeviceRecognition;

  /// Releases resources.
  void dispose();
}
