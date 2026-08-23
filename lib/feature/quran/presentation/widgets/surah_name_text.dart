import 'package:flutter/material.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Whether [text] contains Arabic script (surah names from the mushaf catalog).
bool containsArabicScript(String text) {
  return text.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF),
  );
}

/// Applies [FontFamily.uthmanicHafs] for Quranic surah name rendering.
TextStyle surahNameTextStyle(TextStyle base, {double? fontSize}) {
  return base.copyWith(
    fontFamily: FontFamily.uthmanicHafs,
    fontSize: fontSize ?? base.fontSize,
  );
}

/// Uses Uthmanic Hafs when [name] is Arabic script; otherwise [base] unchanged.
TextStyle textStyleForSurahName(
  String name,
  TextStyle base, {
  double? fontSize,
}) {
  if (!containsArabicScript(name)) return base;
  return surahNameTextStyle(base, fontSize: fontSize);
}

/// Renders a surah name with Uthmanic Hafs when the label is Arabic script.
class SurahNameText extends StatelessWidget {
  /// Creates a [SurahNameText].
  const new(
    this.name, {
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    super.key,
  });

  /// Surah display label (Arabic name from the mushaf catalog).
  final String name;

  /// Base typography; Uthmanic Hafs is merged in when [name] is Arabic.
  final TextStyle? style;

  /// Passed through to the underlying [Text].
  final int? maxLines;

  /// Passed through to the underlying [Text].
  final TextOverflow? overflow;

  /// Passed through to the underlying [Text].
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      name,
      style: textStyleForSurahName(name, base),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// Surah name in Uthmanic Hafs plus a trailing 
/// suffix (ayah number, range, etc.).
class SurahNameWithSuffix extends StatelessWidget {
  /// Creates a [SurahNameWithSuffix].
  const new({
    required this.surahName,
    required this.suffix,
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Arabic or localized surah label.
  final String surahName;

  /// Trailing text such as ` · 255` or ` · 1–7`.
  final String suffix;

  /// Base typography for the suffix; the surah span may override the font.
  final TextStyle? style;

  /// Passed through to the underlying [Text.rich].
  final int? maxLines;

  /// Passed through to the underlying [Text.rich].
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: surahName,
            style: textStyleForSurahName(surahName, base),
          ),
          TextSpan(text: suffix, style: base),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

/// Localized ayah reference (`surah • ayah`) with Uthmanic Hafs on the surah span.
///
/// When [reference] has no surah/ayah separator, applies Uthmanic Hafs only if
/// the whole label is Arabic script (e.g. a standalone surah name).
class AyahReferenceText extends StatelessWidget {
  /// Creates an [AyahReferenceText].
  const new(
    this.reference, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Pre-formatted reference from localized ayah-reference helpers.
  final String reference;

  /// Base typography.
  final TextStyle? style;

  /// Passed through to the underlying text widget.
  final int? maxLines;

  /// Passed through to the underlying text widget.
  final TextOverflow? overflow;

  static const _separators = [' • ', ' · '];

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    for (final separator in _separators) {
      final sepIndex = reference.indexOf(separator);
      if (sepIndex > 0) {
        return SurahNameWithSuffix(
          surahName: reference.substring(0, sepIndex),
          suffix: reference.substring(sepIndex),
          style: base,
          maxLines: maxLines,
          overflow: overflow,
        );
      }
    }

    return SurahNameText(
      reference,
      style: base,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Inline spans for a `surah · ayah` fragment with Uthmanic Hafs on the surah.
List<InlineSpan> surahAyahReferenceSpans(String reference, TextStyle style) {
  for (final separator in AyahReferenceText._separators) {
    final sepIndex = reference.indexOf(separator);
    if (sepIndex > 0) {
      final surahPart = reference.substring(0, sepIndex);
      return [
        TextSpan(
          text: surahPart,
          style: textStyleForSurahName(surahPart, style),
        ),
        TextSpan(text: reference.substring(sepIndex), style: style),
      ];
    }
  }

  return [
    TextSpan(
      text: reference,
      style: textStyleForSurahName(reference, style),
    ),
  ];
}

/// Range label for the player chrome (`surah · ayah`, cross-surah arrows, etc.).
class AyahRangeLabelText extends StatelessWidget {
  /// Creates an [AyahRangeLabelText].
  const new(
    this.label, {
    this.style,
    this.suffix = '',
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Formatted surah/ayah range for the player chrome.
  final String label;

  /// Base typography.
  final TextStyle? style;

  /// Optional trailing text such as ` · 3×`.
  final String suffix;

  /// Passed through to the underlying [Text.rich].
  final int? maxLines;

  /// Passed through to the underlying [Text.rich].
  final TextOverflow? overflow;

  static const _arrow = ' → ';

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final arrowIndex = label.indexOf(_arrow);
    final children = <InlineSpan>[
      if (arrowIndex > 0) ...[
        ...surahAyahReferenceSpans(label.substring(0, arrowIndex), base),
        TextSpan(text: _arrow, style: base),
        ...surahAyahReferenceSpans(
          label.substring(arrowIndex + _arrow.length),
          base,
        ),
      ] else
        ...surahAyahReferenceSpans(label, base),
      if (suffix.isNotEmpty) TextSpan(text: suffix, style: base),
    ];

    return Text.rich(
      TextSpan(style: base, children: children),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
