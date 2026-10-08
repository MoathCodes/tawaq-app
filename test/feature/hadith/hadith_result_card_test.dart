// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:ui' as ui;

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_source_ruling.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

// These strings are deliberately synthetic UI fixtures. They exercise
// qualified, negated, and unavailable source wording without making a
// religious claim or standing in for repository content.
const _negatedFixture = 'Fixture judgment: ليس بصحيح في هذا السياق';
const _qualifiedFixture = 'Fixture judgment: حسن مع قيد المصدر';
const _unknownFixture = 'Fixture unknown judgment: source wording unavailable';
const _longJudgmentFixture =
    'Fixture judgment: qualified source wording preserved across a narrow '
    'card at large text size; this continuation is intentionally synthetic '
    'and long enough to require several wrapped lines.';

Widget _wrap(
  Widget child, {
  required ThemeMode themeMode,
  AppPalette palette = AppPalette.manuscript,
}) {
  return FTheme(
    data: buildAppTheme(
      palette: palette,
      themeMode: themeMode,
      touch: false,
      textScale: 1,
    ),
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

DetailedHadith _fixtureHadith(String judgment) => DetailedHadith(
  hadith: 'Fixture hadith body',
  rawi: 'Fixture narrator',
  mohdith: 'Fixture scholar',
  book: 'Fixture source',
  numberOrPage: 'Fixture reference',
  grade: judgment,
);

Widget _wrapCard(
  Widget child, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
}) {
  return ProviderScope(
    // The complete card watches favorites during build. Keep this visual
    // fixture independent of the real Hive-backed repository and user data.
    overrides: [hadithFavoritesProvider.overrideWith((ref) async => const [])],
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: themeMode,
        touch: false,
        textScale: textScale,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(child: SizedBox(width: 280, child: child)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'every SDK tone is legible on its actual surface in every palette',
    (tester) async {
      for (final palette in AppPalette.values) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          for (final tone in VerdictTone.values) {
            await tester.pumpWidget(
              _wrap(
                HadithSourceRuling(hukm: 'Synthetic source ruling', tone: tone),
                themeMode: mode,
                palette: palette,
              ),
            );
            await tester.pumpAndSettle();
            final text = tester.widget<Text>(
              find.text('Synthetic source ruling'),
            );
            final surface = tester.widget<Container>(
              find.byKey(ValueKey('hadith-ruling-${tone.name}')),
            );
            final background = (surface.decoration! as BoxDecoration).color!;
            final a = text.style!.color!.computeLuminance();
            final b = background.computeLuminance();
            expect(
              ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05),
              greaterThanOrEqualTo(4.5),
              reason: '${palette.name} ${mode.name} ${tone.name}',
            );
            expect(
              find.byIcon(FLucideIcons.circleCheck),
              tone == VerdictTone.positive ? findsOneWidget : findsNothing,
            );
            expect(
              find.byIcon(FLucideIcons.triangleAlert),
              tone == VerdictTone.negative ? findsOneWidget : findsNothing,
            );
          }
        }
      }
    },
  );

  testWidgets('long source category remains reachable from compact card menu', (
    tester,
  ) async {
    final hadith = _fixtureHadith(_unknownFixture).copyWith(
      categories: const [
        HadithCategory(
          id: 'fixture',
          name: 'Synthetic category label with enough source wording to wrap repeatedly in a compact result card',
        ),
      ],
    );
    await tester.pumpWidget(
      _wrapCard(
        HadithResultCard(hadith: hadith),
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(hadith.categories.single.name), findsNothing);
    final trigger = find.text(
      lookupAppLocalizations(const Locale('en')).hadithTopics,
    );
    await tester.ensureVisible(trigger);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.text(hadith.categories.single.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'footer copy preserves complete source judgment without selecting the result',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData')
            clipboard = (call.arguments as Map)['text'] as String;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var selected = false;
      final hadith = _fixtureHadith(_longJudgmentFixture);
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        _wrapCard(
          HadithResultCard(
            hadith: hadith,
            isFavorite: false,
            isSelected: false,
            onSelect: () => selected = true,
          ),
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          textScale: 1,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel(l10n.menuCopyText));
      await tester.tap(find.bySemanticsLabel(l10n.menuCopyText));
      await tester.pumpAndSettle();
      expect(clipboard, contains(hadith.hadith));
      expect(clipboard, contains(hadith.hukm));
      expect(clipboard, contains(hadith.book));
      expect(selected, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search highlights keep source text and readable contrast across themes',
    (tester) async {
      for (final palette in AppPalette.values) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          final theme = buildAppTheme(
            palette: palette,
            themeMode: mode,
            touch: false,
            textScale: 1,
          );
          const source = 'إِنَّما fixture إِنَّما';
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                hadithFavoritesProvider.overrideWith((ref) async => const []),
              ],
              child: _wrap(
                HadithResultCard(
                  hadith: _fixtureHadith('fixture').copyWith(hadith: source),
                  query: 'انما',
                  isFavorite: false,
                  isSelected: false,
                  onSelect: () {},
                ),
                themeMode: mode,
                palette: palette,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final rich = tester
              .widgetList<RichText>(find.byType(RichText))
              .firstWhere((w) => w.text.toPlainText().contains(source));
          final matches = <TextSpan>[];
          void visit(InlineSpan span) {
            if (span is TextSpan) {
              if (span.style?.backgroundColor != null) matches.add(span);
              for (final child in span.children ?? <InlineSpan>[]) {
                visit(child);
              }
            }
          }

          visit(rich.text);
          expect(matches, hasLength(2));
          for (final span in matches) {
            expect(span.text, 'إِنَّما');
            expect(span.style!.backgroundColor, isNot(theme.colors.secondary));
            final a = span.style!.color!.computeLuminance();
            final b = span.style!.backgroundColor!.computeLuminance();
            expect(
              ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'judgment badge keeps full qualified wording and neutral contrast in both themes',
    (tester) async {
      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        final theme = buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: themeMode,
          touch: false,
          textScale: 1,
        );

        for (final judgment in [
          _negatedFixture,
          _qualifiedFixture,
          _unknownFixture,
        ]) {
          await tester.pumpWidget(
            _wrap(HadithSourceRuling(hukm: judgment), themeMode: themeMode),
          );
          await tester.pumpAndSettle();

          final text = tester.widget<Text>(find.text(judgment));
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
          expect(text.style?.color, theme.colors.foreground);

          final semantics = tester.getSemantics(find.text(judgment));
          expect(semantics.label, judgment);
        }
      }
    },
  );

  testWidgets(
    'SDK negative tone keeps exact text, contrast and warning icon across palettes',
    (tester) async {
      for (final palette in [
        AppPalette.manuscript,
        AppPalette.sage,
        AppPalette.neutral,
      ]) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          final theme = buildAppTheme(
            palette: palette,
            themeMode: mode,
            touch: false,
            textScale: 1,
          );
          for (final judgment in ['ضعيف', 'فيه أبو داود النخعي كذاب']) {
            await tester.pumpWidget(
              _wrap(
                HadithSourceRuling(hukm: judgment, tone: VerdictTone.negative),
                themeMode: mode,
                palette: palette,
              ),
            );
            await tester.pumpAndSettle();
            final text = tester.widget<Text>(find.text(judgment));
            expect(
              HSLColor.fromColor(text.style!.color!).hue,
              closeTo(HSLColor.fromColor(theme.colors.destructive).hue, 1),
            );
            expect(text.maxLines, isNull);
            expect(find.byIcon(FLucideIcons.triangleAlert), findsOneWidget);
            final a = text.style!.color!.computeLuminance();
            final b = theme.colors.card.computeLuminance();
            expect(
              ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
      }
    },
  );

  test('missing narrator is omitted from result semantics too', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final label = hadithResultRowSemanticsLabel(
      _fixtureHadith(_qualifiedFixture).copyWith(rawi: '-'),
      l10n,
      isFavorite: false,
      isSelected: false,
    );
    expect(label, isNot(contains(l10n.hadithNarrator)));
    expect(label, contains(_qualifiedFixture));
  });

  test('result-row semantics preserves the complete source judgment', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final hadith = _fixtureHadith(_qualifiedFixture);

    final label = hadithResultRowSemanticsLabel(
      hadith,
      l10n,
      isFavorite: false,
      isSelected: false,
    );

    expect(label, contains(_qualifiedFixture));
    expect(label, endsWith(_qualifiedFixture));
  });

  testWidgets(
    'source appears once without a numbered heading while selection stays accessible',
    (tester) async {
      final hadith = _fixtureHadith(_qualifiedFixture);
      final l10n = lookupAppLocalizations(const Locale('en'));
      final rowLabel = hadithResultRowSemanticsLabel(
        hadith,
        l10n,
        isFavorite: false,
        isSelected: true,
        resultOrdinal: 2,
      );

      await tester.pumpWidget(
        _wrapCard(
          HadithResultCard(
            hadith: hadith,
            resultOrdinal: 2,
            isFavorite: false,
            isSelected: true,
            onSelect: () {},
            showFavoriteAction: false,
          ),
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
          textScale: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Result 2'), findsNothing);
      expect(
        find.textContaining(
          'Fixture source (Fixture reference)',
          findRichText: true,
        ),
        findsOneWidget,
      );
      final semantics = tester.getSemantics(find.bySemanticsLabel(rowLabel));
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    },
  );

  testWidgets('hover stays flat and selected borders remain uniform', (
    tester,
  ) async {
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        for (final selected in [false, true]) {
          await mouse.moveTo(Offset.zero);
          await tester.pumpWidget(
            _wrapCard(
              HadithResultCard(
                hadith: _fixtureHadith(_qualifiedFixture),
                isFavorite: false,
                isSelected: selected,
                onSelect: () {},
                showFavoriteAction: false,
              ),
              themeMode: mode,
              locale: locale,
              textScale: 1.6,
            ),
          );
          await tester.pumpAndSettle();
          final surface = find
              .descendant(
                of: find.byType(HadithResultCard).first,
                matching: find.byType(Container),
              )
              .first;
          BoxDecoration decoration() =>
              tester.widget<Container>(surface).decoration! as BoxDecoration;
          final before = decoration();
          await mouse.moveTo(tester.getCenter(find.byType(MouseClick).first));
          await tester.pumpAndSettle();
          final after = decoration();
          expect(before.boxShadow, isNull);
          expect(after.boxShadow, isNull);
          expect(after.border!.isUniform, isTrue);
          expect(after.border!.top.width, 1);
          if (selected) {
            expect(after.color, before.color);
            expect(after.border, before.border);
          } else {
            expect(after.color, isNot(before.color));
          }
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets(
    'keyboard selection and visible actions stay independently reachable',
    (tester) async {
      final hadith = _fixtureHadith(_qualifiedFixture);
      var selected = false;
      var favorited = false;
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        _wrapCard(
          Focus(
            autofocus: true,
            child: HadithResultCard(
              hadith: hadith,
              isFavorite: false,
              isSelected: false,
              onSelect: () => selected = true,
              onToggleFavorite: () => favorited = true,
            ),
          ),
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
          textScale: 1,
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selected, isTrue);

      // Footer order is Share, Copy text, then Bookmark.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(favorited, isTrue);

      await tester.tap(find.bySemanticsLabel(l10n.hadithShare));
      await tester.pumpAndSettle();
      expect(find.byType(HadithShareDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HadithShareDialog),
          matching: find.text(l10n.menuCopyText),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.menuOpen), findsNothing);

      await tester.tap(find.bySemanticsLabel(l10n.close));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _wrapCard(
          HadithResultCard(
            hadith: hadith,
            isFavorite: false,
            isSelected: false,
            onSelect: () {},
            showFavoriteAction: false,
          ),
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
          textScale: 1,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.hadithShare));
      await tester.pumpAndSettle();
      expect(find.byType(HadithShareDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HadithShareDialog),
          matching: find.text(l10n.menuCopyText),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.menuOpen), findsNothing);
      expect(find.text(l10n.menuAddBookmark), findsNothing);
    },
  );

  testWidgets(
    'complete result card wraps long judgments at narrow large text in both themes',
    (tester) async {
      final hadith = _fixtureHadith(_longJudgmentFixture);

      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        final theme = buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: themeMode,
          touch: false,
          textScale: 1.6,
        );
        for (final locale in [const Locale('en'), const Locale('ar')]) {
          final l10n = lookupAppLocalizations(locale);
          final rowLabel = hadithResultRowSemanticsLabel(
            hadith,
            l10n,
            isFavorite: false,
            isSelected: false,
          );

          await tester.pumpWidget(
            _wrapCard(
              HadithResultCard(
                hadith: hadith,
                isFavorite: false,
                isSelected: false,
                onSelect: () {},
                showFavoriteAction: false,
              ),
              themeMode: themeMode,
              locale: locale,
              textScale: 1.6,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final judgmentText = tester.widget<Text>(
            find.text(_longJudgmentFixture),
          );
          expect(judgmentText.maxLines, isNull);
          expect(judgmentText.overflow, isNull);
          expect(
            tester.getSemantics(find.bySemanticsLabel(rowLabel)).label,
            contains(_longJudgmentFixture),
          );

          final cardRect = tester.getRect(find.bySemanticsLabel(rowLabel));
          final judgmentRect = tester.getRect(find.text(_longJudgmentFixture));
          expect(judgmentRect.left, greaterThanOrEqualTo(cardRect.left));
          expect(judgmentRect.right, lessThanOrEqualTo(cardRect.right));
          expect(
            judgmentRect.height,
            greaterThan(theme.typography.body.sm.fontSize! * 3),
          );
        }
      }
    },
  );
}
