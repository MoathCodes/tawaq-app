import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// A screen that is displayed when a route is not found.
class NotFoundScreen extends StatelessWidget {
  /// Creates a not found screen.
  const NotFoundScreen({required this.errorMsg, super.key});

  /// The error message to display.
  final String errorMsg;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const .all(AppSpacing.xl),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                padding: const .all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FLucideIcons.bug,
                  size: 64,
                  color: theme.colors.destructive,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            Semantics(
              header: true,
              child: Text(
                context.l10n.pageNotFound,
                style: theme.typography.body.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              context.l10n.pageNotFoundDescription,
              style: theme.typography.body.lg.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

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
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            FButton(
              onPress: () => const PrayerRoute().go(context),
              prefix: const Icon(FLucideIcons.clock, size: 18),
              child: Text(context.l10n.goToPrayerPage),
            ),
          ],
        ),
      ),
    );
  }
}
