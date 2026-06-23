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
        children: [
          Expanded(
            child: SettingsSemantics.sectionHeader(
              label: title,
              child: Text(
                title,
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: crossAxisAlignment == CrossAxisAlignment.center
            ? Center(child: child)
            : child,
      ),
    );
  }
}

/// A labeled block inside a settings section — no card chrome.
class SettingsGroup extends StatelessWidget {
  /// Creates a [SettingsGroup].
  const SettingsGroup({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Optional group heading.
  final String? title;

  /// Optional helper text below the heading.
  final String? subtitle;

  /// Optional widget aligned with the heading (e.g. save action).
  final Widget? trailing;

  /// Group content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        if (title != null)
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: SettingsSemantics.sectionHeader(
                  label: title!,
                  child: Text(
                    title!,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        child,
      ],
    );
  }
}
