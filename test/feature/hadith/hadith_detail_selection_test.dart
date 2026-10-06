// Independent fixture scope isolates the detail destination from persistence.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
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
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 300,
            child: HadithSelectedDetailsPane(key: key, hadith: hadith),
          ),
        ),
      ),
    ),
  );
}

const _original = DetailedHadith(
  hadith: 'Synthetic original UI fixture',
  rawi: 'Fixture narrator',
  mohdith: 'Fixture scholar',
  book: 'Fixture book',
  numberOrPage: '1',
  grade: 'Synthetic judgment',
  hadithId: 'fixture-original',
  hasAlternateHadithSahih: true,
);
const _alternate = DetailedHadith(
  hadith: 'Synthetic alternate UI fixture',
  rawi: 'Fixture alternate narrator',
  mohdith: 'Fixture alternate scholar',
  book: 'Fixture alternate book',
  numberOrPage: '2',
  grade: 'Synthetic alternate judgment',
  hadithId: 'fixture-alternate',
);

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() => HadithSessionState(
    query: 'Fixture search',
    selectedHadithKey: hadithStableKey(_original),
    searchOutcome: const AsyncData(HadithSearchPage(results: [_original])),
  );
}

class _Settings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

void main() {
  testWidgets('alternate card opens its own selected detail destination', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hadithSessionControllerProvider.overrideWith(_Session.new),
        hadithScreenSettingsProvider.overrideWith(_Settings.new),
        hadithFavoritesProvider.overrideWith((ref) async => []),
        hadithDetailProvider(
          HadithDetailKind.alternate,
          'fixture-original',
        ).overrideWith((ref) async => _alternate),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FTheme(
          data: buildAppTheme(
            palette: AppPalette.manuscript,
            themeMode: ThemeMode.dark,
            touch: false,
            textScale: 1,
          ),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final selected = ref.watch(selectedHadithProvider);
                  return selected == null
                      ? const Text('Missing selected detail')
                      : HadithSelectedDetailsPane(hadith: selected);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.tap(find.text(l10n.hadithAlternateHadithSahih));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(_alternate.hadith));
    await tester.tap(find.text(_alternate.hadith));
    await tester.pumpAndSettle();
    expect(container.read(selectedHadithProvider), _alternate);
    final session = container.read(hadithSessionControllerProvider);
    expect(session.mode, HadithViewMode.specificList);
    expect(session.specificHadiths, [_alternate]);
    expect(session.searchSnapshot!.query, 'Fixture search');
    expect(find.text('Missing selected detail'), findsNothing);
    expect(find.text(_alternate.hadith), findsOneWidget);
    expect(find.text(_alternate.hukm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'same stable result preserves detail scroll while a new result resets it',
    (tester) async {
      final first = _hadith(suffix: 'one');
      final replacement = _hadith(suffix: 'two');

      await tester.pumpWidget(
        _wrap(first, key: ValueKey(hadithStableKey(first))),
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
        _wrap(first, key: ValueKey(hadithStableKey(first))),
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
        _wrap(replacement, key: ValueKey(hadithStableKey(replacement))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selected result 2'), findsNothing);
      expect(find.text('Selected result 1'), findsNothing);
      expect(find.text(replacement.hadith), findsOneWidget);
      expect(
        tester.widget<SingleChildScrollView>(scrollFinder).controller!.offset,
        closeTo(0, 0.01),
      );
    },
  );

  testWidgets(
    'detail omits selected-result heading and repeated source citation',
    (tester) async {
      final hadith = _hadith(suffix: 'outside page');

      await tester.pumpWidget(
        _wrap(
          hadith,
          key: ValueKey(hadithStableKey(hadith)),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الحديث المحدد'), findsNothing);
      expect(
        find.text(
          'Fixture source outside page (Fixture reference outside page)',
        ),
        findsOneWidget,
      );
    },
  );
}
