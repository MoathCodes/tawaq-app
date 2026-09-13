import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

final String _longText = List.filled(60, 'Fixture hadith text. ').join();

DetailedHadith _hadith({required String suffix}) => DetailedHadith(
  hadith: '$_longText$suffix',
  rawi: 'Fixture narrator',
  mohdith: 'Fixture scholar',
  book: 'Fixture source $suffix',
  numberOrPage: 'Fixture reference $suffix',
  grade: 'Fixture grade',
);

Widget _wrap(
  DetailedHadith hadith, {
  required Key key,
  int? resultOrdinal,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 300,
            child: HadithSelectedDetailsPane(
              key: key,
              hadith: hadith,
              resultOrdinal: resultOrdinal,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'same stable result preserves detail scroll while a new result resets it',
    (tester) async {
      final first = _hadith(suffix: 'one');
      final replacement = _hadith(suffix: 'two');

      await tester.pumpWidget(
        _wrap(first, resultOrdinal: 1, key: ValueKey(hadithStableKey(first))),
      );
      await tester.pumpAndSettle();

      final scrollFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollFinder, const Offset(0, -180));
      await tester.pumpAndSettle();
      final firstOffset = tester
          .widget<SingleChildScrollView>(scrollFinder)
          .controller!
          .offset;
      expect(firstOffset, greaterThan(0));

      await tester.pumpWidget(
        _wrap(
          first,
          resultOrdinal: 1,
          key: ValueKey(hadithStableKey(first)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SingleChildScrollView>(scrollFinder).controller!.offset,
        closeTo(firstOffset, 0.01),
      );

      await tester.drag(scrollFinder, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SingleChildScrollView>(scrollFinder).controller!.offset,
        greaterThan(0),
      );

      await tester.pumpWidget(
        _wrap(
          replacement,
          resultOrdinal: 2,
          key: ValueKey(hadithStableKey(replacement)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selected result 2'), findsOneWidget);
      expect(find.text('Selected result 1'), findsNothing);
      expect(
        tester.widget<SingleChildScrollView>(scrollFinder).controller!.offset,
        closeTo(0, 0.01),
      );
    },
  );

  testWidgets(
    'detail keeps honest selected identity when no page ordinal exists',
    (
      tester,
    ) async {
      final hadith = _hadith(suffix: 'outside page');

      await tester.pumpWidget(
        _wrap(
          hadith,
          key: ValueKey(hadithStableKey(hadith)),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الحديث المحدد'), findsOneWidget);
      expect(
        find.text(
          'Fixture source outside page (Fixture reference outside page)',
        ),
        findsNWidgets(2),
      );
    },
  );
}
