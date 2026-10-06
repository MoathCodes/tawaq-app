// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/presentation/provider/hijri_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_header.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _PendingDay extends PrayerDay {
  @override
  Stream<PrayerDaySnapshot> build() => const Stream.empty();
}

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'hero status remains usable with reduced motion in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 860));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final theme = buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1.2,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prayerDayIsLoadingProvider.overrideWithValue(false),
              prayerCalendarDayKeyProvider.overrideWithValue(20261005),
              prayerDayProvider.overrideWith(_PendingDay.new),
              hijriClockProvider.overrideWithValue(''),
              prayerCardCountdownProvider.overrideWithValue('00:29:00'),
              prayerCardStaticProvider.overrideWithValue((
                prayer: Prayer.dhuhr,
                adhanTime: '11:42 AM',
                iqamahTime: '11:52 AM',
                canSetStatus: true,
                showIqamah: true,
                isCountdown: false,
                referenceTime: DateTime(2026, 10, 5),
              )),
              completionStatusProvider.overrideWith((ref, arguments) => null),
            ],
            child: MaterialApp(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  size: const Size(1200, 860),
                  textScaler: const TextScaler.linear(1.2),
                ),
                child: FTheme(data: theme, child: child!),
              ),
              home: const Scaffold(body: PrayerHeroHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final trigger = find.descendant(
          of: find.byType(PrayerHeroHeader),
          matching: find.byType(MouseClick),
        );
        expect(trigger, findsOneWidget);
        final animated = find.descendant(
          of: trigger,
          matching: find.byType(AnimatedContainer),
        );
        expect(
          tester.widget<AnimatedContainer>(animated).duration,
          Duration.zero,
        );
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        expect(find.byType(FItem), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      semanticsEnabled: false,
      variant: const TargetPlatformVariant({TargetPlatform.linux}),
    );
  }
}
