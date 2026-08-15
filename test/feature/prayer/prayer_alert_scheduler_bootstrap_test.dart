import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_alert_scheduler_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

class _MockCoordinator extends Mock implements PrayerAlertCoordinator {}

class _CountingDispatcher extends PrayerAlertDispatcher {
  final fired = <PrayerAlertEvent>[];

  @override
  PrayerAlertCoordinator build() => _MockCoordinator();

  @override
  Future<void> dispatch(PrayerAlertEvent event) async {
    fired.add(event);
  }
}

/// Controllable live clock for scheduler tests.
class _ManualPrayerDay extends PrayerDay {
  final _controller = StreamController<PrayerDaySnapshot>.broadcast();

  @override
  Stream<PrayerDaySnapshot> build() {
    ref.onDispose(_controller.close);
    return _controller.stream;
  }

  void push(PrayerDaySnapshot snapshot) => _controller.add(snapshot);

  /// Simulate a clock gap (loading retains prior `.value`, but not `asData`).
  void emitLoadingGap() {
    state = const AsyncLoading<PrayerDaySnapshot>();
  }
}

class _LocaleOverride extends LocaleNotifier {
  @override
  Future<String> build() async => 'en';
}

class _AdhanOverride extends AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() async => AdhanSettings.defaults();
}

/// Stays in AsyncLoading with a null `.value` until [hydrate] is called.
class _DelayedAdhanOverride extends AdhanSettingsNotifier {
  final _ready = Completer<AdhanSettings>();

  @override
  Future<AdhanSettings> build() => _ready.future;

  void hydrate([AdhanSettings? settings]) {
    if (!_ready.isCompleted) {
      _ready.complete(settings ?? AdhanSettings.defaults());
    }
  }
}

void main() {
  setUpAll(tz.initializeTimeZones);

  late Location location;
  late PrayerSettings settings;
  late PrayerDaySnapshot Function(TZDateTime now) snapshotAt;
  late _CountingDispatcher dispatcher;
  late ProviderContainer container;

  setUp(() {
    location = getLocation('Asia/Riyadh');
    settings = PrayerSettings.defaultSettings().copyWith(
      coordinates: Coordinates(21.575224, 39.210725),
      location: location,
    );
    final inputs = PrayerTimeInputs(
      method: settings.method,
      coordinates: settings.coordinates,
      location: settings.location,
      adhanAdjustments: settings.adhanAdjustments,
    );
    final bundle = computePrayerDayBundle(
      inputs: inputs,
      anchorNow: TZDateTime(location, 2026, 6, 18, 12),
    );
    snapshotAt = (now) => PrayerDaySnapshot(
      now: now,
      location: location,
      bundle: bundle,
    );

    dispatcher = _CountingDispatcher();
    container = ProviderContainer(
      overrides: [
        prayerDayProvider.overrideWith(_ManualPrayerDay.new),
        effectivePrayerSettingsProvider.overrideWithValue(settings),
        adhanSettingsProvider.overrideWith(_AdhanOverride.new),
        localeProvider.overrideWith(_LocaleOverride.new),
        prayerAlertDispatcherProvider.overrideWith(() => dispatcher),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('null prayerDay re-bootstraps — no stale catch-up fire', () async {
    final fajr = snapshotAt(
      TZDateTime(location, 2026, 6, 18, 12),
    ).timeline.fajrToday;

    container.listen(prayerAlertSchedulerProvider, (_, _) {});
    final day = container.read(prayerDayProvider.notifier) as _ManualPrayerDay;

    // Bootstrap tick just before fajr.
    day.push(snapshotAt(fajr.subtract(const Duration(seconds: 1))));
    await Future<void>.delayed(Duration.zero);
    expect(dispatcher.fired, isEmpty);

    // Gap: loading (asData == null) clears bootstrap even if .value is retained.
    day.emitLoadingGap();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(prayerDayProvider).asData, isNull);

    // Resume well after fajr but inside the catch-up window.
    day.push(snapshotAt(fajr.add(const Duration(minutes: 5))));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(dispatcher.fired, isEmpty);
  });

  test('adhanSettings null freezes then re-bootstraps on hydrate', () async {
    final delayed = _DelayedAdhanOverride();
    final localDispatcher = _CountingDispatcher();
    final local = ProviderContainer(
      overrides: [
        prayerDayProvider.overrideWith(_ManualPrayerDay.new),
        effectivePrayerSettingsProvider.overrideWithValue(settings),
        adhanSettingsProvider.overrideWith(() => delayed),
        localeProvider.overrideWith(_LocaleOverride.new),
        prayerAlertDispatcherProvider.overrideWith(() => localDispatcher),
      ],
    );
    addTearDown(local.dispose);

    final fajr = snapshotAt(
      TZDateTime(location, 2026, 6, 18, 12),
    ).timeline.fajrToday;

    local.listen(prayerAlertSchedulerProvider, (_, _) {});
    final day = local.read(prayerDayProvider.notifier) as _ManualPrayerDay;

    // Ticks while adhan is still loading must not advance the catch-up clock.
    day.push(snapshotAt(fajr.subtract(const Duration(seconds: 1))));
    await Future<void>.delayed(Duration.zero);
    day.push(snapshotAt(fajr.add(const Duration(minutes: 2))));
    await Future<void>.delayed(Duration.zero);
    expect(localDispatcher.fired, isEmpty);

    delayed.hydrate();
    // Allow the async notifier to settle.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(local.read(adhanSettingsProvider).hasValue, isTrue);

    // First ready tick re-bootstraps (no fire) even though fajr was crossed
    // while settings were null.
    day.push(snapshotAt(fajr.add(const Duration(minutes: 3))));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(localDispatcher.fired, isEmpty);

    // A later fresh crossing (e.g. next prayer) can still fire — use dhuhr.
    final dhuhr = snapshotAt(
      TZDateTime(location, 2026, 6, 18, 12),
    ).timeline.dhuhrToday;
    day.push(snapshotAt(dhuhr.subtract(const Duration(seconds: 1))));
    await Future<void>.delayed(Duration.zero);
    day.push(snapshotAt(dhuhr.add(const Duration(seconds: 1))));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      localDispatcher.fired.any(
        (e) => e.prayer == Prayer.dhuhr && e.kind.name == 'adhan',
      ),
      isTrue,
    );
  });
}
