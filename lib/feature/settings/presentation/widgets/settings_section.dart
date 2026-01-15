import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/theme/theme.dart';

/// A card widget for displaying settings.
class SettingsCard extends StatelessWidget {
  /// Creates a new [SettingsCard] instance.
  const SettingsCard({
    required this.title,
    required this.sections,
    super.key,
    this.subtitle,
    this.spacing = AppSpacing.sm,
  });

  /// The title of the card.
  final String title;

  /// The subtitle of the card.
  final String? subtitle;

  /// The spacing between sections.
  final double spacing;

  /// The sections to display in the card.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ScreenUtilPlus().screenWidth >= 1024 ? 0.50.sw : 1.sw,
        minHeight: 400,
      ),
      child: FCard(
        // titleAlignment:
        //     isArabic ? Alignment.centerRight : Alignment.centerLeft,
        // subtitleAlignment:
        //     isArabic ? Alignment.centerRight : Alignment.centerLeft,
        // leading: const Icon(Icons.settings),
        title: Text(title),
        style: (p0) => p0.copyWith(
          decoration: p0.decoration.copyWith(
            border: Border.all(color: theme.colors.border, width: 2),
          ),
        ),
        subtitle: (subtitle != null) ? Text(subtitle!) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: .stretch,
          spacing: spacing,
          children: [
            // Text(title).h3,
            Divider(color: theme.colors.foreground, thickness: .5, height: 16),
            ...sections,
          ],
        ),
      ),
    );
  }
}

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
    return FCard(
      // titleAlignment:
      //     isArabic ? Alignment.centerRight : Alignment.centerLeft,
      // subtitleAlignment:
      //     isArabic ? Alignment.centerRight : Alignment.centerLeft,
      image: leading,
      style: (p0) => p0.copyWith(
        decoration: p0.decoration.copyWith(
          // color: theme.colors.secondary,
          color: Colors.transparent,
          border: Border.all(color: Colors.transparent),
        ),
        contentStyle: (p0) => p0.copyWith(padding: .zero),
      ),
      title: Row(
        mainAxisAlignment: .spaceBetween,
        children: [Text(title), ?suffix],
      ),
      subtitle: Text(subtitle),
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
