import 'package:dyn_mouse_scroll/smooth_scroll_multiplatform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/widgets/app_theme_selector.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/prayer_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  // Cache commonly used timezones for better performance

  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DynMouseScroll(
      builder: (context, controller, physics) => SingleChildScrollView(
        physics: physics,
        controller: controller,
        child: Column(spacing: 12, children: [
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
          const PrayerSection()
        ]),
      ),
    );
  }
}
