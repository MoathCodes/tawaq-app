import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_completion_provider.g.dart';

/// Today's prayer completions (alias for [prayerCompletionsForDate]).
@riverpod
Future<List<PrayerCompletion>> prayerCompletion(Ref ref) {
  ref.watch(prayerCalendarDayKeyProvider);
  final now = ref.read(currentLocationTimeProvider);
  if (now == null) return Future.value(const []);

  final today = normalizeCompletionDay(now);
  return ref.watch(prayerCompletionsForDateProvider(today).future);
}

/// Write actions for prayer completion records.
@Riverpod(keepAlive: true)
class PrayerCompletionActions extends _$PrayerCompletionActions {
  @override
  void build() {}

  Location? get _location => ref.read(effectivePrayerSettingsProvider)?.location;

  /// Sets or clears the completion status for [prayer] on [completionDay].
  Future<void> setPrayerStatus({
    required Prayer prayer,
    required DateTime completionDay,
    required CompletionStatus status,
  }) async {
    if (!ref.mounted) return;
    final location = _location;
    if (location == null) return;

    final service = ref.read(prayerServiceProvider);
    final normalizedDay = normalizeCompletionDay(completionDay);

    if (status == CompletionStatus.none) {
      await service.deleteCompletionForPrayerOnDate(
        prayer,
        normalizedDay,
        location,
      );
    } else {
      final existing = await _loadCanonical(prayer, normalizedDay);
      final completion = PrayerCompletion(
        id: existing?.id,
        prayer: prayer,
        completionTime: existing?.completionTime ?? normalizedDay,
        status: status,
      );
      ref
          .read(firstPrayerRecordedDateProvider.notifier)
          .setIfNull(completion.completionTime);
      await service.addOrUpdateCompletion(completion, location);
    }

    if (!ref.mounted) return;
    invalidatePrayerCompletionsForDate(ref, normalizedDay);
  }

  /// Adds or updates a prayer completion record.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    if (!ref.mounted) return;
    await setPrayerStatus(
      prayer: completion.prayer,
      completionDay: completion.completionTime,
      status: completion.status,
    );
  }

  /// Cycles [prayer]'s completion on today's calendar day.
  ///
  /// Order: none → jamaah → onTime → late → missed → cleared.
  Future<void> cycleTodayPrayerStatus({
    required Prayer prayer,
    required CompletionStatus currentStatus,
  }) async {
    if (!ref.mounted) return;

    final now = ref.read(currentLocationTimeProvider);
    if (now == null) return;

    final completionDay = normalizeCompletionDay(now);
    final nextStatus = currentStatus.trackerCycleNext;

    await setPrayerStatus(
      prayer: prayer,
      completionDay: completionDay,
      status: nextStatus ?? CompletionStatus.none,
    );
  }

  /// Returns the canonical completion for [prayer] on [date].
  Future<PrayerCompletion?> getPrayerCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
  ) async {
    if (!prayer.isObligatory) return null;
    return _loadCanonical(prayer, normalizeCompletionDay(date));
  }

  Future<PrayerCompletion?> _loadCanonical(
    Prayer prayer,
    DateTime day,
  ) async {
    final location = _location;
    if (location == null) return null;

    final completions = await ref.read(
      prayerCompletionsForDateProvider(day).future,
    );
    return pickCanonical(
      completions,
      prayer: prayer,
      location: location,
      day: day,
    );
  }
}
