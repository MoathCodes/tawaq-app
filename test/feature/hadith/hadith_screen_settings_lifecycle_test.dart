import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';

void main() {
  test('settings hydration survives a layout detaching its listener', () async {
    final ready = Completer<Storage<String, String>>();
    final container = ProviderContainer(
      overrides: [settingsStorageProvider.overrideWith((ref) => ready.future)],
    );
    addTearDown(container.dispose);
    final listener = container.listen(hadithScreenSettingsProvider, (_, _) {});
    final notifier = container.read(hadithScreenSettingsProvider.notifier);
    final pending = container.read(hadithScreenSettingsProvider.future);
    listener.close();
    await container.pump();
    ready.complete(Storage<String, String>.inMemory());
    await pending;
    await container.pump();
    expect(container.read(hadithScreenSettingsProvider).hasValue, isTrue);
    expect(
      container.read(hadithScreenSettingsProvider.notifier),
      same(notifier),
    );
  });
}
