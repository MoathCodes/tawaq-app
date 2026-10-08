// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

import 'hadith_judgment_test.dart' show fixture;

Widget wrap(
  Widget child,
  Locale locale,
  ThemeMode mode,
  double scale, {
  ProviderContainer? container,
}) {
  final content = FTheme(
    data: buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: mode,
      touch: false,
      textScale: scale,
    ),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FToaster(child: child!),
      home: Scaffold(body: child),
    ),
  );
  return container == null
      ? ProviderScope(child: content)
      : UncontrolledProviderScope(container: container, child: content);
}

void main() {
  testWidgets(
    'all export options keep one primary citation and distinct source qualifications',
    (tester) async {
      const record = DetailedHadith(
        hadithId: 'fixture',
        hadith: 'Synthetic narration',
        rawi: 'Primary narrator',
        mohdith: 'Primary scholar',
        book: 'Primary source',
        numberOrPage: '42',
        grade: 'Primary source ruling',
        verdictTone: VerdictTone.positive,
        takhrij: 'Synthetic takhrij',
      );
      final related = record.copyWith(
        mohdith: 'Related scholar',
        book: 'Related source',
        grade: 'Distinct qualified ruling',
      );
      final explanation = Sharh(
        hadith: record,
        embeddedHadith: related,
        sharhMetadata: const SharhMetadata(
          id: '1',
          sharh: 'Synthetic commentary.',
        ),
      );
      final origins = UsulHadith(
        hadith: record,
        sources: const [
          UsulSource(
            source: 'Synthetic origin source (1)',
            chain: 'Synthetic chain.',
            hadithText: 'Synthetic narration',
          ),
        ],
        count: 1,
      );
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: HadithShareCard(
              boundaryKey: GlobalKey(),
              hadith: record,
              options: HadithShareOptions(HadithShareInclude.values.toSet()),
              sharh: explanation,
              usul: origins,
            ),
          ),
          const Locale('en'),
          ThemeMode.dark,
          1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic narration'), findsOneWidget);
      expect(
        find.textContaining('Primary source', findRichText: true),
        findsNWidgets(2),
      ); // one ruling and one citation
      expect(
        find.textContaining('Related source', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Distinct qualified ruling', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Synthetic commentary.'), findsOneWidget);
      expect(find.text('Synthetic chain.'), findsOneWidget);
      expect(
        find.text(
          lookupAppLocalizations(const Locale('en')).hadithScholarRuling,
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.text('Primary source ruling')).style!.fontSize,
        20,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct card cannot hide negative ruling or show empty narrator',
    (tester) async {
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        await tester.pumpWidget(
          wrap(
            SingleChildScrollView(
              child: HadithShareCard(
                boundaryKey: GlobalKey(),
                hadith: fixture,
                options: const HadithShareOptions({
                  HadithShareInclude.narrator,
                }),
              ),
            ),
            locale,
            ThemeMode.dark,
            1.6,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(fixture.hukm), findsOneWidget);
        expect(find.text('-'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'share option is checked and disabled, placeholder options absent, clipboard keeps hukm',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => FButton(
              onPress: () => showHadithShareDialog(context, fixture),
              child: const Text('share'),
            ),
          ),
          const Locale('ar'),
          ThemeMode.dark,
          1,
        ),
      );
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      final tile = tester.widget<FSelectTile<HadithShareInclude>>(
        find.byWidgetPredicate(
          (w) =>
              w is FSelectTile<HadithShareInclude> &&
              w.value == HadithShareInclude.grade,
        ),
      );
      expect(tile.enabled, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is FSelectTile<HadithShareInclude> &&
              w.value == HadithShareInclude.narrator,
        ),
        findsNothing,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));
      await tester.tap(find.text(l10n.menuCopyText));
      await tester.pumpAndSettle();
      expect(clipboard, contains(fixture.hukm));
      expect(clipboard, startsWith(fixture.hadith));
      expect(clipboard, isNot(contains(l10n.hadithNarrator)));
    },
  );
  testWidgets(
    'selected optional-detail failure blocks export and recovers on retry or deselection',
    (tester) async {
      final hadith = fixture.copyWith(
        hasSharhMetadata: true,
        sharhMetadata: const SharhMetadata(id: '3', isContainSharh: false),
      );
      var calls = 0;
      var fail = true;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          hadithSharhProvider(SharhId('3')).overrideWith((ref) async {
            calls++;
            if (fail) throw StateError('Synthetic network failure');
            return const Sharh(
              hadith: DetailedHadith(
                hadith: 'Synthetic fixture',
                rawi: '-',
                mohdith: 'Fixture scholar',
                book: 'Fixture book',
                numberOrPage: '151',
                grade: 'Fixture judgment',
              ),
              sharhMetadata: SharhMetadata(
                id: '3',
                isContainSharh: true,
                sharh: 'Synthetic commentary fixture',
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => FButton(
              onPress: () => showHadithShareDialog(context, hadith),
              child: const Text('share'),
            ),
          ),
          const Locale('en'),
          ThemeMode.light,
          1,
          container: container,
        ),
      );
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      final sharhOption = find.byWidgetPredicate(
        (w) =>
            w is FSelectTile<HadithShareInclude> &&
            w.value == HadithShareInclude.sharh,
      );
      await tester.ensureVisible(sharhOption);
      await tester.tap(sharhOption);
      await tester.pumpAndSettle();
      final failure = l10n.hadithShareDetailsFailed(l10n.hadithSharh);
      expect(find.text(failure), findsOneWidget);
      FButton saveButton() => tester.widget<FButton>(
        find.ancestor(
          of: find.text(l10n.shareSaveImage),
          matching: find.byType(FButton),
        ),
      );
      expect(saveButton().onPress, isNull);
      expect(calls, 1);
      fail = false;
      await tester.tap(find.text(l10n.retryAction));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text(failure), findsNothing);
      expect(find.text('Synthetic commentary fixture'), findsOneWidget);
      expect(saveButton().onPress, isNotNull);
      fail = true;
      container.invalidate(hadithSharhProvider(SharhId('3')));
      await tester.pumpAndSettle();
      expect(saveButton().onPress, isNull);
      await tester.ensureVisible(sharhOption);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is FSelectTile<HadithShareInclude> &&
              w.value == HadithShareInclude.sharh,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(failure), findsNothing);
      expect(saveButton().onPress, isNotNull);
    },
  );

  testWidgets(
    'dialog wraps at shipped minimum size and large text across locales and themes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            wrap(
              Builder(
                builder: (context) => FButton(
                  onPress: () => showHadithShareDialog(context, fixture),
                  child: const Text('share'),
                ),
              ),
              locale,
              mode,
              1.6,
            ),
          );
          await tester.tap(find.text('share'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(fixture.hukm), findsOneWidget);
          await tester.tap(
            find.bySemanticsLabel(lookupAppLocalizations(locale).close),
          );
          await tester.pumpAndSettle();
        }
      }
    },
  );
}
