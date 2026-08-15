import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;

class FakeAudioPlayer extends Mock implements PlayerApi {}

class FakeAudioPlayerStream extends Mock implements PlayerStream {}

Future<void> noopAsync(Invocation _) async {}

/// Typed controllers for every stream [TawaqAudioService] subscribes to.
class FakeAudioStreamHandles {
  FakeAudioStreamHandles(this.player, this.stream);

  final FakeAudioPlayer player;
  final FakeAudioPlayerStream stream;

  final StreamController<bool> playing = StreamController<bool>.broadcast();
  final StreamController<bool> playWhenReady =
      StreamController<bool>.broadcast();
  final StreamController<bool> completed = StreamController<bool>.broadcast();
  final StreamController<bool> eofReached = StreamController<bool>.broadcast();
  final StreamController<MpvPlayerError> error =
      StreamController<MpvPlayerError>.broadcast();
  final StreamController<MpvFileEndedEvent> endFile =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<bool> buffering = StreamController<bool>.broadcast();
  final StreamController<bool> pausedForCache =
      StreamController<bool>.broadcast();
  final StreamController<void> seekCompleted = StreamController.broadcast();
  final StreamController<Duration> position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> duration =
      StreamController<Duration>.broadcast();
  final StreamController<int?> remainingAbLoops =
      StreamController<int?>.broadcast();
  final StreamController<DemuxerCacheState> demuxerCacheState =
      StreamController<DemuxerCacheState>.broadcast();
  final StreamController<Playlist> playlist =
      StreamController<Playlist>.broadcast();
  final StreamController<MediaSessionCommand> mediaSessionCommands =
      StreamController<MediaSessionCommand>.broadcast();

  Future<void> dispose() async {
    await playing.close();
    await playWhenReady.close();
    await completed.close();
    await eofReached.close();
    await error.close();
    await endFile.close();
    await buffering.close();
    await pausedForCache.close();
    await seekCompleted.close();
    await position.close();
    await duration.close();
    await remainingAbLoops.close();
    await demuxerCacheState.close();
    await playlist.close();
    await mediaSessionCommands.close();
  }
}

FakeAudioStreamHandles buildFakeAudioPlayer({
  PlayerState initialState = const PlayerState(),
}) {
  final stream = FakeAudioPlayerStream();
  final player = FakeAudioPlayer();
  final handles = FakeAudioStreamHandles(player, stream);

  when(() => stream.playing).thenAnswer((_) => handles.playing.stream);
  when(
    () => stream.playWhenReady,
  ).thenAnswer((_) => handles.playWhenReady.stream);
  when(() => stream.completed).thenAnswer((_) => handles.completed.stream);
  when(() => stream.eofReached).thenAnswer((_) => handles.eofReached.stream);
  when(() => stream.error).thenAnswer((_) => handles.error.stream);
  when(() => stream.endFile).thenAnswer((_) => handles.endFile.stream);
  when(() => stream.buffering).thenAnswer((_) => handles.buffering.stream);
  when(
    () => stream.pausedForCache,
  ).thenAnswer((_) => handles.pausedForCache.stream);
  when(
    () => stream.seekCompleted,
  ).thenAnswer((_) => handles.seekCompleted.stream);
  when(() => stream.position).thenAnswer((_) => handles.position.stream);
  when(() => stream.duration).thenAnswer((_) => handles.duration.stream);
  when(
    () => stream.remainingAbLoops,
  ).thenAnswer((_) => handles.remainingAbLoops.stream);
  when(
    () => stream.demuxerCacheState,
  ).thenAnswer((_) => handles.demuxerCacheState.stream);
  when(() => stream.playlist).thenAnswer((_) => handles.playlist.stream);
  when(
    () => stream.mediaSessionCommands,
  ).thenAnswer((_) => handles.mediaSessionCommands.stream);
  when(() => player.stream).thenReturn(stream);
  when(() => player.state).thenReturn(initialState);
  when(
    () => player.open(any(), play: any(named: 'play')),
  ).thenAnswer(noopAsync);
  when(
    () => player.openAll(
      any(),
      play: any(named: 'play'),
      index: any(named: 'index'),
    ),
  ).thenAnswer(noopAsync);
  when(player.play).thenAnswer(noopAsync);
  when(player.pause).thenAnswer(noopAsync);
  when(player.stop).thenAnswer(noopAsync);
  when(
    () => player.seek(
      any(),
      relative: any(named: 'relative'),
      exact: any(named: 'exact'),
    ),
  ).thenAnswer(noopAsync);
  when(() => player.setVolume(any())).thenAnswer(noopAsync);
  when(() => player.setMediaSession(any())).thenAnswer(noopAsync);
  when(() => player.setAudioClientName(any())).thenAnswer(noopAsync);
  when(() => player.setAbLoopA(any())).thenAnswer(noopAsync);
  when(() => player.setAbLoopB(any())).thenAnswer(noopAsync);
  when(() => player.setAbLoopCount(any())).thenAnswer(noopAsync);
  when(() => player.setLoop(any())).thenAnswer(noopAsync);
  when(() => player.setGapless(any())).thenAnswer(noopAsync);
  when(() => player.setPrefetchPlaylist(any())).thenAnswer(noopAsync);
  when(
    () => player.deleteResumeConfig(filename: any(named: 'filename')),
  ).thenAnswer(noopAsync);
  when(player.dispose).thenAnswer(noopAsync);

  return handles;
}

void setFakePlayerState(FakeAudioPlayer player, PlayerState state) {
  when(() => player.state).thenReturn(state);
}

void registerAudioServiceFallbacks() {
  registerFallbackValue(const Media('asset:///fallback'));
  registerFallbackValue(Duration.zero);
  registerFallbackValue(0.0);
  registerFallbackValue(const MediaSession());
  registerFallbackValue('');
  registerFallbackValue(Loop.off);
  registerFallbackValue(Gapless.weak);
}
