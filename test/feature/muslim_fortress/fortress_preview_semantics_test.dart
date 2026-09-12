import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/l10n/app_localizations.dart';
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
  lines: [HisnPlainLine(_fixtureText)],
  commentary: HisnCommentary(
    id: 8,
    contentId: 7,
    sharh: '',
    hadith: _fixtureHadith,
    benefit: _fixtureBenefit,
  ),
);

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.neutral,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
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
    'expanded preview exposes content, tabs, and one keyboard-safe collapse action',
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
              .descendant(
                of: tileFocusFinder,
                matching: find.byType(Semantics),
              )
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

        final benefitSemantics = find.semantics
            .byValue(_fixtureBenefit)
            .evaluate()
            .single;
        expect(benefitSemantics.value, _fixtureBenefit);
        expect(
          benefitSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );

        final benefitTab = tester.getSemantics(
          find.bySemanticsLabel(
            RegExp('^${RegExp.escape(l10n.fortressBenefit)}\\n'),
          ),
        );
        final hadithTab = tester.getSemantics(
          find.bySemanticsLabel(
            RegExp('^${RegExp.escape(l10n.fortressRelatedHadith)}\\n'),
          ),
        );
        expect(
          benefitTab.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          benefitTab.getSemanticsData().hasAction(SemanticsAction.focus),
          isTrue,
        );
        expect(
          hadithTab.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          hadithTab.getSemanticsData().hasAction(SemanticsAction.focus),
          isTrue,
        );

        // Activate the tab through its semantic action, not its visual Text.
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          hadithTab.id,
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(expandedLabel), findsOneWidget);
        final hadithSemantics = find.semantics
            .byValue(_fixtureHadith)
            .evaluate()
            .single;
        expect(hadithSemantics.value, _fixtureHadith);
        expect(
          hadithSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );

        // Pointer selection of the nested tab must leave the row expanded.
        await tester.tap(find.text(l10n.fortressBenefit));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(expandedLabel), findsOneWidget);
        expect(
          find.semantics.byValue(_fixtureBenefit).evaluate(),
          hasLength(1),
        );

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
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(collapseLabel))
              .getSemanticsData()
              .hasAction(SemanticsAction.focus),
          isFalse,
        );

        // Space must still reach MouseClick's focusable adapter, even though
        // its duplicate semantics are excluded from the tree.
        final mouseFocusFinder = find
            .descendant(
              of: find.byType(MouseClick),
              matching: find.byWidgetPredicate(
                (widget) => widget is Focus && widget.debugLabel == 'FTappable',
              ),
            )
            .first;
        final mouseFocus = Focus.of(
          tester.element(
            find
                .descendant(
                  of: mouseFocusFinder,
                  matching: find.byType(Semantics),
                )
                .first,
          ),
        );
        mouseFocus.requestFocus();
        await tester.pump();
        expect(mouseFocus.hasFocus, isTrue);
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
}
