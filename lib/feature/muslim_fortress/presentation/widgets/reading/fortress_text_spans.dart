import 'package:material_ui/material_ui.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Keeps supplied Quran quotations in their own Arabic font; source strings
/// stay untouched. The bundled Quran font owns the supplied ayah-number glyphs.
TextSpan fortressDhikrSpan(String text, TextStyle style) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final quote in RegExp(r'﴿([^﴾]+)﴾', dotAll: true).allMatches(text)) {
    if (quote.start > cursor)
      spans.add(TextSpan(text: text.substring(cursor, quote.start)));
    final body = fortressQuranDisplayText(quote.group(1)!);
    spans.add(
      TextSpan(
        text: body,
        semanticsLabel: quote.group(0),
        style: style.copyWith(
          fontFamily: FontFamily.uthmanicHafs,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
    cursor = quote.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return TextSpan(style: style, children: spans);
}

String fortressQuranDisplayText(String source) =>
    source.replaceAll('﴿', '').replaceAll('﴾', '');
