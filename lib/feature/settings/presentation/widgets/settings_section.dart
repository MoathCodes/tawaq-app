import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double spacing;
  final List<Widget> sections;
  const SettingsCard({
    required this.title,
    required this.sections,
    super.key,
    this.subtitle,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ScreenUtil().screenWidth >= 1024 ? 0.50.sw : 1.sw,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

class SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? suffix;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;
  const SettingsSection({
    required this.child,
    required this.title,
    required this.subtitle,
    super.key,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.leading,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return HoverCard(
      padding: const EdgeInsets.all(8),
      child: FCard(
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
          contentStyle: (p0) => p0.copyWith(padding: const EdgeInsets.all(0)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(title), ?suffix],
        ),
        subtitle: Text(subtitle),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Divider(color: theme.colors.foreground, thickness: .5, height: 12),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
