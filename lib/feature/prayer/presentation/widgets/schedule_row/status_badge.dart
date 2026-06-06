import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Small badge showing the completion status of a prayer.
class StatusBadge extends ConsumerWidget {
  /// Creates a [StatusBadge].
  const StatusBadge({required this.status, super.key});

  /// The completion status to display.
  final CompletionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final colors = context.theme.colors;
    final badgeColor = status.getBadgeColor(colors);
    return ExcludeSemantics(
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.getLocaleName(context.l10n),
        style: TextStyle(
          color: badgeColor,
          fontSize: scaledSp(10, appScale),
          fontWeight: FontWeight.w600,
        ),
      ),
      ),
    );
  }
}
