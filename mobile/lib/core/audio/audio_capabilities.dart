import 'dart:async';

/// Speech processing architecture modes
enum SpeechProcessingMode {
  onDevice,
  platformManaged,
  cloud,
  unavailable,
}

/// Runtime capability snapshot for speech and audio features
class AudioCapabilities {
  final bool ttsSupported;
  final bool sttSupported;
  final bool microphoneAvailable;
  final SpeechProcessingMode processingMode;
  final bool supportsWordHighlighting;
  final String activeLocale;

  const AudioCapabilities({
    required this.ttsSupported,
    required this.sttSupported,
    required this.microphoneAvailable,
    required this.processingMode,
    required this.supportsWordHighlighting,
    required this.activeLocale,
  });

  AudioCapabilities copyWith({
    bool? ttsSupported,
    bool? sttSupported,
    bool? microphoneAvailable,
    SpeechProcessingMode? processingMode,
    bool? supportsWordHighlighting,
    String? activeLocale,
  }) {
    return AudioCapabilities(
      ttsSupported: ttsSupported ?? this.ttsSupported,
      sttSupported: sttSupported ?? this.sttSupported,
      microphoneAvailable: microphoneAvailable ?? this.microphoneAvailable,
      processingMode: processingMode ?? this.processingMode,
      supportsWordHighlighting: supportsWordHighlighting ?? this.supportsWordHighlighting,
      activeLocale: activeLocale ?? this.activeLocale,
    );
  }
}

/// Abstract capability service to detect device audio/speech support at runtime.
abstract class IAudioCapabilityService {
  Future<AudioCapabilities> detectCapabilities();
}
