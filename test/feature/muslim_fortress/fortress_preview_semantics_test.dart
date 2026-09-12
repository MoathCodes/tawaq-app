import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
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
    'expanded preview exposes study tabs and a separate collapse action',
    (tester) async {
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
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      final collapsedLabel = FortressA11y.previewRowLabel(
        l10n,
        oneBasedIndex: 1,
        isExpanded: false,
        targetCount: 3,
        text: _fixtureText,
      );
      final collapsedNode = tester.getSemantics(
        find.bySemanticsLabel(collapsedLabel),
      );
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        collapsedNode.id,
        SemanticsAction.tap,
      );
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
      expect(
        tester
            .widgetList<ScopedSelectableRichText>(
              find.byType(ScopedSelectableRichText),
            )
            .map((widget) => widget.textSpan.toPlainText()),
        contains(_fixtureBenefit),
      );
      expect(find.byType(FTabs), findsOneWidget);

      // A nested study-tab activation must not collapse the expanded row.
      await tester.tap(find.text(l10n.fortressRelatedHadith));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(expandedLabel), findsOneWidget);
      expect(
        tester
            .widgetList<ScopedSelectableRichText>(
              find.byType(ScopedSelectableRichText),
            )
            .map((widget) => widget.textSpan.toPlainText()),
        contains(_fixtureHadith),
      );

      final collapseLabel = FortressA11y.previewCollapseLabel(
        l10n,
        oneBasedIndex: 1,
      );
      final collapseSemantics = find.bySemanticsLabel(collapseLabel);
      expect(collapseSemantics, findsOneWidget);
      final collapseNode = tester.getSemantics(collapseSemantics);
      expect(collapseNode.label, collapseLabel);
      expect(
        collapseNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        collapseNode.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(collapsedLabel), findsOneWidget);
    },
  );
}
