import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/smooth_scroll.dart';
import 'package:hasanat/feature/settings/presentation/widgets/app_theme_selector.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        child: SingleChildScrollView(
      physics: const SmoothDesktopScrollPhysics(),
      child: Column(children: [
        SettingsCard(
          title: context.l10n.appearance,
          subtitle: context.l10n.appearanceSubtitle,
          sections: [
            SettingsSection(
              title: context.l10n.colorTheme,
              subtitle: context.l10n.colorThemeSubtitle,
              child: const AppThemeSelector(),
            ),
          ],
        ),
      ]),
    ));
  }
}
