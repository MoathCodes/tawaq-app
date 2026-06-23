import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared chrome for modal dialogs: a themed card with a title row (optional
/// leading icon), a close button, and a body.
///
/// Pulls every color from the active [FThemeData] so it adapts to light and
/// dark themes. [width] is a *preferred* width — the shell clamps to the
/// viewport via [dialogConstraints].
class PlayerDialogShell extends StatelessWidget {
  /// Creates a [PlayerDialogShell].
  const PlayerDialogShell({
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.headerBottom,
    this.footer,
    this.width = 520,
    this.maxHeight,
    this.scrollableBody = false,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Optional muted line under the title.
  final String? subtitle;

  /// Optional leading icon next to the title.
  final IconData? icon;

  /// Body content.
  final Widget child;

  /// Optional widget pinned under the title row (e.g. a search field).
  final Widget? headerBottom;

  /// Optional pinned footer below the body (e.g. a primary action).
  final Widget? footer;

  /// Preferred dialog width; clamped to the viewport.
  final double width;

  /// Optional max height; the [child] scrolls within it when [scrollableBody].
  final double? maxHeight;

  /// Whether the body should scroll inside [maxHeight].
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    final constraints = dialogConstraints(
      context,
      preferredWidth: width,
      preferredHeight: maxHeight,
      minWidth: 320,
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typography.body.lg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.body.sm.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).maybePop(),
                child: Icon(
                  FLucideIcons.x,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          if (headerBottom != null) ...[
            const SizedBox(height: AppSpacing.md),
            headerBottom!,
          ],
        ],
      ),
    );

    final body = scrollableBody
        ? Flexible(child: SingleChildScrollView(child: child))
        : child;

    return Center(
      child: ConstrainedBox(
        constraints: constraints,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: theme.radii.xl,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              Container(height: 1, color: colors.border),
              body,
              if (footer != null) ...[
                Container(height: 1, color: colors.border),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
