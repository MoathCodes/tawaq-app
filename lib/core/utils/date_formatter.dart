import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_formatter.g.dart';

@riverpod
DateFormat timeFormatter(Ref ref) {
  final locale = ref.watch(localeNotifierProvider);
  final is24Hours = ref.watch(
      prayerSettingsNotifierProvider.select((s) => s.valueOrNull?.is24Hours));

  return is24Hours ?? false
      ? DateFormat.Hm(locale.value?.languageCode)
      : DateFormat.jm(locale.value?.languageCode);
}
