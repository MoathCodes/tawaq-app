import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_formatter.g.dart';

/// Provides a localized [DateFormat] for formatting prayer times.
///
/// This provider watches the current locale and the 24-hour time setting
/// to return a [DateFormat] instance that can be used to format prayer times
/// in the correct format.
@riverpod
DateFormat timeFormatter(Ref ref) {
  final locale = ref.watch(localeProvider);
  final is24Hours = ref.watch(
    prayerSettingsProvider.select((s) => s.value?.is24Hours),
  );

  return is24Hours ?? false
      ? DateFormat.Hm(locale.value?.languageCode)
      : DateFormat.jm(locale.value?.languageCode);
}