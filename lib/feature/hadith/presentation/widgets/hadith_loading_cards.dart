import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_card_layout.dart';
import 'package:tawaq/theme/theme.dart';

/// Prose previews have paragraphs rather than record attribution and actions.
class HadithProseLoading extends StatelessWidget {
  const HadithProseLoading({super.key});
  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    effect: SolidColorEffect(color: context.theme.colors.muted),
    child: ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 32),
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Bone(height: 14),
          Bone(height: 14),
          FractionallySizedBox(widthFactor: .7, child: Bone(height: 14)),
          Bone(width: 80, height: 12),
        ],
      ),
    ),
  );
}

/// Static, neutral placeholders follow the loaded card's responsive slots.
class HadithLoadingCards extends StatelessWidget {
  const HadithLoadingCards({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final line = (theme.typography.body.lg.fontSize ?? 18) * 1.9;
    return Skeletonizer.zone(
      effect: SolidColorEffect(color: theme.colors.muted),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => HadithCardFrame(
          key: const ValueKey('hadith-loading-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(
                      height: line,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: i == 2 ? .62 : 1,
                          child: Bone(height: line * .55),
                        ),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Bone(width: 90, height: 10),
                    Bone(width: 100, height: 20),
                  ],
                ),
              ),
              HadithAttributionLayout(
                compact: [
                  for (var i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Bone(width: 200, height: 14),
                    ),
                ],
                wide: [
                  for (var i = 0; i < 3; i++)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Bone(width: 70, height: 10),
                        Bone(width: 120, height: 14),
                      ],
                    ),
                ],
              ),
              const Wrap(
                spacing: 6,
                children: [
                  Bone(width: 90, height: 22),
                  Bone(width: 75, height: 22),
                  Bone(width: 85, height: 22),
                ],
              ),
              const SizedBox(height: 4),
              const Wrap(
                spacing: 16,
                children: [
                  Bone(width: 110, height: 30),
                  Bone(width: 100, height: 30),
                  Bone(width: 32, height: 30),
                  Bone(width: 85, height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
