import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'i_audio_permission_service.dart';

/// Concrete implementation of IAudioPermissionService using AudioRecorder from record package.
class PlatformAudioPermissionService implements IAudioPermissionService {
  final AudioRecorder _audioRecorder;

  PlatformAudioPermissionService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  @override
  Future<MicrophonePermissionStatus> checkPermission() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        return MicrophonePermissionStatus.granted;
      }
      return MicrophonePermissionStatus.notDetermined;
    } catch (e) {
      debugPrint('[PlatformAudioPermissionService] checkPermission error: $e');
      return MicrophonePermissionStatus.unsupported;
    }
  }

  @override
  Future<MicrophonePermissionStatus> requestPermission() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      return hasPermission
          ? MicrophonePermissionStatus.granted
          : MicrophonePermissionStatus.denied;
    } catch (e) {
      debugPrint('[PlatformAudioPermissionService] requestPermission error: $e');
      return MicrophonePermissionStatus.unsupported;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    // Platform settings link can be opened via system channel or settings launcher
    return false;
  }
}
