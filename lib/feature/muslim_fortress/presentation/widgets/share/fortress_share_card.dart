import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
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
        width: 640,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: 1.5),
          borderRadius: theme.radii.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dua.category,
              style: theme.typography.body.sm.copyWith(color: colors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              dua.text,
              style: theme.typography.body.xl.copyWith(height: 1.9),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (include(FortressShareInclude.repetition))
              section(l10n.fortressRepetition, '×${dua.targetCount}'),
            if (include(FortressShareInclude.source) && dua.hasSource)
              section(l10n.fortressSourceReference, dua.reference!),
            if (include(FortressShareInclude.virtue) && dua.hasVirtue)
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
            if (include(FortressShareInclude.appName)) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  l10n.appName,
                  style: theme.typography.body.xs.copyWith(
                    color: colors.primary,
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
