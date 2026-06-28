import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared section label row for fortress study panels (sharh, hadith, source).
class FortressStudySectionHeader extends StatelessWidget {
  /// Creates a study section header.
  const FortressStudySectionHeader({
    required this.icon,
    required this.title,
    this.prominent = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(
            icon,
            size: prominent ? 20 : 16,
            color: prominent ? colors.primary : colors.mutedForeground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: (prominent ? typography.body.md : typography.body.sm).copyWith(
              fontWeight: prominent ? FontWeight.w700 : FontWeight.w600,
              color: prominent ? colors.primary : colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
