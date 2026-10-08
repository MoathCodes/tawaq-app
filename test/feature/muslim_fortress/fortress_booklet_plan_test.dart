import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_booklet_plan.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));
  final colors = buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: ThemeMode.dark,
    touch: false,
    textScale: 1,
  ).colors;
  for (final scale in [.8, 1.0, 1.25, 1.6]) {
    test(
      'long Arabic blocks preserve every grapheme and fit page bounds, scale=$scale',
      () async {
        final source = List.filled(
          170,
          'نصٌّ تجريبيٌّ غير دينيّ لاختبار الصفحات 👨‍👩‍👧‍👦.\n',
        ).join();
        final blocks = [
          FortressBookletBlock(
            id: '1:body',
            itemId: 1,
            itemNumber: 1,
            target: 100,
            heading: 'Synthetic fixture',
            text: source,
            dhikr: true,
          ),
          const FortressBookletBlock(
            id: '2:body',
            itemId: 2,
            itemNumber: 2,
            target: 3,
            heading: '',
            text: 'Second fixture',
            dhikr: true,
          ),
        ];
        final plan = await FortressBookletPlan.create(
          title: 'Fixture',
          blocks: blocks,
          colors: colors,
          l10n: l10n,
          textScale: scale,
        );
        expect(plan.pages.length, greaterThan(2));
        final slices = plan.pages.expand((page) => page.slices).toList();
        for (final block in blocks) {
          final parts = slices.where((s) => s.block.id == block.id).toList();
          expect(parts.map((s) => s.text).join(), block.text);
          final boundaries = {0};
          var cursor = 0;
          for (final grapheme in block.text.characters) {
            cursor += grapheme.length;
            boundaries.add(cursor);
          }
          expect(
            parts.every(
              (s) => boundaries.contains(s.start) && boundaries.contains(s.end),
            ),
            isTrue,
          );
        }
        expect(
          slices.every(
            (s) =>
                s.y >= FortressBookletPlan.bodyTop &&
                s.y + s.height <= FortressBookletPlan.bodyBottom,
          ),
          isTrue,
        );
        expect(slices.last.block.itemId, 2);
        expect(
          slices
              .where((s) => s.start > 0)
              .every((s) => s.heading.contains(l10n.fortressContinued)),
          isTrue,
        );
        final bytes = await plan.png(0);
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(plan.plainText, contains(source));
      },
    );
  }
  test('a fitting dhikr and source move together to the next page', () async {
    final blocks = [
      FortressBookletBlock(
        id: '1',
        itemId: 1,
        itemNumber: 1,
        target: 1,
        heading: '',
        text: List.filled(9, 'Synthetic previous item\n').join(),
        dhikr: true,
      ),
      const FortressBookletBlock(
        id: '2',
        itemId: 2,
        itemNumber: 2,
        target: 3,
        heading: '',
        text: 'Synthetic second reading',
        dhikr: true,
      ),
      FortressBookletBlock(
        id: '2:source',
        itemId: 2,
        itemNumber: 2,
        target: 3,
        heading: 'Source',
        text: List.filled(3, 'Synthetic second source\n').join(),
        source: true,
      ),
    ];
    final plan = await FortressBookletPlan.create(
      title: 'Fixture',
      blocks: blocks,
      colors: colors,
      l10n: l10n,
    );
    final pages = plan.pages
        .where((p) => p.slices.any((s) => s.block.itemId == 2))
        .toList();
    expect(pages, hasLength(1));
    expect(pages.single.slices.map((s) => s.block.id), ['2', '2:source']);
    expect(
      pages.single.slices.map((s) => s.text).join(),
      blocks.skip(1).map((b) => b.text).join(),
    );
  });
  test('cancelled plan yields no partial result', () async {
    await expectLater(
      FortressBookletPlan.create(
        title: 'Fixture',
        blocks: [
          const FortressBookletBlock(
            id: '1',
            itemId: 1,
            itemNumber: 1,
            target: 1,
            heading: '',
            text: 'Fixture',
          ),
        ],
        colors: colors,
        l10n: l10n,
        cancelled: () => true,
      ),
      throwsA(isA<FortressBookletCancelled>()),
    );
  });
}
