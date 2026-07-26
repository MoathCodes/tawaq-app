import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/hijri_format.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'hijri_provider.g.dart';

/// Formatted Hijri date for the current prayer-calendar day.
///
/// Invalidates on locale or day change only (not every clock tick).
@riverpod
String hijriClock(Ref ref) {
  // Day key + locale are the only reactive inputs; the instant is read
  // non-reactively so this does not recompute on every 1 Hz clock tick.
  ref.watch(prayerCalendarDayKeyProvider);
  final langCode = ref.watch(localeProvider).value ?? 'en';
  final settings = ref.read(effectivePrayerSettingsProvider);
  if (settings == null) return '';
  return HijriFormat.formatDate(
    TZDateTime.now(settings.location),
    langCode,
    pattern: 'DDDD, dd MMMM yyyy',
  );
}
