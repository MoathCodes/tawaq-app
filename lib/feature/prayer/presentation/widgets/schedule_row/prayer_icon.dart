import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme_extensions.dart';

/// Rounded icon container for a prayer in the schedule row.
class PrayerIcon extends ConsumerWidget {
  /// Creates a [PrayerIcon].
  const PrayerIcon({
    required this.prayer,
    required this.isActive,
    required this.colors,
    super.key,
  });

  /// The prayer whose icon to display.
  final Prayer prayer;

  /// Whether this prayer is the currently active one.
  final bool isActive;

  /// Theme colors for styling.
  final FColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    return ExcludeSemantics(
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.secondary,
          borderRadius: context.theme.radii.md,
        ),
        child: Center(
          child: Icon(
            prayer.icon,
            color: isActive
                ? colors.primaryForeground
                : colors.secondaryForeground,
            size: scaledSp(24, appScale),
          ),
        ),
      ),
    );
  }
}
