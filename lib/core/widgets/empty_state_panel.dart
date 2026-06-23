import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Centered empty-state placeholder with icon, title, and optional hint.
class EmptyStatePanel extends StatelessWidget {
  /// Creates an empty state panel.
  const EmptyStatePanel({
    required this.icon,
    required this.title,
    super.key,
    this.hint,
    this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.iconSize = 40,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary message.
  final String title;

  /// Secondary hint below the title.
  final String? hint;

  /// Optional merged accessibility label.
  final String? semanticsLabel;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  /// Icon size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: theme.colors.mutedForeground.withAlpha(120),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: theme.typography.body.md.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint!,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (semanticsLabel case final label?) {
      return Semantics(
        label: label,
        child: Padding(padding: padding, child: content),
      );
    }

    return Padding(padding: padding, child: content);
  }
}

/// Async error placeholder with icon, message, optional detail, and retry.
class ErrorStatePanel extends StatelessWidget {
  /// Creates an error state panel.
  const ErrorStatePanel({
    required this.message,
    super.key,
    this.detail,
    this.onRetry,
    this.retryLabel,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.maxWidth,
  });

  /// Primary error message.
  final String message;

  /// Optional secondary detail (e.g. exception text).
  final String? detail;

  /// Retry callback; when set, a retry button is shown.
  final VoidCallback? onRetry;

  /// Retry button label.
  final String? retryLabel;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  /// Optional max width for the detail text area.
  final double? maxWidth;

  static const _detailMaxHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FLucideIcons.circleAlert,
            size: 48,
            color: theme.colors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? 400,
                maxHeight: _detailMaxHeight,
              ),
              child: SingleChildScrollView(
                child: Text(
                  detail!,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          if (onRetry != null && retryLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FButton(
              onPress: onRetry,
              child: Text(retryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
