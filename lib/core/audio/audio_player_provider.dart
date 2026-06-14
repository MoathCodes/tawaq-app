import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_queue.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/logging/logger_provider.dart';

part 'audio_player_provider.g.dart';

/// Singleton [TawaqAudioService] for the process.
@Riverpod(keepAlive: true)
TawaqAudioService tawaqAudioService(Ref ref) {
  final service = TawaqAudioService();
  ref.onDispose(service.dispose);
  return service;
}

/// High-level playback controller for adhan and future Quran recitation.
@Riverpod(keepAlive: true)
class AudioPlayerController extends _$AudioPlayerController {
  PlaybackQueue? _queue;

  @override
  PlaybackState build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    final sub = service.stateStream.listen((next) {
      state = next;
    });
    ref.onDispose(sub.cancel);
    return service.state;
  }

  TawaqAudioService get _service => ref.read(tawaqAudioServiceProvider);

  /// Plays a single [track].
  Future<void> playTrack(AudioTrack track) async {
    _queue = null;
    await _service.play(track);
  }

  /// Plays [queue] from its current index.
  Future<void> playQueue(PlaybackQueue queue) async {
    _queue = queue;
    final track = queue.currentTrack;
    if (track == null) return;
    await _service.play(track);
  }

  /// Stub until recitation sources are bundled.
  Future<void> playAyah({required int surah, required int ayah}) async {
    ref.read(loggerProvider).i(
      'Quran recitation not yet available (surah $surah, ayah $ayah)',
    );
  }

  /// Pauses the active track.
  Future<void> pause() => _service.pause();

  /// Resumes the active track.
  Future<void> resume() => _service.resume();

  /// Stops playback.
  Future<void> stop() async {
    _queue = null;
    await _service.stop();
  }

  /// Sets output volume from 0 to 100.
  Future<void> setVolume(double volume) => _service.setVolume(volume);

  /// Skips to the next queue item when available.
  Future<void> skipToNext() async {
    final queue = _queue;
    if (queue == null) return;
    final next = queue.next();
    if (next == null) {
      await stop();
      return;
    }
    _queue = next;
    final track = next.currentTrack;
    if (track != null) await _service.play(track);
  }
}
