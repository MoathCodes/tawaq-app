import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';

/// Compact prayer glyph for schedule rows.
class PrayerIcon extends StatelessWidget {
  /// Creates a [PrayerIcon].
  const new({
    required this.prayer,
    required this.isActive,
    required this.colors,
    this.status,
    super.key,
  });

  /// The prayer whose icon to display.
  final Prayer prayer;

  /// Whether this prayer is the currently active one.
  final bool isActive;

  /// Theme colors for styling.
  final FColors colors;

  /// Logged completion status, if any. `null` means still loading.
  final CompletionStatus? status;

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final statusColor = status != null && status != CompletionStatus.none
        ? status!.getBadgeColor(colors)
        : null;

    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: statusColor != null
              ? Border.all(color: statusColor, width: 2)
              : null,
        ),
        child: Icon(
          prayer.icon,
          color: isActive ? colors.primaryForeground : colors.foreground,
          size: theme.typography.body.lg.fontSize,
        ),
      ),
    );
  }
}
