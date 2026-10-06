import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_hukm_badge.dart';
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
    // Constrain at the render boundary too, so direct callers cannot omit a
    // negative source ruling or render missing attribution placeholders.
    final include = options
        .constrained(
          hadith: hadith,
          sharhAvailable: sharh != null,
          usulAvailable: usul != null,
        )
        .contains;
    final textStyle = type.body.md.copyWith(height: 1.75);

    Widget labelled(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${context.l10n.hadithFieldLabel(label)} ',
              style: textStyle.copyWith(color: colors.mutedForeground),
            ),
            TextSpan(text: value, style: textStyle),
          ],
        ),
        textAlign: TextAlign.start,
      ),
    );

    final attribution = <Widget>[
      if (include(HadithShareInclude.narrator))
        labelled(l10n.hadithNarrator, hadith.rawi),
      if (include(HadithShareInclude.muhaddith))
        labelled(l10n.hadithMuhaddith, hadith.mohdith),
      if (include(HadithShareInclude.source))
        labelled(l10n.hadithSource, hadith.book),
      if (include(HadithShareInclude.number))
        labelled(l10n.hadithNumberOrPage, hadith.numberOrPage),
    ];
    final content = <Widget>[
      Text(
        hadith.hadith,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.start,
        style: type.body.lg.copyWith(
          fontSize: 24,
          height: 1.9,
          fontWeight: FontWeight.w500,
        ),
      ),
      if (include(HadithShareInclude.grade)) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.hadithGradeExplanation,
          style: type.body.sm.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: AppSpacing.sm),
        HadithHukmBadge(
          hukm: hadith.hukm,
          tone: hadithSourceJudgmentTone(hadith),
        ),
      ],
      if (attribution.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: AppSpacing.md),
        ...attribution,
      ],
      if (include(HadithShareInclude.takhrij))
        labelled(l10n.hadithTakhrij, hadith.takhrij!),
      if (include(HadithShareInclude.sharh) && sharh != null) ...[
        _sectionHeading(context, l10n.hadithSharh),
        Text(sharh!, textDirection: TextDirection.rtl, style: textStyle),
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
        width: 560,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: 1),
          borderRadius: context.theme.radii.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...content,
            if (include(HadithShareInclude.appName)) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
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
