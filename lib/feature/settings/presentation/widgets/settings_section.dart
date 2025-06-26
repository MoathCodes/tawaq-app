import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SettingsSection> sections;
  const SettingsCard(
      {super.key, required this.title, required this.sections, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.l10n.localeName == 'ar';
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 0.75.sw, minHeight: 400),
      child: OutlinedContainer(
        backgroundColor: theme.colorScheme.secondary,
        borderColor: theme.colorScheme.foreground.withAlpha(100),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Basic(
              titleAlignment:
                  isArabic ? Alignment.centerRight : Alignment.centerLeft,
              subtitleAlignment:
                  isArabic ? Alignment.centerRight : Alignment.centerLeft,
              // leading: const Icon(Icons.settings),
              title: Text(title).h3,
              subtitle: subtitle != null ? Text(subtitle!) : null,
            ),
            // Text(title).h3,
            Divider(
              color: theme.colorScheme.foreground,
              thickness: .5,
              height: 48,
            ),
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
  final Widget child;
  const SettingsSection(
      {super.key,
      required this.child,
      required this.title,
      required this.subtitle,
      this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.l10n.localeName == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Basic(
          titleAlignment:
              isArabic ? Alignment.centerRight : Alignment.centerLeft,
          subtitleAlignment:
              isArabic ? Alignment.centerRight : Alignment.centerLeft,
          leading: leading,
          title: Text(title).bold.h4,
          subtitle: Text(subtitle),
        ),
        Divider(
          color: theme.colorScheme.foreground,
          thickness: .5,
          height: 12,
        ),
        const Gap(12),
        child,
      ],
    );
  }
}
