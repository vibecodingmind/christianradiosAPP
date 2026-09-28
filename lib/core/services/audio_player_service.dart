import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';

// Global provider for the audio handler
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError('Must be initialized in main');
});

final currentStationProvider = StateProvider<Station?>((ref) => null);

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

final isPlayingProvider = Provider<bool>((ref) {
  final state = ref.watch(playbackStateProvider).value;
  return state?.playing ?? false;
});

final isLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(playbackStateProvider).value;
  if (state == null) return false;
  return state.processingState == AudioProcessingState.loading ||
      state.processingState == AudioProcessingState.buffering;
});

final volumeStreamProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.volumeStream;
});

final volumeLevelProvider = Provider<double>((ref) {
  final asyncVal = ref.watch(volumeStreamProvider);
  return asyncVal.value ?? ref.watch(audioHandlerProvider).volume;
});

final playerErrorProvider = StateProvider<String?>((ref) => null);

/// Live Second-by-Second Sleep Timer State & Notifier
class SleepTimerState {
  final int? selectedMinutes;
  final int remainingSeconds;

  const SleepTimerState({
    required this.selectedMinutes,
    required this.remainingSeconds,
  });

  const SleepTimerState.off()
      : selectedMinutes = null,
        remainingSeconds = 0;

  bool get isActive => selectedMinutes != null && remainingSeconds > 0;

  /// Formats remaining seconds as MM:SS (or HH:MM:SS if >= 1 hour)
  String get formattedCountdown {
    if (remainingSeconds <= 0) return '00:00';
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _ticker;

  SleepTimerNotifier(this._ref) : super(const SleepTimerState.off());

  void setTimer(int? minutes) {
    _ticker?.cancel();
    if (minutes == null || minutes <= 0) {
      state = const SleepTimerState.off();
      return;
    }

    final totalSeconds = minutes * 60;
    state = SleepTimerState(
      selectedMinutes: minutes,
      remainingSeconds: totalSeconds,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final nextSeconds = state.remainingSeconds - 1;
      if (nextSeconds <= 0) {
        timer.cancel();
        state = const SleepTimerState.off();
        try {
          await _ref.read(audioHandlerProvider).pause();
        } catch (_) {}
      } else {
        state = SleepTimerState(
          selectedMinutes: state.selectedMinutes,
          remainingSeconds: nextSeconds,
        );
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Station? _currentStation;
  double _lastNonZeroVolume = 1.0;

  AudioPlayerHandler() {
    _initAudioSession();
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
      ));
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {
      // AudioSession fallback if platform channel unavailable
    }
  }

  Future<void> playStation(Station station) async {
    _currentStation = station;

    mediaItem.add(MediaItem(
      id: station.id,
      title: station.name,
      artist: station.genre,
      album: station.countryCode,
      artUri: station.logoUrl.isNotEmpty ? Uri.parse(station.logoUrl) : null,
      extras: {'streamUrl': station.streamUrl},
    ));

    // Optimistically emit playing=true immediately so UI & wave indicators respond at 0ms
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause, MediaControl.stop],
      processingState: AudioProcessingState.loading,
      playing: true,
    ));

    try {
      // preload: false ensures setUrl does not block waiting for live stream headers
      // before calling .play(), preserving browser user-gesture autoplay and starting audio faster.
      await _player.setUrl(station.streamUrl, preload: false);
      await _player.play();
    } catch (_) {
      if (station.backupStreamUrl != null && station.backupStreamUrl!.isNotEmpty) {
        try {
          await _player.setUrl(station.backupStreamUrl!, preload: false);
          await _player.play();
        } catch (e) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  bool get isPlaying => _player.playing;
  Station? get currentStation => _currentStation;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  double get volume => _player.volume;
  Stream<double> get volumeStream => _player.volumeStream;

  Future<void> setVolume(double val) async {
    final clamped = val.clamp(0.0, 1.0);
    if (clamped > 0.02) {
      _lastNonZeroVolume = clamped;
    }
    await _player.setVolume(clamped);
  }

  Future<void> toggleMute() async {
    if (_player.volume > 0.02) {
      _lastNonZeroVolume = _player.volume;
      await _player.setVolume(0.0);
    } else {
      await _player.setVolume(_lastNonZeroVolume > 0.05 ? _lastNonZeroVolume : 0.85);
    }
  }
}
