import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';

class _FakePlayer extends Mock implements PlayerApi {}

class _FakePlayerStream extends Mock implements PlayerStream {}

Future<void> _noop(Invocation _) async {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Media('asset:///fallback'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(0.0);
    registerFallbackValue(const MediaSession());
    registerFallbackValue('');
  });

  late _FakePlayer player;
  late _FakePlayerStream stream;
  late StreamController<bool> playing;
  late StreamController<MpvPlayerError> error;
  late StreamController<MpvFileEndedEvent> endFile;
  late StreamController<bool> buffering;
  late StreamController<bool> pausedForCache;
  late StreamController<void> seekCompleted;
  late StreamController<Duration> position;
  late StreamController<Duration> duration;
  late StreamController<int?> remainingAbLoops;
  late StreamController<MediaSessionCommand> mediaSessionCommands;

  setUp(() {
    stream = _FakePlayerStream();
    player = _FakePlayer();
    playing = StreamController<bool>.broadcast();
    error = StreamController<MpvPlayerError>.broadcast();
    endFile = StreamController<MpvFileEndedEvent>.broadcast();
    buffering = StreamController<bool>.broadcast();
    pausedForCache = StreamController<bool>.broadcast();
    seekCompleted = StreamController.broadcast();
    position = StreamController<Duration>.broadcast();
    duration = StreamController<Duration>.broadcast();
    remainingAbLoops = StreamController<int?>.broadcast();
    mediaSessionCommands = StreamController<MediaSessionCommand>.broadcast();

    when(() => stream.playing).thenAnswer((_) => playing.stream);
    when(() => stream.error).thenAnswer((_) => error.stream);
    when(() => stream.endFile).thenAnswer((_) => endFile.stream);
    when(() => stream.buffering).thenAnswer((_) => buffering.stream);
    when(() => stream.pausedForCache).thenAnswer((_) => pausedForCache.stream);
    when(() => stream.seekCompleted).thenAnswer((_) => seekCompleted.stream);
    when(() => stream.position).thenAnswer((_) => position.stream);
    when(() => stream.duration).thenAnswer((_) => duration.stream);
    when(() => stream.remainingAbLoops)
        .thenAnswer((_) => remainingAbLoops.stream);
    when(() => stream.mediaSessionCommands)
        .thenAnswer((_) => mediaSessionCommands.stream);
    when(() => player.stream).thenReturn(stream);
    when(() => player.state).thenReturn(const PlayerState());
    when(() => player.open(any(), play: any(named: 'play'))).thenAnswer(_noop);
    when(player.play).thenAnswer(_noop);
    when(player.pause).thenAnswer(_noop);
    when(player.stop).thenAnswer(_noop);
    when(() => player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        )).thenAnswer(_noop);
    when(() => player.setVolume(any())).thenAnswer(_noop);
    when(() => player.setMediaSession(any())).thenAnswer(_noop);
    when(() => player.setAudioClientName(any())).thenAnswer(_noop);
    when(player.dispose).thenAnswer(_noop);
  });

  tearDown(() async {
    await playing.close();
    await error.close();
    await endFile.close();
    await buffering.close();
    await pausedForCache.close();
    await seekCompleted.close();
    await position.close();
    await duration.close();
    await remainingAbLoops.close();
    await mediaSessionCommands.close();
  });

  test('appBootstrapReady completes on desktop without errors', () async {
    final service = TawaqAudioService(player: player);
    final container = ProviderContainer(
      overrides: [
        hiveCoreInitProvider.overrideWith((ref) async {}),
        desktopShellInitProvider.overrideWith((ref) async {}),
        tawaqAudioServiceProvider.overrideWith((ref) {
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(appBootstrapReadyProvider.future),
      completes,
    );
  });
}
