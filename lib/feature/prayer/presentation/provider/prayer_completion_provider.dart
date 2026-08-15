import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'prayer_completion_provider.g.dart';

/// Write actions for prayer completion records.
@Riverpod(keepAlive: true)
class PrayerCompletionActions extends _$PrayerCompletionActions {
  @override
  void build() {}

  Location? get _location => ref.read(prayerTimeInputsProvider)?.location;

  /// Sets or clears the completion status for [prayer] on [completionDay].
  ///
  /// [completionDay] should carry the intended calendar wall components (from
  /// a day key or [completionCalendarDay]); storage uses location midnight.
  Future<void> setPrayerStatus({
    required Prayer prayer,
    required DateTime completionDay,
    required CompletionStatus status,
  }) async {
    if (!ref.mounted) return;
    final location = _location;
    if (location == null) return;

    final dayKey = calendarDayKeyFromDate(completionDay);
    final dayInstant = calendarDayFromKey(dayKey, location);

    if (status == CompletionStatus.none) {
      await ref
          .read(prayerCompletionStoreProvider.notifier)
          .deletePrayer(
            prayer,
            dayInstant,
          );
    } else {
      final existing = await _loadCanonical(prayer, dayKey);
      final completion = PrayerCompletion(
        id: existing?.id,
        prayer: prayer,
        completionTime: existing?.completionTime ?? dayInstant,
        status: status,
      );
      await ref.read(prayerCompletionStoreProvider.notifier).save(completion);
    }
  }

  /// Cycles [prayer]'s completion on today's calendar day.
  ///
  /// Order: none → jamaah → onTime → late → missed → cleared.
  Future<void> cycleTodayPrayerStatus({
    required Prayer prayer,
    required CompletionStatus currentStatus,
  }) async {
    if (!ref.mounted) return;

    final location = _location;
    final now = ref.read(prayerDayProvider).value?.now;
    if (location == null || now == null) return;

    final completionDay = completionCalendarDay(now, location);
    final nextStatus = currentStatus.trackerCycleNext;

    await setPrayerStatus(
      prayer: prayer,
      completionDay: completionDay,
      status: nextStatus ?? CompletionStatus.none,
    );
  }

  Future<PrayerCompletion?> _loadCanonical(
    Prayer prayer,
    int dayKey,
  ) async {
    final location = _location;
    if (location == null) return null;

    final completions = await ref.read(
      prayerCompletionsForDateProvider(dayKey).future,
    );
    return pickCanonical(
      completions,
      prayer: prayer,
      location: location,
      day: calendarDayFromKey(dayKey, location),
    );
  }
}
