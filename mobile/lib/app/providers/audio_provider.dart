import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/i_tts_service.dart';
import '../../core/audio/i_stt_service.dart';
import '../../core/audio/i_audio_permission_service.dart';
import '../../core/audio/audio_capabilities.dart';
import '../../core/audio/platform_tts_service.dart';
import '../../core/audio/platform_stt_service.dart';
import '../../core/audio/platform_audio_permission_service.dart';
import '../../core/audio/platform_audio_capability_service.dart';
import 'accessibility_provider.dart';

/// Provider for ITtsService
final ttsServiceProvider = Provider<ITtsService>((ref) {
  final service = PlatformTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for ISpeechToTextService
final sttServiceProvider = Provider<ISpeechToTextService>((ref) {
  final service = PlatformSpeechToTextService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for IAudioPermissionService
final audioPermissionServiceProvider = Provider<IAudioPermissionService>((ref) {
  return PlatformAudioPermissionService();
});

/// Provider for IAudioCapabilityService
final audioCapabilityServiceProvider = Provider<IAudioCapabilityService>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  final stt = ref.watch(sttServiceProvider);
  final perm = ref.watch(audioPermissionServiceProvider);
  return PlatformAudioCapabilityService(
    ttsService: tts,
    sttService: stt,
    permissionService: perm,
  );
});

/// Async notifier for AudioCapabilities
final audioCapabilitiesProvider = FutureProvider<AudioCapabilities>((ref) async {
  final capabilityService = ref.watch(audioCapabilityServiceProvider);
  return await capabilityService.detectCapabilities();
});

/// TTS Controller State
class TtsState {
  final TtsPlaybackState playbackState;
  final String currentText;
  final double speechRate;
  final String? activeWord;
  final String? error;

  const TtsState({
    this.playbackState = TtsPlaybackState.stopped,
    this.currentText = '',
    this.speechRate = 1.0,
    this.activeWord,
    this.error,
  });

  bool get isPlaying => playbackState == TtsPlaybackState.playing;
  bool get isPaused => playbackState == TtsPlaybackState.paused;
  bool get isStopped => playbackState == TtsPlaybackState.stopped;

  TtsState copyWith({
    TtsPlaybackState? playbackState,
    String? currentText,
    double? speechRate,
    String? activeWord,
    String? error,
  }) {
    return TtsState(
      playbackState: playbackState ?? this.playbackState,
      currentText: currentText ?? this.currentText,
      speechRate: speechRate ?? this.speechRate,
      activeWord: activeWord,
      error: error,
    );
  }
}

/// TTS Controller Notifier
class TtsController extends Notifier<TtsState> {
  StreamSubscription<TtsPlaybackState>? _stateSub;

  @override
  TtsState build() {
    final ttsService = ref.watch(ttsServiceProvider);
    final accessibility = ref.watch(accessibilityProvider);

    _stateSub?.cancel();
    _stateSub = ttsService.stateStream.listen((playback) {
      state = state.copyWith(playbackState: playback);
    });

    ref.onDispose(() {
      _stateSub?.cancel();
    });

    ttsService.setSpeechRate(accessibility.speechRate);

    return TtsState(speechRate: accessibility.speechRate);
  }

  Future<void> speak(String text) async {
    final ttsService = ref.read(ttsServiceProvider);
    state = state.copyWith(currentText: text, error: null);
    await ttsService.speak(text);
  }

  Future<void> pause() async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.pause();
  }

  Future<void> resume() async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.resume();
  }

  Future<void> stop() async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.stop();
  }

  Future<void> replay() async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.replay();
  }

  Future<void> setRate(double rate) async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.setSpeechRate(rate);
    state = state.copyWith(speechRate: rate);
  }
}

final ttsControllerProvider = NotifierProvider<TtsController, TtsState>(
  TtsController.new,
);

/// Speech Interaction State Machine
enum SpeechInteractionStep {
  idle,
  permissionRequired,
  ready,
  listening,
  processing,
  review,
  error,
}

