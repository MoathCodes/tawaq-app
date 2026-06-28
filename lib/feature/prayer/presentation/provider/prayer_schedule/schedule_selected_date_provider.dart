import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'schedule_selected_date_provider.g.dart';

/// Calendar day selected in the prayer schedule list (defaults to today).
///
/// User picks persist via [select]; midnight rollover follows only when the
/// user was already viewing "today".
@Riverpod(keepAlive: true)
class ScheduleSelectedDate extends _$ScheduleSelectedDate {
  @override
  DateTime build() {
    ref.listen(prayerCalendarDayKeyProvider, (previous, next) {
      if (previous == null || previous == 0 || next == 0 || previous == next) {
        return;
      }

      if (isSameCalendarDayKey(state, previous)) {
        state = dateFromCalendarDayKey(next);
      }
    });

    return _initialSelectedDate();
  }

  DateTime _initialSelectedDate() {
    final dayKey = ref.read(prayerCalendarDayKeyProvider);
    if (dayKey != 0) return dateFromCalendarDayKey(dayKey);

    final now = ref.read(prayerDayProvider).value?.now;
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
