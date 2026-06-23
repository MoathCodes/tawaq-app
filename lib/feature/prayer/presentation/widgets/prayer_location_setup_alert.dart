import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/theme/theme.dart';

const _kMaxAlertWidth = 420.0;

/// Prompts the user to set prayer location when coordinates are still unset.
class PrayerLocationSetupAlert extends StatelessWidget {
  /// Creates [PrayerLocationSetupAlert].
  const PrayerLocationSetupAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kMaxAlertWidth),
      child: StaticCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    FLucideIcons.mapPin,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        l10n.prayerLocationRequiredTitle,
                        style: theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      Text(
                        l10n.prayerLocationRequiredSubtitle,
                        style: theme.typography.body.sm.copyWith(
                          color: colors.mutedForeground,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FButton(
              mainAxisSize: MainAxisSize.min,
              onPress: () => const OnboardingRoute().go(context),
              prefix: const Icon(FLucideIcons.mapPin, size: 16),
              child: Text(l10n.onboardingOpenSetupAction),
            ),
          ],
        ),
      ),
    );
  }
}
