import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';

void main() {
  Widget wrap(Widget child) {
    return FTheme(
      data: FThemeData(
        colors: FThemes.zinc.light.desktop.colors,
        typography: FThemes.zinc.light.desktop.typography,
        icons: FThemes.zinc.light.desktop.icons,
        touch: false,
        extensions: const [AppRadii.standard(), AppDurations.standard()],
      ),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  int countLeafTextSpans(InlineSpan span) {
    if (span is! TextSpan) return 0;

    final children = span.children;
    if (children == null || children.isEmpty) {
      return span.text == null || span.text!.isEmpty ? 0 : 1;
    }

    return children.fold<int>(0, (count, child) => count + countLeafTextSpans(child));
  }

  bool hasStyledLeaf(
    InlineSpan span,
    bool Function(TextStyle? style) matches,
  ) {
    if (span is! TextSpan) return false;

    final text = span.text;
    if (text != null && text.isNotEmpty && matches(span.style)) {
      return true;
    }

    for (final child in span.children ?? const <InlineSpan>[]) {
      if (hasStyledLeaf(child, matches)) return true;
    }

    return false;
  }

  group('TafsirText', () {
    testWidgets('renders interleaved segments as one flowing paragraph', (
      tester,
    ) async {
      const raw =
          'تفسير '
          '<span class="aya">﴿بِسْمِ اللَّهِ﴾</span> '
          'بعد الآية '
          '<span class="t2">[ الحديث ]</span> '
          'خاتمة';

      await tester.pumpWidget(
        wrap(
          const TafsirText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
          ),
        ),
      );

      expect(find.byType(ScopedSelectableRichText), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('merges qawl, ayah, reference, and commentary into one selectable run', (
      tester,
    ) async {
      const raw =
          'لقوله تعالى: '
          '<span class="t3">( ولقد آتيناك سبعا من المثاني )</span> '
          '<span class="t2">[ الحجر : 87 ]</span> '
          'والله أعلم.';

      await tester.pumpWidget(
        wrap(
          const TafsirText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
            tafsirId: TafsirId.ibnKathir,
          ),
        ),
      );

      expect(find.byType(ScopedSelectableRichText), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);

      final richText = tester.widget<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      final root = richText.textSpan;

      expect(countLeafTextSpans(root), greaterThan(3));
      expect(
        hasStyledLeaf(root, (style) => style?.fontWeight == FontWeight.w700),
        isTrue,
        reason: 'qawl lead span',
      );
      expect(
        hasStyledLeaf(
          root,
          (style) => style?.color == const Color(0xFF15803D),
        ),
        isTrue,
        reason: 'ayah span',
      );
      expect(
        hasStyledLeaf(
          root,
          (style) => style?.fontSize == 14 * 0.88,
        ),
        isTrue,
        reason: 'reference span',
      );
      expect(root.toPlainText(), contains('والله أعلم.'));
    });

    testWidgets('keeps poetry as a separate block between inline runs', (
      tester,
    ) async {
      const raw =
          'مقدمة\n'
          'يا من ألوذ به فيما أؤمله    لا يجبر الناس عظما أنت كاسره\n'
          'خاتمة';

      await tester.pumpWidget(
        wrap(
          const TafsirText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
          ),
        ),
      );

      // Prose before and after poetry stay inline; poetry uses a diwan row.
      expect(find.byType(ScopedSelectableRichText), findsNWidgets(2));
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
