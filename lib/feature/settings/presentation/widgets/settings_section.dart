import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/theme/theme.dart';

/// A section widget for displaying a specific setting.
class SettingsSection extends StatelessWidget {
  /// Creates a new [SettingsSection] instance.
  const SettingsSection({
    required this.child,
    required this.title,
    required this.subtitle,
    super.key,
    this.crossAxisAlignment = .stretch,
    this.leading,
    this.suffix,
  });

  /// The title of the section.
  final String title;

  /// The subtitle of the section.
  final String subtitle;

  /// The leading widget of the section.
  final Widget? leading;

  /// The suffix widget of the section.
  final Widget? suffix;

  /// The child widget of the section.
  final Widget child;

  /// The cross axis alignment of the section.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FCard(
      image: leading,
      style: (p0) => p0.copyWith(
        decoration: p0.decoration.copyWith(
          color: Colors.transparent,
          border: Border.all(color: Colors.transparent),
        ),
        contentStyle: (p0) => p0.copyWith(padding: EdgeInsets.zero),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          ?suffix,
        ],
      ),
      subtitle: Text(
        subtitle,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
