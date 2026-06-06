import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

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
      style: .delta(
        decoration: .boxDelta(
          color: Colors.transparent,
          border: .all(color: Colors.transparent),
        ),
        // contentStyle: .delta(
        //   padding: .value(EdgeInsets.zero),
        // ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SettingsSemantics.sectionHeader(
            label: title,
            child: Text(
              title,
              style: theme.typography.md.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?suffix,
        ],
      ),
      subtitle: Semantics(
        label: subtitle,
        child: Text(
          subtitle,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
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
