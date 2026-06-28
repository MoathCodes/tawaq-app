import 'package:flutter/material.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/theme/theme.dart';

/// Placeholder skeleton list shown while the first search page loads.
class HadithResultsSkeletonList extends StatelessWidget {
  const HadithResultsSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hadithSearchLoadingSemanticsLabel(context.l10n),
      child: ExcludeSemantics(
        child: ListView.separated(
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) {
            return const StaticCard(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  SizedBox(height: 20, width: double.infinity),
                  SizedBox(height: 20, width: double.infinity),
                  SizedBox(height: 20, width: 220),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(height: 14, width: 180),
                  SizedBox(height: AppSpacing.xs),
                  SizedBox(height: 14, width: 220),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(height: 30, width: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
