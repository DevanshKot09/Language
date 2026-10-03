import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/core/audio/i_tts_service.dart';
import 'package:lingua_ai/core/audio/i_stt_service.dart';
import 'package:lingua_ai/core/audio/i_audio_permission_service.dart';
import 'package:lingua_ai/core/audio/audio_capabilities.dart';
import 'package:lingua_ai/core/audio/platform_audio_capability_service.dart';
import 'package:lingua_ai/app/providers/audio_provider.dart';

/// Test Mock for ITtsService
class MockTtsService implements ITtsService {
  final StreamController<TtsPlaybackState> _stateController = StreamController<TtsPlaybackState>.broadcast();
  final StreamController<TtsProgressCallback?> _progressController = StreamController<TtsProgressCallback?>.broadcast();

  TtsPlaybackState _currentState = TtsPlaybackState.stopped;
  String lastSpoken = '';
  double currentRate = 1.0;
  double currentVolume = 1.0;
  String currentLanguage = 'en-US';

  @override
  TtsPlaybackState get currentState => _currentState;

  @override
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<TtsProgressCallback?> get progressStream => _progressController.stream;

  @override
  bool get supportsWordProgress => true;

  @override
  Future<void> speak(String text) async {
    lastSpoken = text;
    _currentState = TtsPlaybackState.playing;
    _stateController.add(_currentState);
  }

  @override
  Future<void> pause() async {
    _currentState = TtsPlaybackState.paused;
    _stateController.add(_currentState);
  }

  @override
  Future<void> resume() async {
    _currentState = TtsPlaybackState.playing;
    _stateController.add(_currentState);
  }

  @override
  Future<void> stop() async {
    _currentState = TtsPlaybackState.stopped;
    _stateController.add(_currentState);
  }

  @override
  Future<void> replay() async {
    if (lastSpoken.isNotEmpty) {
      await speak(lastSpoken);
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    currentRate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    currentLanguage = languageCode;
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}

/// Test Mock for ISpeechToTextService
class MockSttService implements ISpeechToTextService {
  final StreamController<SttState> _stateController = StreamController<SttState>.broadcast();
  final StreamController<double> _soundController = StreamController<double>.broadcast();

  bool available = true;
  bool listening = false;
  bool onDevice = true;

  void Function(String transcript, bool isFinal)? resultCallback;
  void Function(SttError error)? errorCallback;

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

  @override
  bool get isOnDeviceRecognition => onDevice;

  @override
  Stream<SttState> get stateStream => _stateController.stream;

  @override
  Stream<double> get soundLevelStream => _soundController.stream;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(SttError error) onError,
    String? localeId,
    Duration? pauseFor,
    Duration? listenFor,
  }) async {
    listening = true;
    resultCallback = onResult;
    errorCallback = onError;
    _stateController.add(SttState.listening);
  }

  @override
  Future<void> stopListening() async {
    listening = false;
    _stateController.add(SttState.processing);
  }

  @override
  Future<void> cancelListening() async {
    listening = false;
    _stateController.add(SttState.ready);
  }

  void emitTranscript(String transcript, bool isFinal) {
    resultCallback?.call(transcript, isFinal);
    if (isFinal) {
      listening = false;
      _stateController.add(SttState.ready);
    }
  }

  void emitError(SttError error) {
    listening = false;
    _stateController.add(SttState.error);
    errorCallback?.call(error);
  }

  @override
  void dispose() {
    _stateController.close();
    _soundController.close();
  }
}

/// Test Mock for IAudioPermissionService
class MockAudioPermissionService implements IAudioPermissionService {
  MicrophonePermissionStatus currentStatus = MicrophonePermissionStatus.notDetermined;

  @override
  Future<MicrophonePermissionStatus> checkPermission() async => currentStatus;