class SpeechInteractionUiState {
  final SpeechInteractionStep step;
  final String recognizedTranscript;
  final String editedTranscript;
  final double soundLevel;
  final String? errorMessage;
  final bool permissionGranted;

  const SpeechInteractionUiState({
    this.step = SpeechInteractionStep.idle,
    this.recognizedTranscript = '',
    this.editedTranscript = '',
    this.soundLevel = 0.0,
    this.errorMessage,
    this.permissionGranted = false,
  });

  SpeechInteractionUiState copyWith({
    SpeechInteractionStep? step,
    String? recognizedTranscript,
    String? editedTranscript,
    double? soundLevel,
    String? errorMessage,
    bool? permissionGranted,
  }) {
    return SpeechInteractionUiState(
      step: step ?? this.step,
      recognizedTranscript: recognizedTranscript ?? this.recognizedTranscript,
      editedTranscript: editedTranscript ?? this.editedTranscript,
      soundLevel: soundLevel ?? this.soundLevel,
      errorMessage: errorMessage,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

/// STT Controller Notifier
class SttController extends Notifier<SpeechInteractionUiState> {
  StreamSubscription<double>? _soundLevelSub;

  @override
  SpeechInteractionUiState build() {
    final sttService = ref.watch(sttServiceProvider);

    _soundLevelSub?.cancel();
    _soundLevelSub = sttService.soundLevelStream.listen((level) {
      if (state.step == SpeechInteractionStep.listening) {
        state = state.copyWith(soundLevel: level);
      }
    });

    ref.onDispose(() {
      _soundLevelSub?.cancel();
    });

    return const SpeechInteractionUiState();
  }

  Future<void> prepareVoiceInteraction() async {
    final permService = ref.read(audioPermissionServiceProvider);
    final status = await permService.checkPermission();

    if (status == MicrophonePermissionStatus.granted) {
      state = state.copyWith(
        step: SpeechInteractionStep.ready,
        permissionGranted: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        step: SpeechInteractionStep.permissionRequired,
        permissionGranted: false,
      );
    }
  }

  Future<void> requestMicrophoneAccess() async {
    final permService = ref.read(audioPermissionServiceProvider);
    final status = await permService.requestPermission();

    if (status == MicrophonePermissionStatus.granted) {
      state = state.copyWith(
        step: SpeechInteractionStep.ready,
        permissionGranted: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        step: SpeechInteractionStep.error,
        errorMessage: 'Microphone access is off. You can enable it in device settings, or type your answer instead.',
        permissionGranted: false,
      );
    }
  }

  Future<void> startListening() async {
    final sttService = ref.read(sttServiceProvider);

    state = state.copyWith(
      step: SpeechInteractionStep.listening,
      errorMessage: null,
    );

    await sttService.startListening(
      onResult: (transcript, isFinal) {
        state = state.copyWith(
          recognizedTranscript: transcript,
          editedTranscript: transcript,
          step: isFinal ? SpeechInteractionStep.review : SpeechInteractionStep.listening,
        );
      },
      onError: (error) {
        state = state.copyWith(
          step: SpeechInteractionStep.error,
          errorMessage: error.message,
        );
      },
    );
  }

  Future<void> stopListening() async {
    final sttService = ref.read(sttServiceProvider);
    state = state.copyWith(step: SpeechInteractionStep.processing);
    await sttService.stopListening();
  }

  Future<void> cancelListening() async {
    final sttService = ref.read(sttServiceProvider);
    await sttService.cancelListening();
    state = state.copyWith(
      step: SpeechInteractionStep.ready,
      recognizedTranscript: '',
      editedTranscript: '',
    );
  }

  void updateEditedTranscript(String newText) {
    state = state.copyWith(editedTranscript: newText);
  }

  void reset() {
    state = const SpeechInteractionUiState();
  }
}

final sttControllerProvider = NotifierProvider<SttController, SpeechInteractionUiState>(
  SttController.new,
);
