// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_prayer_row.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 700.0]) {
      testWidgets('iqamah keeps row rhythm at $width in $language', (
        tester,
      ) async {
        final heights = <double>[];
        for (final iqamah in [null, '12:29 PM']) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                completionStatusProvider.overrideWith((ref, args) => null),
                prayerMinuteSnapshotProvider.overrideWithValue(null),
              ],
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: FTheme(
                  data: buildAppTheme(
                    palette: AppPalette.manuscript,
                    themeMode: ThemeMode.dark,
                    touch: false,
                    textScale: width == 320 ? 1.5 : 1,
                  ),
                  child: Scaffold(
                    body: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: width,
                        child: SchedulePrayerRow(
                          row: PrayerScheduleRow(
                            prayer: Prayer.dhuhr,
                            prayerTime: DateTime(2026, 10, 6, 12),
                            formattedAdhanTime: '12:19 PM',
                            formattedIqamahTime: iqamah,
                          ),
                          isToday: false,
                          currentPrayer: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          heights.add(tester.getSize(find.byType(SchedulePrayerRow)).height);
          expect(tester.takeException(), isNull);
        }
        if (width == 700) expect(heights[1], heights[0]);
      });
    }
  }
}
