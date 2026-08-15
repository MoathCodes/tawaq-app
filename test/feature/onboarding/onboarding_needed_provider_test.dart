import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;

const _persistOptions = StorageOptions(
  cacheTime: StorageCacheTime.unsafe_forever,
);

ProviderContainer _containerWith(Storage<String, String> storage) {
  return ProviderContainer(
    overrides: [
      hiveCoreInitProvider.overrideWith((ref) async {}),
      settingsStorageProvider.overrideWith((ref) async => storage),
    ],
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('computeOnboardingNeeded', () {
    test('is false while onboarding or prayer settings are loading', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: true,
          onboardingCompleted: false,
          prayerLoading: false,
        ),
        isFalse,
      );
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: false,
          prayerLoading: true,
        ),
        isFalse,
      );
    });

    test('is false when onboarding already completed', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: true,
          prayerLoading: false,
        ),
        isFalse,
      );
    });

    test('is true until onboarding is completed', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: false,
          prayerLoading: false,
        ),
        isTrue,
      );
    });
  });

  group('OnboardingStateNotifier reopen + durability', () {
    test(
      'reset clears completed so reopen is allowed (no bounce)',
      () async {
        final storage = Storage<String, String>.inMemory();
        await storage.write(
          'OnboardingStateNotifier',
          '{"completed":true,"completedAt":"2026-01-01T00:00:00.000"}',
          _persistOptions,
        );

        final container = _containerWith(storage);
        addTearDown(container.dispose);
        final before = await container.read(onboardingStateProvider.future);
        expect(before.completed, isTrue);
        // Without reset, redirect would eject /onboarding (needed == false).
        expect(
          computeOnboardingNeeded(
            onboardingLoading: false,
            onboardingCompleted: before.completed,
            prayerLoading: false,
          ),
          isFalse,
        );

        final cleared = await container
            .read(onboardingStateProvider.notifier)
            .reset();
        expect(cleared, isTrue);

        final after = container.read(onboardingStateProvider).requireValue;
        expect(after.completed, isFalse);
        expect(
          computeOnboardingNeeded(
            onboardingLoading: false,
            onboardingCompleted: after.completed,
            prayerLoading: false,
          ),
          isTrue,
        );
      },
    );

    test('finish without hydrate returns false (no navigate)', () async {
      final gate = Completer<Storage<String, String>>();
      final container = ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {}),
          settingsStorageProvider.overrideWith((ref) => gate.future),
        ],
      );
      addTearDown(container.dispose);

      // Start hydrate (blocked on storage) then call finish while !hasValue.
      unawaited(container.read(onboardingStateProvider.future));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingStateProvider).hasValue, isFalse);

      final finished = await container
          .read(onboardingStateProvider.notifier)
          .finish();
      expect(finished, isFalse);

      gate.complete(Storage.inMemory());
      final hydrated = await container.read(onboardingStateProvider.future);
      expect(hydrated.completed, isFalse);
    });

    test(
      'finish awaits Storage.write so cold start still sees completed',
      () async {
        final storage = Storage<String, String>.inMemory();
        final container = _containerWith(storage);
        await container.read(onboardingStateProvider.future);

        final finished = await container
            .read(onboardingStateProvider.notifier)
            .finish();
        expect(finished, isTrue);
        // Snapshot disk before disposing the live notifier.
        final written = await storage.read('OnboardingStateNotifier');
        expect(written?.data, contains('"completed":true'));
        container.dispose();

        final cold = _containerWith(storage);
        addTearDown(cold.dispose);

        final restored = await cold.read(onboardingStateProvider.future);
        expect(restored.completed, isTrue);
        expect(restored.completedAt, isNotNull);
      },
    );

    test('reset awaits Storage.write so cold start stays cleared', () async {
      final storage = Storage<String, String>.inMemory();
      await storage.write(
        'OnboardingStateNotifier',
        '{"completed":true,"completedAt":"2026-01-01T00:00:00.000"}',
        _persistOptions,
      );

      final container = _containerWith(storage);
      await container.read(onboardingStateProvider.future);
      final cleared = await container
          .read(onboardingStateProvider.notifier)
          .reset();
      expect(cleared, isTrue);
      final written = await storage.read('OnboardingStateNotifier');
      expect(written?.data, contains('"completed":false'));
      container.dispose();

      final cold = _containerWith(storage);
      addTearDown(cold.dispose);

      final restored = await cold.read(onboardingStateProvider.future);
      expect(restored.completed, isFalse);
    });
  });
}
