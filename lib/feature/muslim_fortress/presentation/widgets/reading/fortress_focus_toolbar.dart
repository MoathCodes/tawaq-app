import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_nav_controls.dart';
import 'package:tawaq/theme/theme.dart';

/// Top chrome for focus reading: progress, finish, title, and counter.
class FortressFocusToolbar extends StatelessWidget {
  /// Creates a focus toolbar.
  const FortressFocusToolbar({
    required this.category,
    required this.duas,
    required this.index,
    required this.remaining,
    required this.isDone,
    required this.progress,
    required this.counterScale,
    required this.onExit,
    super.key,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final int index;
  final int remaining;
  final bool isDone;
  final double progress;
  final Animation<double> counterScale;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FortressExcludeDecorative(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: theme.colors.muted.withAlpha(80),
                valueColor: AlwaysStoppedAnimation(
                  isDone
                      ? theme.colors.primary
                      : theme.colors.primary.withAlpha(200),
                ),
              );
            },
          ),
        ),
        NonSelectable(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, toolbarConstraints) {
                final compactToolbar =
                    toolbarConstraints.maxWidth < context.theme.breakpoints.sm;

                return Row(
                  children: [
                    FortressLabeledNavButton(
                      label: l10n.fortressFinish,
                      enabled: true,
                      onPress: onExit,
                      iconOnly: compactToolbar,
                      prefix: const Icon(FLucideIcons.x, size: 18),
                      child: Text(l10n.fortressFinish),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Semantics(
                        header: true,
                        label: category.title,
                        child: Text(
                          category.title,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      liveRegion: true,
                      label: isDone
                          ? l10n.fortressCompleted
                          : l10n.fortressRemainingCount(remaining),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ScaleTransition(
                            scale: counterScale,
                            child: Text(
                              isDone ? '✓' : '$remaining',
                              style: theme.typography.body.xl3.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: isDone
                                    ? theme.colors.primary
                                    : theme.colors.foreground,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${index + 1} / ${duas.length}',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
