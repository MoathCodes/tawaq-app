import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_dialog.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const _fixtureText = 'Fixture dhikr text for semantics coverage';
const _fixtureBenefit = 'Fixture benefit content';
const _fixtureHadith = 'Fixture related hadith content';

FortressDuaItem _fixtureDua() => const FortressDuaItem(
  contentId: 7,
  category: 'Fixture category',
  text: _fixtureText,
  targetCount: 3,
  source: 'Fixture source reference',
  lines: [HisnPlainLine(_fixtureText)],
  commentary: HisnCommentary(
    id: 8,
    contentId: 7,
    sharh: '',
    hadith: _fixtureHadith,
    benefit: _fixtureBenefit,
  ),
);

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) {
  return ProviderScope(
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.neutral,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: textScale,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

const _bundledArabicPassage =
    'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets(
      'expanded actions follow logical start in ${locale.languageCode}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 720,
              height: 800,
              child: FortressStudyHost(
                child: FortressDuaPreviewCard(
                  index: 0,
                  dua: _fixtureDua(),
                  isExpanded: true,
                  onToggleExpanded: () {},
                ),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(locale);
        final benefit = tester.getRect(find.text(l10n.fortressBenefit));
        final share = tester.getRect(find.text(l10n.fortressShare));
        expect(
          benefit.center.dx,
          locale.languageCode == 'ar'
              ? greaterThan(share.center.dx)
              : lessThan(share.center.dx),
        );
        final card = tester.getRect(find.byType(FortressDuaPreviewCard));
        final collapse = tester.getRect(find.text(l10n.fortressShowLess));
        expect(
          (locale.languageCode == 'ar'
              ? card.right - collapse.right
              : collapse.left - card.left),
          lessThan(100),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'five study tabs fit complete words at normal and enlarged type',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const dua = FortressDuaItem(
        contentId: 7,
        category: 'Fixture',
        text: 'Fixture',
        targetCount: 1,
        lines: [HisnPlainLine('Fixture')],
        source: 'Fixture source',
        virtue: 'Fixture virtue',
        commentary: HisnCommentary(
          id: 1,
          contentId: 7,
          sharh: 'Fixture sharh',
          hadith: 'Fixture hadith',
          benefit: 'Fixture benefit',
        ),
      );
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        for (final scale in [1.0, 1.3]) {
          await tester.pumpWidget(
            _wrap(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Builder(
                    builder: (context) => SizedBox(
                      width: FortressStudyPanel.minimumTabWidth(
                        context,
                        dua,
                      ).clamp(420, 1200),
                      height: 900,
                      child: FortressStudyPanel(
                        dua: dua,
                        kind: FortressDetailKind.virtue,
                        onKindChanged: (_) {},
                        onClose: () {},
                        bucket: PageStorageBucket(),
                      ),
                    ),
                  ),
                ),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();
          for (final kind in FortressDetailKind.values) {
            final text = kind.label(lookupAppLocalizations(locale));
            final label = find.descendant(
              of: find.byType(FTabs),
              matching: find.text(text),
            );
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: label, matching: find.byType(RichText)).first,
            );
            final painter = TextPainter(
              textScaler: paragraph.textScaler,
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            for (final word in text.split(RegExp(r'\s+'))) {
              painter.text = TextSpan(text: word, style: paragraph.text.style);
              painter.layout();
              expect(
                painter.width,
                lessThanOrEqualTo(paragraph.size.width + .1),
                reason: '$locale $scale: complete word $word must fit',
              );
            }
            painter.dispose();
            expect(paragraph.didExceedMaxLines, isFalse);
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
  testWidgets(
    'persistent sheet tabs replace visible content and outside tap dismisses',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1000,
            height: 800,
            child: FortressStudyHost(
              child: Builder(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: FButton(
                    onPress: () =>
                        showFortressStudySheet(context, _fixtureDua()),
                    child: const Text('Open fixture details'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open fixture details'));
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(
        find.descendant(
          of: find.byType(FTabs),
          matching: find.text(l10n.fortressBenefit),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(_fixtureBenefit, findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fixture source reference', findRichText: true),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(FTabs),
          matching: find.text(l10n.fortressRelatedHadith),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(_fixtureHadith, findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(_fixtureBenefit, findRichText: true),
        findsNothing,
      );
      await tester.tapAt(const Offset(100, 300));
      await tester.pumpAndSettle();
      expect(find.byType(FTabs), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expanded reading surface collapses on short tap but preserves controls and selection drags',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var expanded = true;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 720,
            height: 800,
            child: FortressStudyHost(
              child: StatefulBuilder(
                builder: (context, setState) => FortressDuaPreviewCard(
                  index: 0,
                  dua: _fixtureDua(),
                  isExpanded: expanded,
                  onToggleExpanded: () => setState(() => expanded = !expanded),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text(_fixtureText), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
      await tester.tap(find.textContaining('Fixture source reference'));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
      expect(find.byType(FTabs), findsOneWidget);
      await tester.tapAt(const Offset(100, 700));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_fixtureText));
      await tester.pumpAndSettle();
      expect(expanded, isFalse);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.fortressBenefit), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final duringClose in [false, true]) {
    testWidgets('chapter sheet host safely unmounts (closing: $duringClose)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1000,
            height: 800,
            child: FortressStudyHost(
              child: Builder(
                builder: (context) => FButton(
                  onPress: () => showFortressStudySheet(context, _fixtureDua()),
                  child: const Text('Open fixture details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open fixture details'));
      await tester.pumpAndSettle();
      if (duringClose) {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.tap(find.bySemanticsLabel(l10n.close).last);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'collapsed preview always exposes sourced virtue, not source reference',
    (tester) async {
      const dua = FortressDuaItem(
        contentId: 17,
        category: 'Fixture',
        text: 'Fixture thikr',
        targetCount: 1,
        lines: [HisnPlainLine('Fixture thikr')],
        source: 'Fixture citation',
        virtue: 'Fixture sourced virtue',
      );
      await tester.pumpWidget(
        _wrap(
          FortressDuaPreviewCard(
            index: 0,
            dua: dua,
            isExpanded: false,
            onToggleExpanded: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Fixture sourced virtue', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fixture citation', findRichText: true),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expanded tile reads every line of long prose instead of inheriting title truncation',
    (tester) async {
      final text = List.filled(30, 'Synthetic long thikr fixture.').join(' ');
      final dua = FortressDuaItem(
        contentId: 19,
        category: 'Synthetic category',
        text: text,
        targetCount: 1,
        lines: [HisnPlainLine(text)],
      );
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: FortressDuaPreviewCard(
              index: 0,
              dua: dua,
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
      expect(paragraph.maxLines, isNull);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.height, greaterThan(200));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('collapsed grouped preview shares without expanding the thikr', (
    tester,
  ) async {
    var expanded = false;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => FTileGroup.builder(
            count: 1,
            tileBuilder: (context, _) => FortressDuaPreviewCard(
              index: 0,
              dua: _fixtureDua(),
              isExpanded: expanded,
              onToggleExpanded: () => setState(() => expanded = !expanded),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.tap(find.bySemanticsLabel(l10n.fortressShare));
    await tester.pumpAndSettle();
    expect(find.byType(FortressShareDialog), findsOneWidget);
    expect(expanded, isFalse);
    await tester.tap(find.bySemanticsLabel(l10n.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_fixtureText));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(tester.takeException(), isNull);
  });

  setUpAll(() async {
    final loader = FontLoader(FontFamily.uthmanicHafs)
      ..addFont(
        rootBundle.load(
          'assets/fonts/hafs_tafseerMouaser_v3_fonts/uthmanic_hafs_v20.ttf',
        ),
      );
    await loader.load();
  });

  testWidgets(
    'collapsed preview owns one text-bearing expand button in English and Arabic',
    (tester) async {
      for (final locale in [const Locale('en'), const Locale('ar')]) {
        await tester.pumpWidget(
          _wrap(
            FortressDuaPreviewCard(
              index: 0,
              dua: _fixtureDua(),
              isExpanded: false,
              onToggleExpanded: () {},
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        final l10n = lookupAppLocalizations(locale);
        final label = FortressA11y.previewRowLabel(
          l10n,
          oneBasedIndex: 1,
          isExpanded: false,
          targetCount: 3,
          text: _fixtureText,
        );
        final semantics = tester.getSemantics(find.bySemanticsLabel(label));

        expect(semantics.label, label);
        expect(semantics.flagsCollection.isButton, isTrue);
        expect(semantics.flagsCollection.isExpanded, Tristate.isFalse);
        expect(
          semantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(find.bySemanticsLabel(RegExp(_fixtureText)), findsOneWidget);
      }
    },
  );

  testWidgets(
    'expanded preview exposes bounded details and independent sharing and collapse actions',
    (tester) async {
      for (final locale in [const Locale('en'), const Locale('ar')]) {
        var expanded = false;
        await tester.pumpWidget(
          _wrap(
            StatefulBuilder(
              builder: (context, setState) => FortressDuaPreviewCard(
                index: 0,
                dua: _fixtureDua(),
                isExpanded: expanded,
                onToggleExpanded: () => setState(() => expanded = !expanded),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        final l10n = lookupAppLocalizations(locale);
        final collapsedLabel = FortressA11y.previewRowLabel(
          l10n,
          oneBasedIndex: 1,
          isExpanded: false,
          targetCount: 3,
          text: _fixtureText,
        );

        // The row's keyboard focus is retained while the semantic wrapper
        // owns the collapsed label. Enter must reach the same toggle.
        final tileFocusFinder = find
            .descendant(
              of: find.byType(FTile),
              matching: find.byWidgetPredicate(
                (widget) => widget is Focus && widget.debugLabel == 'FTappable',
              ),
            )
            .first;
        final tileFocusContext = tester.element(
          find
              .descendant(of: tileFocusFinder, matching: find.byType(Semantics))
              .first,
        );
        final tileFocus = Focus.of(tileFocusContext);
        tileFocus.requestFocus();
        await tester.pump();
        expect(tileFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        final expandedLabel = FortressA11y.previewRowLabel(
          l10n,
          oneBasedIndex: 1,
          isExpanded: true,
          targetCount: 3,
        );
        final expandedNode = tester.getSemantics(
          find.bySemanticsLabel(expandedLabel),
        );
        expect(expandedNode.flagsCollection.isExpanded, Tristate.isTrue);

        final thikrSemantics = tester.getSemantics(
          find.bySemanticsLabel(_fixtureText),
        );
        expect(thikrSemantics.label, _fixtureText);
        expect(
          thikrSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );

        expect(find.semantics.byValue(_fixtureBenefit).evaluate(), isEmpty);
        expect(find.text(l10n.fortressBenefit), findsOneWidget);
        expect(find.text(l10n.fortressRelatedHadith), findsOneWidget);
        expect(find.textContaining('Fixture source reference'), findsOneWidget);
        expect(find.text('Fixture source reference'), findsNothing);
        expect(find.text(l10n.fortressSourceReference), findsNothing);
        expect(find.byType(FTabs), findsNothing);
        expect(find.semantics.byValue(_fixtureHadith).evaluate(), isEmpty);

        await tester.tap(find.bySemanticsLabel(l10n.fortressShare));
        await tester.pumpAndSettle();
        expect(find.byType(FortressShareDialog), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(l10n.close));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(expandedLabel), findsOneWidget);
        expect(find.semantics.byValue(_fixtureBenefit).evaluate(), isEmpty);

        final collapseLabel = FortressA11y.previewCollapseLabel(
          l10n,
          oneBasedIndex: 1,
        );
        final collapseSemantics = find.bySemanticsLabel(collapseLabel);
        // The outer semantic owner is the only actionable collapse node;
        // MouseClick remains below it for pointer and keyboard delivery.
        expect(collapseSemantics, findsOneWidget);
        final collapseNode = tester.getSemantics(collapseSemantics);
        expect(collapseNode.label, collapseLabel);
        expect(
          collapseNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          find.semantics
              .byAction(SemanticsAction.tap)
              .evaluate()
              .where((node) => node.label == collapseLabel),
          hasLength(1),
        );
        // The independent collapse button also responds to keyboard input.
        final button = find
            .ancestor(of: collapseSemantics, matching: find.byType(FButton))
            .first;
        final focusFinder = find
            .descendant(
              of: button,
              matching: find.byWidgetPredicate(
                (widget) => widget is Focus && widget.debugLabel == 'FTappable',
              ),
            )
            .first;
        final collapseFocus = Focus.of(
          tester.element(
            find
                .descendant(of: focusFinder, matching: find.byType(Semantics))
                .first,
          ),
        );
        collapseFocus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(collapsedLabel), findsOneWidget);

        // Re-expand via the row semantics, then verify the dedicated semantic
        // collapse action also works after nested content has been visited.
        final collapsedNode = tester.getSemantics(
          find.bySemanticsLabel(collapsedLabel),
        );
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          collapsedNode.id,
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        final reexpandedCollapse = tester.getSemantics(
          find.bySemanticsLabel(collapseLabel),
        );
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          reexpandedCollapse.id,
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(collapsedLabel), findsOneWidget);
      }
    },
  );

  testWidgets(
    'collapsed preview keeps readable source text and explicit expand copy',
    (tester) async {
      const longText =
          'A long sourced dhikr passage that should remain readable in the '
          'collapsed preview while the user decides whether to expand it.';
      const dua = FortressDuaItem(
        contentId: 9,
        category: 'Fixture category',
        text: longText,
        targetCount: 7,
        lines: [HisnPlainLine(longText)],
      );

      await tester.pumpWidget(
        _wrap(
          FortressDuaPreviewCard(
            index: 0,
            dua: dua,
            isExpanded: false,
            onToggleExpanded: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      final preview = tester.widget<Text>(find.text(longText));
      expect(preview.maxLines, 4);
      expect(
        preview.style?.color,
        buildAppTheme(
          palette: AppPalette.neutral,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        ).colors.foreground,
      );
      expect(find.text(l10n.fortressShowMore), findsOneWidget);
      expect(find.text('×7'), findsOneWidget);
    },
  );

  testWidgets(
    'narrow large Arabic preview keeps the footer below sourced prose',
    (tester) async {
      const dua = FortressDuaItem(
        contentId: 255,
        category: 'آية الكرسي',
        text: _bundledArabicPassage,
        targetCount: 1,
        lines: [
          HisnQuranLine(
            HisnQuranSingleAyah(
              HisnVerseRange(surah: 2, startAyah: 255, endAyah: 255),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: FortressDuaPreviewCard(
              index: 0,
              dua: dua,
              isExpanded: false,
              onToggleExpanded: () {},
            ),
          ),
          locale: const Locale('ar'),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final prose = tester.getRect(find.text(_bundledArabicPassage));
      final target = tester.getRect(find.text('×1'));
      expect(prose.height, greaterThan(0));
      expect(target.top, greaterThanOrEqualTo(prose.bottom));
      expect(
        find.text(lookupAppLocalizations(const Locale('ar')).fortressShowMore),
        findsOneWidget,
      );
    },
  );
}
