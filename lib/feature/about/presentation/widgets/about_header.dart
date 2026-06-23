import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/theme/theme.dart';

const _kLogoSize = 84.0;

/// The hero header of the about dialog: app icon, name, version and tagline.
class AboutHeader extends StatelessWidget {
  /// Creates an [AboutHeader].
  const AboutHeader({required this.content, super.key});

  /// The content to render.
  final AboutContent content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: theme.radii.xl,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: theme.radii.xl,
            child: Assets.images.appIcon.image(
              width: _kLogoSize,
              height: _kLogoSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          content.appName,
          textAlign: TextAlign.center,
          style: typography.body.xl2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content.latinName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography.body.sm.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FBadge(
          variant: FBadgeVariant.secondary,
          child: Text(content.version),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content.tagline.resolve(context),
          textAlign: TextAlign.center,
          style: typography.body.sm.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}
