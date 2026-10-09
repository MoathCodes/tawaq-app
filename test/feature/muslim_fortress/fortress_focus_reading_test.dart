import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const category = FortressCategory(
  chapterId: 1,
  title: 'Synthetic fixture chapter',
  recurrence: HisnRecurrence.daily,
  supplicationCount: 2,
);
const items = [
  FortressDuaItem(
    contentId: 1,
    category: 'Fixture',
    text: 'Synthetic first reading',
    targetCount: 1,
    lines: [HisnPlainLine('Synthetic first reading')],
    source: 'Synthetic source',
    virtue: 'Synthetic virtue encouragement',
  ),
  FortressDuaItem(
    contentId: 2,
    category: 'Fixture',
    text: 'Synthetic second reading',
    targetCount: 3,
    lines: [HisnPlainLine('Synthetic second reading')],
    source: 'Synthetic second source',
  ),
];
Widget wrap({
  double scale = 1,
  Locale locale = const Locale('en'),
  ThemeMode mode = ThemeMode.dark,
  VoidCallback? exit,
}) => ProviderScope(
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FTheme(
      data: buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: mode,
        touch: false,
        textScale: 1,
      ),
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: FortressFocusReadingSurface(
          category: category,
          duas: items,
          onExit: exit ?? () {},
        ),
      ),
    ),
  ),
);
void main() {
  testWidgets('final repetition advances once and returning retains counts', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fortress-counter')));
    await tester.pump(const Duration(milliseconds: 599));
    expect(find.text(items.first.text), findsOneWidget);
    expect(find.byKey(const ValueKey('fortress-focus-virtue')), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('fortress-focus-virtue')))
          .bottom,
      lessThan(
        tester.getRect(find.byKey(const ValueKey('fortress-counter'))).top,
      ),
    );
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    expect(find.text(items.last.text), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Previous'));
    await tester.pumpAndSettle();
    expect(find.text(items.first.text), findsOneWidget);
    final counter = tester.widget<FTappable>(
      find.byKey(const ValueKey('fortress-counter')),
    );
    expect(counter.onPress, isNull);
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 800.0, 1200.0]) {
    testWidgets(
      'side details stay open and Escape closes only details at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var exits = 0;
        await tester.pumpWidget(wrap(exit: () => exits++));
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.tap(find.text(l10n.fortressSourceReference));
        await tester.pumpAndSettle();
        expect(find.byType(FortressStudyPanel), findsOneWidget);
        expect(
          find.textContaining(l10n.fortressItemPosition(1, 2)),
          findsOneWidget,
        );
        final panel = tester.getRect(find.byType(FortressStudyPanel));
        expect(panel.top, 0);
        expect(panel.height, 800);
        expect(panel.right, width);
        final tabs = tester.widget<FTabs>(find.byType(FTabs));
        expect(tabs.scrollable, isFalse);
        if (width >= 720) {
          final counterRect = tester.getRect(
            find.byKey(const ValueKey('fortress-counter')),
          );
          expect(counterRect.right, lessThanOrEqualTo(panel.left));
          await tester.tap(find.byKey(const ValueKey('fortress-counter')));
          await tester.pump();
          final counter = tester.widget<FTappable>(
            find.byKey(const ValueKey('fortress-counter')),
          );
          expect(counter.onPress, isNull);
          expect(find.byType(FortressStudyPanel), findsOneWidget);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(FortressStudyPanel), findsNothing);
        expect(exits, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(exits, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'reading text taps count, selection drags do not, and segments animate',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final text = find.text(items.first.text);
      await tester.drag(text, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FTappable>(find.byKey(const ValueKey('fortress-counter')))
            .onPress,
        isNotNull,
      );
      await tester.tap(text);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<FTappable>(find.byKey(const ValueKey('fortress-counter')))
            .onPress,
        isNull,
      );
      final segment = find.descendant(
        of: find.byKey(const ValueKey(('fortress-segment', 0))),
        matching: find.byType(FractionallySizedBox),
      );
      final fraction = tester
          .widget<FractionallySizedBox>(segment)
          .widthFactor!;
      expect(fraction, greaterThan(0));
      expect(fraction, lessThan(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<FractionallySizedBox>(segment).widthFactor, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'focus sheet tabs and automatic item changes rebuild the visible body',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(find.text(l10n.fortressSourceReference));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(FTabs),
          matching: find.text(l10n.fortressVirtue),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Synthetic source', findRichText: true),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(FTabs),
          matching: find.text(l10n.fortressSourceReference),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Synthetic source', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('fortress-counter')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Synthetic second source', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'desktop completion keeps a bounded action group and truthful unfinished state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      for (var i = 0; i < 2; i++) {
        await tester.tap(
          find.bySemanticsLabel(i == 1 ? l10n.fortressFinish : l10n.next),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text(l10n.fortressReachedEnd), findsOneWidget);
      expect(find.text(l10n.fortressCompleted), findsNothing);
      final primary = find
          .ancestor(
            of: find.text(l10n.fortressContinueUnfinished),
            matching: find.byType(FButton),
          )
          .first;
      expect(tester.getSize(primary).width, lessThanOrEqualTo(240));
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(find.text(items.first.text), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final duringClose in [false, true]) {
    testWidgets(
      'exiting with a persistent sheet disposes the whole reader safely (closing: $duringClose)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var visible = true;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (_, setState) => visible
                ? wrap(exit: () => setState(() => visible = false))
                : const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.tap(find.text(l10n.fortressSourceReference));
        await tester.pumpAndSettle();
        if (duringClose) {
          await tester.tap(find.text(l10n.fortressSourceReference).last);
          await tester.pump(const Duration(milliseconds: 40));
        }
        await tester.tap(find.bySemanticsLabel(l10n.fortressExitFocus));
        await tester.pumpAndSettle();
        expect(visible, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('removing the reader cancels an in-flight sheet close', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.tap(find.text(l10n.fortressSourceReference));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.fortressSourceReference).last);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow 200% text fits both locales and themes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final locale in [const Locale('ar'), const Locale('en')]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await tester.pumpWidget(wrap(scale: 2, locale: locale, mode: mode));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('fortress-counter')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
