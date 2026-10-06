import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

class FortressShareCard extends StatelessWidget {
  const new({
    required this.boundaryKey,
    required this.dua,
    required this.options,
    this.commentary,
    super.key,
  });

  final GlobalKey boundaryKey;
  final FortressDuaItem dua;
  final FortressShareOptions options;
  final HisnCommentary? commentary;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final body = theme.typography.body.md.copyWith(height: 1.75);
    final include = options.contains;

    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.typography.body.xs.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: body),
        ],
      ),
    );

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: theme.radii.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  dua.category,
                  style: theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (include(FortressShareInclude.repetition))
                  FBadge(
                    variant: .secondary,
                    child: Text('×${dua.targetCount}'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              dua.text,
              style: theme.typography.body.xl.copyWith(
                fontFamily: dua.isQuranicPassage
                    ? FontFamily.uthmanicHafs
                    : null,
                fontSize: 24,
                height: 1.9,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (include(FortressShareInclude.virtue) && dua.hasDistinctVirtue)
              section(l10n.fortressVirtue, dua.virtue!),
            if (include(FortressShareInclude.sharh) &&
                commentary?.sharh.isNotEmpty == true)
              section(l10n.fortressSharh, commentary!.sharh),
            if (include(FortressShareInclude.hadith) &&
                commentary?.hadith.isNotEmpty == true)
              section(l10n.fortressRelatedHadith, commentary!.hadith),
            if (include(FortressShareInclude.benefit) &&
                commentary?.benefit.isNotEmpty == true)
              section(l10n.fortressBenefit, commentary!.benefit),
            if (include(FortressShareInclude.source) && dua.hasSource) ...[
              Divider(color: colors.border, height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.fortressSourceReference}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: dua.reference),
                  ],
                ),
                style: theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                  height: 1.75,
                ),
              ),
            ],
            if (include(FortressShareInclude.appName)) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  l10n.appName,
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
