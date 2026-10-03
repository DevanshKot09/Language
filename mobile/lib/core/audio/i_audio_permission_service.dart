/// Microphone permission status
enum MicrophonePermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unsupported,
}

/// Abstract interface for microphone and audio permission services.
abstract class IAudioPermissionService {
  /// Check current microphone permission status without triggering a system prompt.
  Future<MicrophonePermissionStatus> checkPermission();

  /// Explicitly request microphone permission from the operating system.
  /// Must be invoked only in response to a direct user action.
  Future<MicrophonePermissionStatus> requestPermission();

  /// Open device app settings so the user can grant permission if permanently denied.
  Future<bool> openAppSettings();
}
