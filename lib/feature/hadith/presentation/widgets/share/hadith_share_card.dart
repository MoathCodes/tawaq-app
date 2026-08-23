import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/theme/theme.dart';

class HadithShareCard extends StatelessWidget {
  const new({
    required this.boundaryKey,
    required this.hadith,
    required this.options,
    this.sharh,
    this.usul,
    super.key,
  });

  final GlobalKey boundaryKey;
  final DetailedHadith hadith;
  final HadithShareOptions options;
  final String? sharh;
  final UsulHadith? usul;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final type = context.theme.typography;
    final l10n = context.l10n;
    final include = options.contains;
    final textStyle = type.body.md.copyWith(height: 1.75);

    Widget labelled(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: type.body.xs.copyWith(color: colors.primary)),
          const SizedBox(height: 2),
          Text(value, style: textStyle),
        ],
      ),
    );

    final content = <Widget>[
      Text(
        hadith.hadith,
        textAlign: TextAlign.justify,
        style: type.body.lg.copyWith(height: 1.9, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (include(HadithShareInclude.narrator))
        labelled(l10n.hadithNarrator, hadith.rawi),
      if (include(HadithShareInclude.muhaddith))
        labelled(l10n.hadithMuhaddith, hadith.mohdith),
      if (include(HadithShareInclude.source))
        labelled(l10n.hadithSource, hadith.book),
      if (include(HadithShareInclude.number))
        labelled(l10n.hadithNumberOrPage, hadith.numberOrPage),
      if (include(HadithShareInclude.grade))
        labelled(l10n.hadithGradeExplanation, hadith.hukm),
      if (include(HadithShareInclude.takhrij) &&
          (hadith.takhrij ?? '').trim().isNotEmpty)
        labelled(l10n.hadithTakhrij, hadith.takhrij!.trim()),
      if (include(HadithShareInclude.sharh) && sharh != null) ...[
        _sectionHeading(context, l10n.hadithSharh),
        Text(sharh!, style: textStyle),
      ],
      if (include(HadithShareInclude.usul) && usul != null) ...[
        _sectionHeading(context, l10n.hadithUsulHadith),
        for (final source in usul!.sources)
          labelled(source.source, source.chain),
      ],
    ];

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: 1.5),
          borderRadius: context.theme.radii.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...content,
            if (include(HadithShareInclude.appName)) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  l10n.appName,
                  style: type.body.xs.copyWith(color: colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _sectionHeading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    child: Text(
      text,
      style: context.theme.typography.body.sm.copyWith(
        color: context.theme.colors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
