/// Native composition review of injected startup and analytics failures.
/// Fixtures exercise mounted recovery callbacks, not OS input or real disk faults.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_lookup_section.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_repair_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

import 'launch_visual_harness.dart' show resizeOwnedWindow;

class _Locale extends LocaleNotifier {
  new(this.language);
  final String language;
  @override
  Future<String> build() async => language;
}

class _PendingOnboarding extends OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() => Completer<OnboardingState>().future;
}

class _PendingPrayer extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() => Completer<PrayerSettings>().future;
}

class _Store extends PrayerCompletionStore {
  @override
  Future<Map<int, List<PrayerCompletion>>> build() async {
    await ref.watch(prayerCompletionsRepairProvider.future);
    return const {};
  }
}

Future<void> main() async {
  try {
    await recoveryMain();
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}

/// Captures the isolated, injected recovery compositions.
Future<void> recoveryMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const ProviderScope(child: SizedBox.shrink()));
  final output = Directory(Platform.environment['LAUNCH_REVIEW_DIR']!);
  await output.create(recursive: true);
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.toString());
    previous?.call(details);
  };
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(800, 600),
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Tawaq recovery review',
    ),
  );
  await windowManager.show();
  await Future<void>.delayed(const Duration(seconds: 2));
  await resizeOwnedWindow(const Size(800, 600));
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  var size = view.physicalSize / view.devicePixelRatio;
  if (size != const Size(800, 600)) {
    await resizeOwnedWindow(Size(1600 - size.width, 1200 - size.height));
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
  size = view.physicalSize / view.devicePixelRatio;
  if (size != const Size(800, 600))
    throw StateError('Unexpected viewport $size');
  final key = GlobalKey();
  Future<void> capture(String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    stdout.writeln('Captured $name');
  }

  Future<void> pressRetry() async {
    final buttons = <FButton>[];
    void visit(Element element) {
      if (element.widget case FButton button) buttons.add(button);
      element.visitChildren(visit);
    }

    key.currentContext!.visitChildElements(visit);
    buttons.single.onPress!();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  for (final language in ['en', 'ar']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: mode,
        touch: false,
        textScale: 1.2,
      );
      final name = 'manuscript-$language-${mode.name}-800-xl';
      for (final owner in [
        'startup',
        'analytics',
        'lookup-scholars',
        'lookup-books',
        'lookup-rawi',
      ]) {
        var attempts = 0;
        final resume = Completer<void>();
        Future<void> load() async {
          if (++attempts == 1)
            throw StateError('injected private recovery diagnostic');
          await resume.future;
        }

        final kind = HadithLookupKind.values.firstWhere(
          (kind) => owner == 'lookup-${kind.name}',
          orElse: () => HadithLookupKind.books,
        );
        final l10n = lookupAppLocalizations(Locale(language));
        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            hadithLookupProvider(kind, 'اب').overrideWith((ref) async {
              await load();
              return const [
                HadithLookupRef(id: 'fixture', name: 'Lookup fixture'),
              ];
            }),
            hiveCoreInitProvider.overrideWith((ref) async {}),
            settingsStorageProvider.overrideWith(
              // This native fixture is a transient test scope with no user data.
              // ignore: invalid_use_of_visible_for_testing_member
              (ref) async => Storage<String, String>.inMemory(),
            ),
            localeProvider.overrideWith(() => _Locale(language)),
            appThemeDataProvider.overrideWithValue(theme),
            appBootstrapReadyProvider.overrideWith((ref) => load()),
            onboardingStateProvider.overrideWith(_PendingOnboarding.new),
            prayerSettingsProvider.overrideWith(_PendingPrayer.new),
            prayerCompletionsRepairProvider.overrideWith((ref) => load()),
            prayerCompletionStoreProvider.overrideWith(_Store.new),
            effectivePrayerSettingsProvider.overrideWithValue(
              PrayerSettings.defaultSettings().copyWith(
                coordinates: Coordinates(24.7136, 46.6753),
              ),
            ),
            appClockProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 10, 3, 9, 12)),
            ),
          ],
        );
        runApp(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: key,
              child: ExcludeSemantics(
                child: owner == 'startup'
                    ? const AppBootstrap()
                    : FTheme(
                        data: theme,
                        child: MaterialApp(
                          debugShowCheckedModeBanner: false,
                          theme: buildAppMaterialTheme(
                            theme,
                            palette: AppPalette.manuscript,
                          ),
                          locale: Locale(language),
                          localizationsDelegates: appLocalizationsDelegates,
                          supportedLocales: AppLocalizations.supportedLocales,
                          home: Scaffold(
                            body: owner == 'analytics'
                                ? const SingleChildScrollView(
                                    child: AnalysisSection(),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: HadithLookupSection(
                                      title: switch (kind) {
                                        HadithLookupKind.scholars =>
                                          l10n.hadithScholars,
                                        HadithLookupKind.books =>
                                          l10n.hadithBooks,
                                        HadithLookupKind.rawi =>
                                          l10n.hadithNarrators,
                                      },
                                      hint: l10n.hadithTypeToSearch,
                                      kind: kind,
                                      selected: (filters) => const [],
                                      withSelected: (filters, items) => filters,
                                    ),
                                  ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (owner.startsWith('lookup-')) {
          FTappable? trigger;
          void findTrigger(Element element) {
            if (element.widget case FTappable tap
                when tap.semanticsExpanded != null)
              trigger = tap;
            element.visitChildren(findTrigger);
          }

          key.currentContext!.visitChildElements(findTrigger);
          trigger!.onPress!();
          await Future<void>.delayed(const Duration(milliseconds: 400));
          await capture('$name-$owner-prompt');
          EditableText? field;
          void findField(Element element) {
            if (element.widget case EditableText text) field = text;
            element.visitChildren(findField);
          }

          key.currentContext!.visitChildElements(findField);
          field!.controller.text = 'اب';
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        await capture('$name-$owner-failure');
        await pressRetry();
        if (attempts != 2)
          throw StateError('Retry did not reach failed $owner fixture');
        await capture('$name-$owner-retry-loading');
        if (owner != 'startup') {
          resume.complete();
          await Future<void>.delayed(const Duration(milliseconds: 900));
          await capture('$name-$owner-recovered');
        }
        runApp(const ProviderScope(child: SizedBox.shrink()));
        await WidgetsBinding.instance.endOfFrame;
        container.dispose();
      }
    }
  }
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  exit(errors.isEmpty ? 0 : 1);
}
