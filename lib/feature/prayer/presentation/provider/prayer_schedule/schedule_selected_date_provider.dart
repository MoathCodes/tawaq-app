import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';

part 'schedule_selected_date_provider.g.dart';

/// Calendar day selected in the prayer schedule list (defaults to today).
@Riverpod(keepAlive: true)
class ScheduleSelectedDate extends _$ScheduleSelectedDate {
  @override
  DateTime build() {
    final now = ref.read(currentLocationTimeProvider);
    return DateTime(now.year, now.month, now.day);
  }

  /// Updates the schedule list to [date] (date component only).
  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}
