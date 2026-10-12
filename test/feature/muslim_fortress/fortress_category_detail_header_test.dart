import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const _category = FortressCategory(
  chapterId: 1,
  title: 'A chapter title long enough to wrap at a narrow desktop width',
  recurrence: HisnRecurrence.daily,
  supplicationCount: 5,
);

Widget _host(double width, {VoidCallback? onStart, VoidCallback? onShare}) {
  return ProviderScope(
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      ),
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: FortressCategoryDetailHeader(
              category: _category,
              duaCount: 5,
              onStartReading: onStart ?? () {},
              onShareChapter: onShare ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final width in [360.0, 720.0]) {
    testWidgets('reading and share are separated and usable at $width', (
      tester,
    ) async {
      var starts = 0;
      var shares = 0;
      await tester.pumpWidget(
        _host(width, onStart: () => starts++, onShare: () => shares++),
      );
      await tester.pumpAndSettle();
      final buttons = find.byType(FButton);
      final start = buttons.at(0);
      final share = buttons.at(1);
      expect(tester.getRect(start).overlaps(tester.getRect(share)), false);
      final a = tester.getRect(start);
      final b = tester.getRect(share);
      final gap = b.top >= a.bottom
          ? b.top - a.bottom
          : a.top >= b.bottom
          ? a.top - b.bottom
          : a.left >= b.right
          ? a.left - b.right
          : b.left - a.right;
      expect(gap, greaterThanOrEqualTo(8));
      await tester.tap(start);
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(shares, 1);
    });
  }

  testWidgets('header keeps one action visible when it wraps at narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(_host(360));
    await tester.pumpAndSettle();

    final title = tester.getBottomLeft(find.text(_category.title));
    final action = tester.getTopLeft(find.text('Start reading'));
    expect(action.dy, greaterThan(title.dy));
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('5 adhkar in this section'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header keeps metadata and action in one compact row when wide', (
    tester,
  ) async {
    await tester.pumpWidget(_host(720));
    await tester.pumpAndSettle();

    expect(find.text('Start reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
