import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';

import '../audio/fake_audio_player.dart';

void main() {
  setUpAll(registerAudioServiceFallbacks);

  late FakeAudioStreamHandles handles;

  setUp(() {
    handles = buildFakeAudioPlayer();
  });

  tearDown(() async {
    await handles.dispose();
  });

  test('appBootstrapReady completes on desktop without errors', () async {
    final service = TawaqAudioService(player: handles.player);
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
