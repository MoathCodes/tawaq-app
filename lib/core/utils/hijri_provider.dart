import 'dart:ui';

import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijri_date/hijri.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hijri_provider.g.dart';

/// A provider that emits a formatted Hijri date string every second.
@riverpod
Stream<String> hijriClock(Ref ref) async* {
  final locale = ref.watch(localeProvider).value;
  yield _formatHijri(locale);
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => _formatHijri(locale),
  );
}

String _formatHijri(Locale? locale) {
  HijriDate.setLocal(locale?.languageCode ?? 'en');
  final hijriDate = HijriDate.fromDate(
    DateTime.now().toLocal(),
  ).toFormat('DDDD, dd MMMM yyyy');
  return hijriDate;
}
