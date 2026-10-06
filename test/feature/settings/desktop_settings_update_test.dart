import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/desktop/launch_at_login_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';

void main() {
  test(
    'pending login registration preserves concurrent desktop edits',
    () async {
      final gate = Completer<void>();
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) async => Storage<String, String>.inMemory(),
          ),
          launchAtLoginUpdateProvider.overrideWithValue((value) {
            calls++;
            expect(value, isTrue);
            return gate.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(desktopSettingsProvider.future);
      final owner = container.read(desktopSettingsProvider.notifier);
      final pending = owner.setLaunchAtLogin(value: true);
      final duplicate = owner.setLaunchAtLogin(value: true);
      owner.setMinimizeToTray(value: true);
      owner.setForceMacStyleWindowControls(value: true);
      expect(
        container.read(desktopSettingsProvider).value!.launchAtLogin,
        isFalse,
      );
      expect(calls, 1);
      gate.complete();
      expect(await pending, isTrue);
      expect(await duplicate, isTrue);
      final prefs = container.read(desktopSettingsProvider).value!;
      expect(prefs.launchAtLogin, isTrue);
      expect(prefs.minimizeToTray, isTrue);
      expect(prefs.forceMacStyleWindowControls, isTrue);
    },
  );

  test('failed registration retains the preference and can retry', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWith(
          (ref) async => Storage<String, String>.inMemory(),
        ),
        launchAtLoginUpdateProvider.overrideWithValue((value) async {
          if (calls++ == 0) throw StateError('registration failed');
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(desktopSettingsProvider.future);
    final owner = container.read(desktopSettingsProvider.notifier);
    await expectLater(owner.setLaunchAtLogin(value: true), throwsStateError);
    expect(
      container.read(desktopSettingsProvider).value!.launchAtLogin,
      isFalse,
    );
    expect(await owner.setLaunchAtLogin(value: true), isTrue);
    expect(calls, 2);
  });
}
