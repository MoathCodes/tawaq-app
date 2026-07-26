import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared title row for player-style modal dialogs.
class PlayerDialogHeader extends StatelessWidget {
  /// Creates a [PlayerDialogHeader].
  const PlayerDialogHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.headerBottom,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Optional muted line under the title.
  final String? subtitle;

  /// Optional leading icon next to the title.
  final IconData? icon;

  /// Optional widget pinned under the title row (e.g. a search field).
  final Widget? headerBottom;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Padding(
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
  }
}

/// Shared chrome for modal dialogs: a themed card with a title row (optional
/// leading icon), a close button, and a body.
///
/// Pulls every color from the active [FThemeData] so it adapts to light and
/// dark themes. [width] is a *preferred* width — the shell clamps to the
/// viewport via [dialogConstraints].
class TawaqDialogShell extends StatelessWidget {
  /// Creates a [TawaqDialogShell].
  const TawaqDialogShell({
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

    final constraints = dialogConstraints(
      context,
      preferredWidth: width,
      preferredHeight: maxHeight,
      minWidth: 320,
    );

    final header = PlayerDialogHeader(
      title: title,
      subtitle: subtitle,
      icon: icon,
      headerBottom: headerBottom,
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

/// @deprecated Use [TawaqDialogShell] instead.
typedef PlayerDialogShell = TawaqDialogShell;

/// Standard Forui 0.24+ dialog body: title, body, trailing action row.
///
/// Use inside [FDialog.builder] after the built-in content layout was removed.
class ForuiDialogLayout extends StatelessWidget {
  /// Creates a [ForuiDialogLayout].
  const ForuiDialogLayout({
    required this.style,
    required this.title,
    required this.body,
    required this.actions,
    this.expandActions = false,
    super.key,
  });

  /// Resolved dialog style from [FDialog.builder].
  final FDialogStyle style;

  /// Dialog title (styled with [FDialogStyle.titleTextStyle]).
  final Widget title;

  /// Dialog body (styled with [FDialogStyle.bodyTextStyle]).
  final Widget body;

  /// Action buttons shown in a trailing row.
  final List<Widget> actions;

  /// When true, each action is [Expanded] (touch-friendly full-width row).
  final bool expandActions;

  @override
  Widget build(BuildContext context) {
    final touch = context.platformVariant.touch;
    final titleBottom = touch ? 9.0 : 5.0;
    final bodyBottom = touch ? 20.0 : 16.0;
    final actionSpacing = touch ? 10.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: touch ? 18 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: titleBottom),
            child: DefaultTextStyle.merge(
              style: style.titleTextStyle,
              child: title,
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bodyBottom),
              child: DefaultTextStyle.merge(
                style: style.bodyTextStyle,
                child: body,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: actionSpacing,
            children: expandActions || touch
                ? [for (final action in actions) Expanded(child: action)]
                : actions,
          ),
        ],
      ),
    );
  }
}
