// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_repair_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;

class _Database extends Mock implements PrayerDatabase;

void main() {
  setUpAll(tz.initializeTimeZones);
  for (final language in ['en', 'ar']) {
    for (final owner in ['repair', 'read']) {
      testWidgets('$language analytics retries failed $owner dependency', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = _Database();
        var repairs = 0;
        var reads = 0;
        final resumed = Completer<void>();
        when(database.getAllCompletions).thenAnswer((_) async {
          if (++reads == 1 && owner == 'read')
            throw StateError('private analytics diagnostic');
          if (owner == 'read') await resumed.future;
          return const <PrayerCompletion>[];
        });
        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            hiveCoreInitProvider.overrideWith((ref) async {}),
            settingsStorageProvider.overrideWith(
              (ref) async => Storage<String, String>.inMemory(),
            ),
            prayerDatabaseProvider.overrideWithValue(database),
            effectivePrayerSettingsProvider.overrideWithValue(
              PrayerSettings.defaultSettings().copyWith(
                coordinates: Coordinates(24.7136, 46.6753),
              ),
            ),
            appClockProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 10, 3, 9, 12)),
            ),
            prayerCompletionsRepairProvider.overrideWith((ref) async {
              repairs++;
              if (owner == 'repair') {
                if (repairs == 1)
                  throw StateError('private analytics diagnostic');
                await resumed.future;
              }
            }),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: FTheme(
              data: buildAppTheme(
                palette: AppPalette.manuscript,
                themeMode: ThemeMode.dark,
                touch: false,
                textScale: 1.2,
              ),
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(
                  body: SingleChildScrollView(child: AnalysisSection()),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final l10n = lookupAppLocalizations(Locale(language));
        final message = language == 'en'
            ? 'Could not load prayer analytics. Try again.'
            : 'تعذّر تحميل إحصاءات الصلاة. حاول مرة أخرى.';
        expect(find.text(message), findsOneWidget);
        expect(
          find.textContaining('private analytics diagnostic'),
          findsNothing,
        );
        await tester.tap(find.text(l10n.retryAction));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(owner == 'repair' ? repairs : reads, 2);
        expect(find.text(message), findsNothing);
        expect(find.text(l10n.prayerAnalyticsNoRecords), findsNothing);
        resumed.complete();
        await tester.pumpAndSettle();
        expect(find.text(l10n.prayerAnalyticsNoRecords), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