  @override
  Future<MicrophonePermissionStatus> requestPermission() async {
    currentStatus = MicrophonePermissionStatus.granted;
    return currentStatus;
  }

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  group('Phase 8 Audio & Speech Architecture Unit Tests', () {
    late MockTtsService mockTts;
    late MockSttService mockStt;
    late MockAudioPermissionService mockPerm;

    setUp(() {
      mockTts = MockTtsService();
      mockStt = MockSttService();
      mockPerm = MockAudioPermissionService();
    });

    tearDown(() {
      mockTts.dispose();
      mockStt.dispose();
    });

    test('Capability service detects on-device speech and TTS support cleanly', () async {
      final capabilityService = PlatformAudioCapabilityService(
        ttsService: mockTts,
        sttService: mockStt,
        permissionService: mockPerm,
      );

      final caps = await capabilityService.detectCapabilities();
      expect(caps.ttsSupported, isTrue);
      expect(caps.sttSupported, isTrue);
      expect(caps.processingMode, equals(SpeechProcessingMode.onDevice));
      expect(caps.activeLocale, equals('en-US'));
      expect(caps.supportsWordHighlighting, isTrue);
    });

    test('TTS Controller manages speak, pause, resume, replay lifecycle', () async {
      final container = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTts),
        ],
      );

      final notifier = container.read(ttsControllerProvider.notifier);

      await notifier.speak('Hello world');
      expect(mockTts.lastSpoken, equals('Hello world'));
      expect(container.read(ttsControllerProvider).isPlaying, isTrue);

      await notifier.pause();
      expect(container.read(ttsControllerProvider).isPaused, isTrue);

      await notifier.resume();
      expect(container.read(ttsControllerProvider).isPlaying, isTrue);

      await notifier.stop();
      expect(container.read(ttsControllerProvider).isStopped, isTrue);

      container.dispose();
    });

    test('STT Controller state machine transitions: ready -> listening -> review', () async {
      final container = ProviderContainer(
        overrides: [
          sttServiceProvider.overrideWithValue(mockStt),
          audioPermissionServiceProvider.overrideWithValue(mockPerm),
        ],
      );

      final notifier = container.read(sttControllerProvider.notifier);

      // 1. Initial prepare
      await notifier.prepareVoiceInteraction();
      expect(container.read(sttControllerProvider).step, equals(SpeechInteractionStep.permissionRequired));

      // 2. Grant permission
      await notifier.requestMicrophoneAccess();
      expect(container.read(sttControllerProvider).step, equals(SpeechInteractionStep.ready));
      expect(container.read(sttControllerProvider).permissionGranted, isTrue);

      // 3. Start listening
      await notifier.startListening();
      expect(container.read(sttControllerProvider).step, equals(SpeechInteractionStep.listening));
      expect(mockStt.listening, isTrue);

      // 4. Emit final transcript
      mockStt.emitTranscript('I finished the story', true);
      final finalState = container.read(sttControllerProvider);
      expect(finalState.step, equals(SpeechInteractionStep.review));
      expect(finalState.recognizedTranscript, equals('I finished the story'));
      expect(finalState.editedTranscript, equals('I finished the story'));

      // 5. Edit transcript
      notifier.updateEditedTranscript('I finished the story carefully');
      expect(container.read(sttControllerProvider).editedTranscript, equals('I finished the story carefully'));

      container.dispose();
    });

    test('STT Controller handles non-shaming error message when speech detection fails', () async {
      final container = ProviderContainer(
        overrides: [
          sttServiceProvider.overrideWithValue(mockStt),
          audioPermissionServiceProvider.overrideWithValue(mockPerm),
        ],
      );

      final notifier = container.read(sttControllerProvider.notifier);
      await notifier.startListening();

      mockStt.emitError(const SttError(
        type: SttErrorType.noSpeechDetected,
        message: "We didn't hear anything. Try again or type your answer.",
      ));

      final state = container.read(sttControllerProvider);
      expect(state.step, equals(SpeechInteractionStep.error));
      expect(state.errorMessage, contains("We didn't hear anything"));

      container.dispose();
    });
  });
}
