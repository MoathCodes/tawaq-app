import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/theme/theme.dart';

/// Small badge showing the completion status of a prayer.
class StatusBadge extends StatelessWidget {
  /// Creates a [StatusBadge].
  const StatusBadge({required this.status, super.key});

  /// The completion status to display.
  final CompletionStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: status
            .getBadgeColor(context.theme.colors)
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.getLocaleName(context.l10n),
        style: TextStyle(
          color: status.getBadgeColor(context.theme.colors),
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
