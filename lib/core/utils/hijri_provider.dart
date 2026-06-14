import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/hijri_format.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';

part 'hijri_provider.g.dart';

/// Formatted Hijri date for the current prayer-calendar day.
///
/// Invalidates on locale or day change only (not every clock tick).
@riverpod
String hijriClock(Ref ref) {
  ref.watch(prayerCalendarDayKeyProvider);
  final langCode = ref.watch(localeProvider);
  final now = ref.read(currentLocationTimeProvider);
  return HijriFormat.formatDate(
    now,
    langCode,
    pattern: 'DDDD, dd MMMM yyyy',
  );
}
