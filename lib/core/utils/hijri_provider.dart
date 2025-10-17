import 'dart:ui';

import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hijri_provider.g.dart';

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
  Hijriyah.setLocal(locale?.languageCode ?? 'en');
  final hijriDate = Hijriyah.fromDate(
    DateTime.now().toLocal(),
  ).toFormat('EEEE, dd MMMM yyyy');
  return hijriDate;
}
