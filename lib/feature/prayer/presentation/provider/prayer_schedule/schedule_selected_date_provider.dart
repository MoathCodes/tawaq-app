import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_calendar_utils.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'schedule_selected_date_provider.g.dart';

/// Calendar day selected in the prayer schedule list (defaults to today).
///
/// Intentionally decoupled from the 1 Hz [currentLocationTimeProvider] clock.
/// User picks persist via [select]; midnight rollover follows only when the
/// user was already viewing "today".
@Riverpod(keepAlive: true)
class ScheduleSelectedDate extends _$ScheduleSelectedDate {
  @override
  DateTime build() {
    ref.listen(prayerCalendarDayKeyProvider, (previous, next) {
      final prevKey = previous ?? 0;
      final nextKey = next ?? 0;
      if (prevKey == 0 || nextKey == 0 || prevKey == nextKey) return;

      if (isSameCalendarDayKey(state, prevKey)) {
        state = dateFromCalendarDayKey(nextKey);
      }
    });

    return _initialSelectedDate();
  }

  DateTime _initialSelectedDate() {
    final dayKey = ref.read(prayerCalendarDayKeyProvider);
    if (dayKey != 0) return dateFromCalendarDayKey(dayKey);

    final now = ref.read(currentLocationTimeProvider);
    if (now != null) {
      return DateTime(now.year, now.month, now.day);
    }

    final settings = ref.read(effectivePrayerSettingsProvider);
    if (settings != null) {
      final tzNow = TZDateTime.now(settings.location);
      return DateTime(tzNow.year, tzNow.month, tzNow.day);
    }

    return DateTime.now();
  }

  /// Updates the schedule list to [date] (date component only).
  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}
