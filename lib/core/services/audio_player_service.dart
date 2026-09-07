import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';

// Global provider for the audio handler
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError('Must be initialized in main');
});

final currentStationProvider = StateProvider<Station?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final playerErrorProvider = StateProvider<String?>((ref) => null);

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Station? _currentStation;

  AudioPlayerHandler() {
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

    try {
      await _player.stop();
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (_) {
      if (station.backupStreamUrl != null && station.backupStreamUrl!.isNotEmpty) {
        try {
          await _player.setUrl(station.backupStreamUrl!);
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
}
