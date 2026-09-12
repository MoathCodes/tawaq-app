import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/hijri_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_header.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

PrayerCardStaticInfo _card({
  required Prayer prayer,
  required bool isCountdown,
  bool showIqamah = false,
}) => (
  prayer: prayer,
  adhanTime: '12:34 PM',
  iqamahTime: '12:44 PM',
  canSetStatus: false,
  showIqamah: showIqamah,
  isCountdown: isCountdown,
  referenceTime: DateTime(2026, 9, 12, 12, 34),
);

Widget _host({
  required Prayer prayer,
  required bool isCountdown,
  required Locale locale,
  required double width,
  double textScale = 1,
  String countdown = '00:12:34',
  bool dark = false,
}) {
  final theme = buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    touch: false,
    textScale: textScale,
  );

  return ProviderScope(
    overrides: [
      prayerDayIsLoadingProvider.overrideWithValue(false),
      prayerCardStaticProvider.overrideWithValue(
        _card(prayer: prayer, isCountdown: isCountdown),
      ),
      prayerCardCountdownProvider.overrideWithValue(countdown),
      hijriClockProvider.overrideWithValue(
        locale.languageCode == 'ar'
            ? 'السبت، ١٩ ربيع الأول ١٤٤٨'
            : 'Saturday, 19 Rabi al-awwal 1448',
      ),
      prayerCalendarDayKeyProvider.overrideWithValue(0),
    ],
    child: FTheme(
      data: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: SizedBox(
            width: width,
            child: const PrayerHeroHeader(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders elapsed obligatory prayer state and LTR duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prayer: Prayer.dhuhr,
        isCountdown: false,
        locale: const Locale('en'),
        width: 720,
        countdown: '+01:02:03',
      ),
    );

    expect(find.text('Current Prayer'), findsOneWidget);
    expect(find.text('Since prayer began'), findsOneWidget);
    final duration = tester.widget<Text>(find.text('+01:02:03'));
    expect(duration.textDirection, TextDirection.ltr);
  });

  testWidgets('renders upcoming pseudo-event wording and exact name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prayer: Prayer.fajrAfter,
        isCountdown: true,
        locale: const Locale('en'),
        width: 720,
      ),
    );

    expect(find.text('Next event'), findsOneWidget);
    expect(find.text('Time remaining'), findsOneWidget);
    expect(find.text('Midnight'), findsOneWidget);
    expect(find.text('Next Prayer'), findsNothing);
  });

  testWidgets('renders Arabic event wording and keeps digital duration LTR', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prayer: Prayer.sunrise,
        isCountdown: false,
        locale: const Locale('ar'),
        width: 720,
        countdown: '+٠١:٠٢:٠٣',
      ),
    );

    expect(find.text('الحدث الحالي'), findsOneWidget);
    expect(find.text('منذ بداية الحدث'), findsOneWidget);
    expect(find.text('الشروق'), findsOneWidget);
    final duration = tester.widget<Text>(find.text('+٠١:٠٢:٠٣'));
    expect(duration.textDirection, TextDirection.ltr);
  });

  for (final width in [320.0, 400.0]) {
    testWidgets(
      'keeps essential hero content visible at ${width.toInt()}dp with large text',
      (tester) async {
        await tester.pumpWidget(
          _host(
            prayer: Prayer.ishaBefore,
            isCountdown: true,
            locale: const Locale('en'),
            width: width,
            textScale: 1.6,
            dark: true,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Next event'), findsOneWidget);
        expect(find.text('Last Third Of The Night'), findsOneWidget);
        expect(find.text('00:12:34'), findsOneWidget);
      },
    );
  }
}
