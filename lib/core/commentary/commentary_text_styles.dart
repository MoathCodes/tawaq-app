import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Shared typography styles for Arabic commentary formatters.
@immutable
class CommentaryTextStyles {
  /// Creates commentary styles.
  const CommentaryTextStyles({
    required this.prose,
    required this.ayah,
    required this.qawlLead,
    required this.quote,
    required this.scholarLead,
    required this.gloss,
    required this.citation,
    required this.verseRef,
    required this.listMarker,
    required this.sectionLead,
    required this.alternateOpinion,
    required this.editorialBracket,
    this.selectionStrut,
  });

  /// Builds styles from a base Naskh style and theme colors.
  factory CommentaryTextStyles.from({
    required TextStyle baseStyle,
    required FColors colors,
    required bool isDark,
    bool useUthmanTnProse = false,
    bool includeSelectionStrut = false,
  }) {
    final fontSize = baseStyle.fontSize ?? 14;
    const proseHeight = 1.85;
    final proseFont =
        useUthmanTnProse ? FontFamily.uthmanTN : baseStyle.fontFamily;
    final ayahColor = Color.lerp(
      colors.primary,
      colors.mutedForeground,
      isDark ? 0.15 : 0.35,
    )!;

    return CommentaryTextStyles(
      prose: baseStyle.copyWith(
        fontFamily: proseFont,
        height: proseHeight,
      ),
      ayah: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanicHafs,
        fontSize: fontSize * 1.08,
        height: 1.9,
        color: ayahColor,
        fontWeight: FontWeight.w500,
      ),
      qawlLead: baseStyle.copyWith(
        fontFamily: proseFont,
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: proseHeight,
      ),
      quote: baseStyle.copyWith(
        fontFamily: proseFont,
        fontWeight: FontWeight.w600,
        color: Color.lerp(
          colors.primary,
          colors.foreground,
          isDark ? 0.15 : 0.4,
        ),
        height: proseHeight,
      ),
      scholarLead: baseStyle.copyWith(
        fontFamily: proseFont,
        fontWeight: FontWeight.w600,
        color: Color.lerp(colors.foreground, colors.primary, 0.35),
        height: proseHeight,
      ),
      gloss: baseStyle.copyWith(
        fontFamily: proseFont,
        fontWeight: FontWeight.w600,
        color: Color.lerp(colors.primary, colors.foreground, 0.25),
        height: proseHeight,
      ),
      citation: baseStyle.copyWith(
        fontSize: fontSize * 0.88,
        color: colors.mutedForeground,
        height: 1.55,
      ),
      verseRef: baseStyle.copyWith(
        fontSize: fontSize * 0.78,
        color: colors.mutedForeground,
        height: 1.6,
      ),
      listMarker: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: proseHeight,
      ),
      sectionLead: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: proseHeight,
      ),
      alternateOpinion: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: colors.mutedForeground,
        height: proseHeight,
      ),
      editorialBracket: baseStyle.copyWith(
        color: colors.mutedForeground,
        height: proseHeight,
      ),
      selectionStrut: includeSelectionStrut
          ? StrutStyle(
              fontFamily: FontFamily.uthmanTN,
              fontSize: fontSize,
              height: proseHeight,
              forceStrutHeight: true,
              leadingDistribution: TextLeadingDistribution.even,
            )
          : null,
    );
  }

  /// Default prose body.
  final TextStyle prose;

  /// Uthmanic ayah snippets.
  final TextStyle ayah;

  /// Qawl / divine-speech leads.
  final TextStyle qawlLead;

  /// Matn or lexical quotes.
  final TextStyle quote;

  /// Scholar dialogue leads.
  final TextStyle scholarLead;

  /// Gloss markers (`أي:` etc.).
  final TextStyle gloss;

  /// Footnote citations.
  final TextStyle citation;

  /// Surah/ayah references beside ayahs.
  final TextStyle verseRef;

  /// Numbered list markers.
  final TextStyle listMarker;

  /// Section pivots (`وفي هذا الحديث`).
  final TextStyle sectionLead;

  /// Alternate opinions (`وقيل:`).
  final TextStyle alternateOpinion;

  /// Editorial brackets (`[هذا]`).
  final TextStyle editorialBracket;

  /// Optional strut for mixed-font selectable paragraphs (tafsir study mode).
  final StrutStyle? selectionStrut;

  /// Bracketed hadith labels and editorial notes (tafsir `t2`).
  TextStyle get reference => citation;

  /// Surah/ayah cross-references (tafsir `t3` `( N - name )`).
  TextStyle get crossReference => verseRef;
}

/// Supplies [CommentaryTextStyles] to commentary formatters below in the tree.
class CommentaryStyleScope extends InheritedWidget {
  /// Creates a commentary style scope.
  const CommentaryStyleScope({
    required this.styles,
    required super.child,
    super.key,
  });

  /// Commentary styles for descendants.
  final CommentaryTextStyles styles;

  /// Returns the nearest [CommentaryTextStyles] from the tree.
  static CommentaryTextStyles of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CommentaryStyleScope>();
    assert(
      scope != null,
      'CommentaryStyleScope not found in context. '
      'Wrap commentary widgets in CommentaryStyleScope.',
    );
    return scope!.styles;
  }

  @override
  bool updateShouldNotify(CommentaryStyleScope oldWidget) =>
      styles != oldWidget.styles;
}
