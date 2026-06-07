import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_commentary_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
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
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );
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

  group('FortressCommentaryText', () {
    testWidgets('renders numbered blocks with list marker styling', (
      tester,
    ) async {
      const raw = '''
1- قوله: «أصبحنا» أي دخلنا في الصباح.
2- قوله: «وله الحمد»: أي الحمد المطلق.
''';

      await tester.pumpWidget(
        wrap(
          const FortressCommentaryText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
          ),
        ),
      );

      expect(find.byType(ScopedSelectableRichText), findsNWidgets(2));
      expect(find.textContaining('1 —'), findsOneWidget);
      expect(find.textContaining('2 —'), findsOneWidget);

      final firstRichText = tester.widget<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText).first,
      );
      expect(
        hasStyledLeaf(
          firstRichText.textSpan,
          (style) => style?.fontWeight == FontWeight.w700,
        ),
        isTrue,
        reason: 'numbered list marker',
      );
    });

    testWidgets('renders citation footnotes below numbered body', (
      tester,
    ) async {
      const raw =
          '1- قوله: «أصبحنا» /55 تحفة الأحوذي، 9/ 236 /55 .';

      await tester.pumpWidget(
        wrap(
          const FortressCommentaryText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
          ),
        ),
      );

      expect(find.byIcon(FLucideIcons.bookMarked), findsOneWidget);
      expect(find.byType(SelectableText), findsNWidgets(2));
      expect(find.textContaining('تحفة'), findsOneWidget);
      expect(find.textContaining('/55'), findsNothing);
    });

    testWidgets('applies Uthmanic ayah styling in prose body', (
      tester,
    ) async {
      const raw =
          '4- قوله: «text» ﴿إِنَّ إِلَىٰ رَبِّكَ الرُّجْعَىٰ﴾ سورة العلق، الآية: 8 .';

      await tester.pumpWidget(
        wrap(
          const FortressCommentaryText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
          ),
        ),
      );

      final richText = tester.widget<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );

      expect(
        hasStyledLeaf(
          richText.textSpan,
          (style) => style?.fontFamily == FontFamily.uthmanicHafs,
        ),
        isTrue,
        reason: 'ayah snippet uses Uthmanic font',
      );
      expect(
        hasStyledLeaf(
          richText.textSpan,
          (style) => style?.fontWeight == FontWeight.w500,
        ),
        isTrue,
        reason: 'ayah snippet has medium weight',
      );
    });
  });
}
