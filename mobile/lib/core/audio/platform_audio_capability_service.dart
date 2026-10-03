import 'audio_capabilities.dart';
import 'i_tts_service.dart';
import 'i_stt_service.dart';
import 'i_audio_permission_service.dart';

/// Concrete capability detector evaluating audio, speech recognition, and microphone readiness.
class PlatformAudioCapabilityService implements IAudioCapabilityService {
  final ITtsService ttsService;
  final ISpeechToTextService sttService;
  final IAudioPermissionService permissionService;

  const PlatformAudioCapabilityService({
    required this.ttsService,
    required this.sttService,
    required this.permissionService,
  });

  @override
  Future<AudioCapabilities> detectCapabilities() async {
    bool ttsAvailable = true;
    bool sttAvailable = false;
    bool micAvailable = false;

    try {
      final permStatus = await permissionService.checkPermission();
      micAvailable = permStatus != MicrophonePermissionStatus.unsupported;
    } catch (_) {}

    try {
      sttAvailable = await sttService.initialize();
    } catch (_) {}

    SpeechProcessingMode mode = SpeechProcessingMode.platformManaged;
    if (!sttAvailable) {
      mode = SpeechProcessingMode.unavailable;
    } else if (sttService.isOnDeviceRecognition) {
      mode = SpeechProcessingMode.onDevice;
    }

    return AudioCapabilities(
      ttsSupported: ttsAvailable,
      sttSupported: sttAvailable,
      microphoneAvailable: micAvailable,
      processingMode: mode,
      supportsWordHighlighting: ttsService.supportsWordProgress,
      activeLocale: 'en-US',
    );
  }
}
