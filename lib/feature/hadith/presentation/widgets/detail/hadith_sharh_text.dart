import 'package:tawaq/feature/hadith/domain/models/hadith_display_text.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/gestures.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide TextRange;
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';

/// Native selectable rendering of SDK structure, with no source normalization.
class HadithSharhText extends ConsumerStatefulWidget {
  const HadithSharhText({
    this.document,
    this.text = '',
    this.fontSize,
    this.commentaryOnly = false,
    super.key,
  });
  final SourcedDocument? document;
  final String text;
  final double? fontSize;
  final bool commentaryOnly;

  @override
  ConsumerState<HadithSharhText> createState() => _HadithSharhTextState();
}

class _HadithSharhTextState extends ConsumerState<HadithSharhText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final document = widget.document;
    final style = context.theme.typography.body.md.copyWith(
      height: 1.8,
      fontSize: widget.fontSize,
    );
    if (document == null)
      return ScopedSelectableText(
        widget.text,
        style: style,
        textDirection: TextDirection.rtl,
      );
    final tokens = documentRenderTokens(
      document,
      commentaryOnly: widget.commentaryOnly,
    );
    final paragraphs = <Widget>[];
    for (final block in document.blocks) {
      if (block.kind == BlockKind.separator) continue;
      final raw = block.range.extract(document.sourceText);
      final start = block.range.start + raw.length - raw.trimLeft().length;
      final end = block.range.end - (raw.length - raw.trimRight().length);
      if (end <= start) continue;
      final spans = <InlineSpan>[];
      for (final token in tokens.where(
        (t) =>
            t.range.start >= block.range.start &&
            t.range.end <= block.range.end,
      )) {
        if (token.range.start >= end || token.range.end <= start) continue;
        final annotation = token.annotations
            .where((a) => a.uri != null || a.definition != null)
            .firstOrNull;
        TapGestureRecognizer? recognizer;
        if (annotation?.uri case final uri?) {
          if (uri.scheme == 'https' || uri.scheme == 'http') {
            recognizer = TapGestureRecognizer()
              ..onTap = () async {
                await ref.read(externalLinkLauncherProvider)(uri);
              };
            _recognizers.add(recognizer);
          }
        }
        if (annotation?.definition case final definition?) {
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              showFDialog<void>(
                context: context,
                builder: (context, style, animation) => FDialog(
                  style: style,
                  animation: animation,
                  builder: (context, dialogStyle) => ForuiDialogLayout(
                    style: dialogStyle,
                    title: Text(annotation!.label ?? token.text),
                    body: Text(definition),
                    actions: [
                      FButton(
                        onPress: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.close),
                      ),
                    ],
                  ),
                ),
              );
            };
          _recognizers.add(recognizer);
        }
        spans.add(
          TextSpan(
            text: document.sourceText.substring(
              token.range.start.clamp(start, end),
              token.range.end.clamp(start, end),
            ),
            recognizer: recognizer,
            style: recognizer == null
                ? null
                : TextStyle(
                    color: context.theme.colors.primary,
                    decoration: TextDecoration.underline,
                  ),
          ),
        );
      }
      if (spans.isEmpty) continue;
      final paragraph = ScopedSelectableRichText(
        TextSpan(
          children: spans,
          style: block.kind == BlockKind.heading
              ? style.copyWith(fontWeight: FontWeight.w600)
              : style,
        ),
      );
      paragraphs.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: block.kind == BlockKind.heading ? 8 : 14,
          ),
          child: block.kind == BlockKind.narration
              ? Container(
                  padding: const EdgeInsets.all(12),
                  color: context.theme.colors.secondary,
                  child: paragraph,
                )
              : paragraph,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs,
    );
  }
}

/// Explanation context is composed independently from its commentary blocks.
class HadithSharhContent extends StatelessWidget {
  const HadithSharhContent({
    required this.sharh,
    this.origin,
    this.selectedHadith,
    this.commentaryOnly = false,
    this.export = false,
    super.key,
  });
  final Sharh sharh;
  final ExplanationReference? origin;
  final DetailedHadith? selectedHadith;
  final bool export;
  final bool commentaryOnly;

  static bool sameRecord(DetailedHadith a, DetailedHadith b) {
    final identified =
        a.hadithId?.isNotEmpty == true && a.hadithId == b.hadithId;
    return (identified ||
            (hasHadithMetadata(a.book) && hasHadithMetadata(a.numberOrPage))) &&
        a.hadith == b.hadith &&
        a.rawi == b.rawi &&
        a.mohdith == b.mohdith &&
        a.book == b.book &&
        a.numberOrPage == b.numberOrPage &&
        a.grade == b.grade &&
        a.explainGrade == b.explainGrade;
  }

  Widget _record(BuildContext context, String label, DetailedHadith record) =>
      Container(
        padding: export
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.all(14),
        decoration: export
            ? null
            : BoxDecoration(
                color: context.theme.colors.secondary,
                borderRadius: context.theme.radii.md,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Text(
              label,
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: export ? 18 : null,
              ),
            ),
            if (!commentaryOnly)
              Text(
                hadithDisplayText(record),
                textDirection: TextDirection.rtl,
                style: context.theme.typography.body.md.copyWith(
                  height: 1.8,
                  fontSize: export ? 20 : null,
                ),
              ),
            HadithMetaField(
              label: context.l10n.hadithNarrator,
              value: record.rawi,
              layout: HadithMetaFieldLayout.inline,
              fontSize: export ? 18 : null,
            ),
            HadithMetaField(
              label: context.l10n.hadithMuhaddith,
              value: record.mohdith,
              layout: HadithMetaFieldLayout.inline,
              fontSize: export ? 18 : null,
            ),
            HadithMetaField(
              label: context.l10n.hadithSource,
              value: context.l10n.hadithSourceCitation(
                record.book,
                record.numberOrPage,
              ),
              layout: HadithMetaFieldLayout.inline,
              fontSize: export ? 18 : null,
            ),
            for (final ruling in hadithSourceRulings(record))
              HadithMetaField(
                label: ruling.expanded
                    ? context.l10n.hadithGradeExplanation
                    : context.l10n.hadithGrade,
                value: ruling.text,
                layout: HadithMetaFieldLayout.inline,
                fontSize: export ? 18 : null,
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final headerVisible =
        selectedHadith == null || !sameRecord(selectedHadith!, sharh.hadith);
    final embedded = sharh.embeddedHadith;
    final embeddedVisible =
        embedded != null &&
        !sameRecord(sharh.hadith, embedded) &&
        (selectedHadith == null || !sameRecord(selectedHadith!, embedded));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        if (headerVisible && origin?.rawLabel.isNotEmpty == true)
          Text(origin!.rawLabel.replaceFirst(RegExp(r'^\s*\|\s*'), '').trim()),
        if (headerVisible)
          _record(context, context.l10n.hadithExplanationHeader, sharh.hadith),
        if (embeddedVisible)
          _record(context, context.l10n.hadithExplanationCitation, embedded),
        HadithSharhText(
          document: sharh.document,
          text: sharh.sharhText ?? '',
          commentaryOnly: sharh.document != null,
          fontSize: export ? 20 : null,
        ),
      ],
    );
  }
}
