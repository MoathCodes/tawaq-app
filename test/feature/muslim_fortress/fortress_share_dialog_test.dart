// Independent share fixtures do not access the user's data.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_card.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_dialog.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Repository extends Mock implements FortressRepository;

const _dua = FortressDuaItem(
  contentId: 7,
  category: 'Synthetic fixture chapter',
  text: 'Synthetic fixture dhikr body',
  targetCount: 3,
  lines: [HisnPlainLine('Synthetic fixture dhikr body')],
  source: 'Synthetic fixture source',
  virtue: 'Synthetic fixture virtue',
  commentaryFlags: HisnCommentaryFlags(
    hasSharh: true,
    hasHadith: false,
    hasBenefit: false,
  ),
);
const _commentary = HisnCommentary(
  id: 1,
  contentId: 7,
  sharh: 'Synthetic fixture commentary',
  hadith: '',
  benefit: '',
);

Widget _wrap(
  ProviderContainer container,
  Locale locale,
  ThemeMode mode,
  double scale, {
  FortressDuaItem dua = _dua,
}) => UncontrolledProviderScope(
  container: container,
  child: FTheme(
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
      home: Scaffold(
        body: Builder(
          builder: (context) => FButton(
            onPress: () => showFortressShareDialog(context, dua),
            child: const Flexible(child: Text('Open fixture share')),
          ),
        ),
      ),
    ),
  ),
);

Finder _option(FortressShareInclude value) => find.byWidgetPredicate(
  (widget) =>
      widget is FSelectTile<FortressShareInclude> && widget.value == value,
);

void main() {
  testWidgets('Quran share uses Quran typography and offers one repetition', (
    tester,
  ) async {
    const dua = FortressDuaItem(
      contentId: 255,
      category: 'Fixture',
      text: 'Quran typography fixture',
      targetCount: 1,
      lines: [
        HisnQuranLine(
          HisnQuranSingleAyah(
            HisnVerseRange(surah: 2, startAyah: 255, endAyah: 255),
          ),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(container, const Locale('en'), ThemeMode.light, 1, dua: dua),
    );
    await tester.tap(find.text('Open fixture share'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text(dua.text)).style?.fontFamily,
      FontFamily.uthmanicHafs,
    );
    expect(_option(FortressShareInclude.repetition), findsOneWidget);
    expect(find.text('×1'), findsOneWidget);
    await tester.ensureVisible(_option(FortressShareInclude.repetition));
    await tester.tap(_option(FortressShareInclude.repetition));
    await tester.pumpAndSettle();
    expect(find.text('×1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'share card and actions fit narrow large text in both locales and themes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          final container = ProviderContainer();
          await tester.pumpWidget(_wrap(container, locale, mode, 1.6));
          await tester.tap(find.text('Open fixture share'));
          await tester.pumpAndSettle();
          final card = tester.widget<FortressShareCard>(
            find.byType(FortressShareCard),
          );
          expect(card.options.contains(FortressShareInclude.virtue), isTrue);
          expect(find.text(_dua.text), findsOneWidget);
          expect(find.text(_dua.virtue!), findsOneWidget);
          final exception = tester.takeException();
          expect(exception, isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
        }
      }
    },
  );

  for (final missing in [false, true]) {
    testWidgets(
      '${missing ? 'missing' : 'failed'} optional details block export and allow retry or deselection',
      (tester) async {
        final repository = _Repository();
        var attempt = 0;
        when(() => repository.loadCommentaryForContent(7)).thenAnswer((_) {
          if (attempt++ == 0) {
            if (missing) return null;
            throw StateError('Synthetic load failure');
          }
          return _commentary;
        });
        final container = ProviderContainer(
          overrides: [
            fortressRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          _wrap(container, const Locale('en'), ThemeMode.dark, 1),
        );
        await tester.tap(find.text('Open fixture share'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        await tester.tap(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(const Locale('en'));
        expect(find.text(l10n.fortressShareDetailsFailed), findsOneWidget);
        FButton exportButton() => tester.widget<FButton>(
          find.widgetWithText(FButton, l10n.shareCopyImage),
        );
        expect(exportButton().onPress, isNull);
        await tester.ensureVisible(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        await tester.tap(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        expect(exportButton().onPress, isNotNull);
        expect(find.text(l10n.fortressShareDetailsFailed), findsNothing);
        await tester.ensureVisible(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        await tester.tap(_option(FortressShareInclude.sharh));
        await tester.pumpAndSettle();
        // Reselecting after failure retries instead of preserving a dead state.
        expect(find.text(_commentary.sharh), findsOneWidget);
        expect(exportButton().onPress, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'closing during commentary hydration does not update disposed hooks',
    (tester) async {
      final gate = Completer<FortressRepository>();
      final repository = _Repository();
      when(() => repository.loadCommentaryForContent(7))
          .thenReturn(_commentary);
      final container = ProviderContainer(
        overrides: [
          fortressRepositoryProvider.overrideWith((ref) => gate.future),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _wrap(container, const Locale('en'), ThemeMode.light, 1),
      );
      await tester.tap(find.text('Open fixture share'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_option(FortressShareInclude.sharh));
      await tester.pumpAndSettle();
      await tester.tap(_option(FortressShareInclude.sharh));
      await tester.pump();
      await tester.tap(
        find.bySemanticsLabel(lookupAppLocalizations(const Locale('en')).close),
      );
      await tester.pumpAndSettle();
      gate.complete(repository);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      verifyNever(() => repository.loadCommentaryForContent(7));
    },
  );
}
