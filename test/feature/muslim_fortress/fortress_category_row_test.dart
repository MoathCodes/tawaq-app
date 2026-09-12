import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_category_row.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

FThemeData _theme(ThemeMode mode) => buildAppTheme(
  palette: AppPalette.manuscript,
  themeMode: mode,
  touch: false,
  textScale: 1,
);

Widget _host({required Widget child, required FThemeData theme}) => FTheme(
  data: theme,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'selected and unselected recurrence labels remain readable in '
      '${mode.name} Manuscript theme',
      (tester) async {
        final theme = _theme(mode);
        final colors = theme.colors;
        const category = FortressCategory(
          chapterId: 1,
          title: 'Morning remembrance',
          recurrence: HisnRecurrence.daily,
          supplicationCount: 4,
        );
        final l10n = AppLocalizationsEn();

        await tester.pumpWidget(
          _host(
            theme: theme,
            child: ColoredBox(
              color: colors.background,
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: FortressCategoryRow(
                        category: category,
                        l10n: l10n,
                        selected: true,
                      ),
                    ),
                  ),
                  FortressCategoryRow(category: category, l10n: l10n),
                ],
              ),
            ),
          ),
        );

        final recurrenceLabels = tester
            .widgetList<Text>(find.text(l10n.daily))
            .toList();
        expect(recurrenceLabels, hasLength(2));
        expect(recurrenceLabels[0].style?.color, colors.primary);
        expect(recurrenceLabels[1].style?.color, colors.mutedForeground);

        // Mirror FortressCategoryListTile's selected fill over the actual
        // sidebar surface, then check the resolved text/surface pair.
        final selectedSurface = Color.alphaBlend(
          colors.primary.withAlpha(20),
          colors.background,
        );
        expect(
          _contrastRatio(colors.primary, selectedSurface),
          greaterThanOrEqualTo(4.5),
          reason: 'selected recurrence label should remain normal text',
        );
        expect(
          _contrastRatio(colors.mutedForeground, colors.background),
          greaterThanOrEqualTo(4.5),
          reason: 'unselected recurrence label should remain normal text',
        );
      },
    );
  }
}
