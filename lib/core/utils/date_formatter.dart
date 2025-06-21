import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_formatter.g.dart';

@riverpod
DateFormat timeFormatter(Ref ref, {bool? is24Hours}) {
  final locale = ref.watch(localeNotifierProvider);

  return is24Hours ?? false
      ? DateFormat.Hm(locale.value?.languageCode)
      : DateFormat.jm(locale.value?.languageCode);
}
