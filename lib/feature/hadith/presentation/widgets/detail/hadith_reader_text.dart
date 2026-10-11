import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

/// Paragraph selection keeps mouse anchors in the displayed RTL text instead
/// of introducing a separately scrolling editable viewport in the reader.
class HadithReaderText extends StatelessWidget {
  const new(this.text, {required this.style, super.key});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = desktopTextSelectionColors(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultSelectionStyle(
        selectionColor: colors.selectionColor,
        cursorColor: colors.cursorColor,
        child: SelectionArea(
          child: Text(text, style: style, textDirection: TextDirection.rtl),
        ),
      ),
    );
  }
}
