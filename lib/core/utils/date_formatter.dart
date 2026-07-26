import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

part 'date_formatter.g.dart';

/// Provides a localized [DateFormat] for formatting prayer times.
///
/// This provider watches the current locale and the 24-hour time setting
/// to return a [DateFormat] instance that can be used to format prayer times
/// in the correct format.
@riverpod
DateFormat timeFormatter(Ref ref) {
  final langCode = ref.watch(localeProvider).value ?? 'en';
  final is24Hours = ref.watch(
    prayerSettingsProvider.select((s) => s.value?.is24Hours),
  );

  return is24Hours ?? false ? DateFormat.Hm(langCode) : DateFormat.jm(langCode);
}
