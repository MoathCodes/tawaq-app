import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/theme/theme.dart';

/// A screen that is displayed when a route is not found.
class NotFoundScreen extends StatelessWidget {
  /// Creates a not found screen.
  const NotFoundScreen({required this.errorMsg, super.key});

  /// The error message to display.
  final String errorMsg;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FScaffold(
      child: Center(
        child: Padding(
          padding: const .all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              // Error icon
              Container(
                padding: const .all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FIcons.bug,
                  size: 64,
                  color: theme.colors.destructive,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Main title
              Text(
                context.l10n.pageNotFound,
                style: theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Description
              Text(
                context.l10n.pageNotFoundDescription,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Error message if provided
              if (errorMsg.isNotEmpty) ...[
                Container(
                  padding: const .all(AppSpacing.md),
                  margin: const .symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.theme.colors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMsg,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Action button
              Row(
                mainAxisAlignment: .center,
                children: [
                  FButton(
                    style: FButtonStyle.primary(),
                    onPress: () => context.go('/prayer'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FIcons.clock, size: 18),
                        SizedBox(width: AppSpacing.sm),
                        Text('Go to Prayer Page'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
