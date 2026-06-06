import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/icon_label.dart';
import 'package:tawaq/feature/settings/presentation/widgets/keyboard_shortcuts/keyboard_shortcuts_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/typography_settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Screen for application settings.
class SettingsScreen extends HookWidget {
  /// Creates a new [SettingsScreen] instance.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final l10n = context.l10n;

    final showKeyboardShortcuts = supportsKeyboardShortcuts;

    final entries = useMemoized(
      () => [
        (
          label: IconLabel(
            label: l10n.appearance,
            icon: FLucideIcons.palette,
            excludeIconSemantics: true,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              SettingsSection(
                title: l10n.colorTheme,
                subtitle: l10n.colorThemeSubtitle,
                child: const ColorThemeSelector(),
              ),
              SettingsSection(
                title: l10n.typographySectionTitle,
                subtitle: l10n.typographySectionSubtitle,
                child: const TypographySettingsSection(),
              ),
              const SizedBox(
                height: AppSpacing.lg,
              ),
            ],
          ),
        ),
        (
          label: IconLabel(
            label: l10n.timeSectionTitle,
            icon: FLucideIcons.clock,
            excludeIconSemantics: true,
          ),
          child: const PrayerSettingsTimeSection(maxWidth: 800),
        ),
        (
          label: IconLabel(
            label: l10n.locationSectionTitle,
            icon: FLucideIcons.mapPin,
            excludeIconSemantics: true,
          ),
          child: const PrayerSettingsLocationSection(maxWidth: 800),
        ),
        if (showKeyboardShortcuts)
          (
            label: IconLabel(
              label: l10n.keyboardShortcutsTabTitle,
              icon: FLucideIcons.keyboard,
              excludeIconSemantics: true,
            ),
            child: SettingsSection(
              title: l10n.keyboardShortcutsSectionTitle,
              subtitle: l10n.keyboardShortcutsSectionSubtitle,
              child: const KeyboardShortcutsSection(),
            ),
          ),
      ],
      [l10n, showKeyboardShortcuts],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            FTabs(
              control: .lifted(
                index: index.value,
                onChange: (i) => index.value = i,
              ),
              children: [
                for (final entry in entries)
                  .entry(label: entry.label, child: const SizedBox.shrink()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: KeyedSubtree(
                  key: ValueKey(index.value),
                  child: entries[index.value].child
                      .animate()
                      .fadeIn(duration: 200.ms, curve: Curves.easeOut)
                      .moveY(
                        begin: 12,
                        end: 0,
                        duration: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
