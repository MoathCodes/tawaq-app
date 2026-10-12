// Independent fixture scope isolates the detail destination from persistence.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_reader_text.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
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
  double height = 300,
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
            height: height,
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
  hadithId: 'fixtureoriginal',
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
    readerTrail: [
      HadithReaderEntry(RecordSelection(hadithStableKey(_original))),
    ],
    searchOutcome: const AsyncData(HadithSearchPage(results: [_original])),
  );
}

class _Settings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

void main() {
  testWidgets('Arabic mouse drag keeps the pointer anchor in the reader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const text =
        'نص تجريبي لاختبار تحديد الكلمات العربية في السطر الأول ثم السطر التالي 123.';
    const record = DetailedHadith(
      hadith: text,
      rawi: 'Fixture',
      mohdith: 'Fixture',
      book: 'Fixture',
      numberOrPage: '1',
      grade: 'Fixture',
    );
    await tester.pumpWidget(
      _wrap(
        record,
        key: const ValueKey('mouse-reader'),
        locale: const Locale('ar'),
        height: 1000,
      ),
    );
    await tester.pumpAndSettle();
    final reader = find.byType(HadithReaderText);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: reader, matching: find.byType(RichText)),
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData')
          copied = (call.arguments as Map)['text'] as String;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final area = tester.state<SelectionAreaState>(
      find.descendant(of: reader, matching: find.byType(SelectionArea)),
    );
    for (final offsets in [(5, 20), (20, 5), (12, 48)]) {
      Offset point(int offset) => paragraph.localToGlobal(
        paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero) +
            const Offset(0, 14),
      );
      final start = point(offsets.$1);
      final end = point(offsets.$2);
      final expectedStart = paragraph
          .getPositionForOffset(paragraph.globalToLocal(start))
          .offset;
      final expectedEnd = paragraph
          .getPositionForOffset(paragraph.globalToLocal(end))
          .offset;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: start);
      await mouse.down(start);
      await tester.pump(const Duration(milliseconds: 100));
      for (var step = 1; step <= 10; step++) {
        await mouse.moveTo(Offset.lerp(start, end, step / 10)!);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await mouse.up();
      await tester.pump();
      area.selectableRegion.copySelection(SelectionChangedCause.toolbar);
      await tester.pump();
      expect(
        copied,
        text.substring(
          expectedStart < expectedEnd ? expectedStart : expectedEnd,
          expectedStart > expectedEnd ? expectedStart : expectedEnd,
        ),
      );
      await mouse.removePointer();
      await tester.pump(const Duration(seconds: 1));
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('alternate card opens its own selected detail destination', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hadithSessionControllerProvider.overrideWith(_Session.new),
        hadithScreenSettingsProvider.overrideWith(_Settings.new),
        hadithFavoritesProvider.overrideWith((ref) async => []),
        hadithRelatedProvider(
          HadithRecordId('fixtureoriginal'),
          RelatedHadithKind.alternate,
        ).overrideWith(
          (ref) async => const ApiResponse(
            data: RelatedHadithResult(
              requestedId: 'fixtureoriginal',
              source: null,
              kind: RelatedHadithKind.alternate,
              related: [_alternate],
            ),
            metadata: SearchMetadata(),
          ),
        ),
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
    expect(session.mode, HadithViewMode.search);
    expect(session.readerTrail.length, 2);
    expect(session.query, 'Fixture search');
    expect(session.results, [_original]);
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
