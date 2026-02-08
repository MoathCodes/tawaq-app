import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/theme/theme.dart';

/// Pill-shaped widget showing the Hijri date.
class HijriDatePill extends StatelessWidget {
  /// Creates a [HijriDatePill].
  const HijriDatePill({required this.hijriDate, super.key});

  /// The async Hijri date string to display.
  final AsyncValue<String> hijriDate;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FIcons.calendar,
            color: Colors.white.withValues(alpha: 0.8),
            size: 14.sp,
          ),
          const SizedBox(width: AppSpacing.xs),
          switch (hijriDate) {
            AsyncData<String>(:final value) => Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
            ),
            _ => Text(
              '...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
            ),
          },
        ],
      ),
    );
  }
}
