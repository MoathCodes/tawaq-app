import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

// These strings are deliberately synthetic UI fixtures. They exercise
// qualified, negated, and unavailable source wording without making a
// religious claim or standing in for repository content.
const _negatedFixture = 'Fixture judgment: ليس بصحيح في هذا السياق';
const _qualifiedFixture = 'Fixture judgment: حسن مع قيد المصدر';
const _unknownFixture = 'Fixture unknown judgment: source wording unavailable';

Widget _wrap(Widget child, {required ThemeMode themeMode}) {
  return FTheme(
    data: buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: themeMode,
      touch: false,
      textScale: 1,
    ),
    child: MaterialApp(home: Scaffold(body: child)),
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

void main() {
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
            _wrap(HadithHukmBadge(hukm: judgment), themeMode: themeMode),
          );
          await tester.pumpAndSettle();

          final text = tester.widget<Text>(find.text(judgment));
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
          expect(text.style?.color, theme.colors.foreground);

          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.color, theme.colors.card);
          expect(decoration.border!.top.color, theme.colors.border);

          final semantics = tester.getSemantics(find.text(judgment));
          expect(semantics.label, judgment);
        }
      }
    },
  );

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
}
