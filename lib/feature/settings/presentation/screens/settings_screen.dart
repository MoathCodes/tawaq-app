import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/icon_label.dart';
import 'package:tawaq/feature/settings/presentation/widgets/desktop_settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/keyboard_shortcuts/keyboard_shortcuts_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
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

  static const _maxContentWidth = 800.0;

  @override
  Widget build(BuildContext context) {
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
              const DesktopSettingsSection(),
            ],
          ),
        ),
        (
          label: IconLabel(
            label: l10n.timeSectionTitle,
            icon: FLucideIcons.clock,
            excludeIconSemantics: true,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              PrayerSettingsTimeSection(),
              PrayerAdhanSettingsSection(),
            ],
          ),
        ),
        (
          label: IconLabel(
            label: l10n.locationSectionTitle,
            icon: FLucideIcons.mapPin,
            excludeIconSemantics: true,
          ),
          child: const PrayerSettingsLocationSection(),
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

    final tabController = useTabController(initialLength: entries.length);
    final tabsStyle = context.theme.tabsStyle;

    return CenteredViewportShell(
      maxContentWidth: _maxContentWidth,
      header: DecoratedBox(
        decoration: tabsStyle.decoration,
        child: TabBar(
          controller: tabController,
          tabs: [
            for (final entry in entries)
              Tab(height: tabsStyle.height, child: entry.label),
          ],
          padding: tabsStyle.padding,
          indicator: tabsStyle.indicatorDecoration,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: tabsStyle.labelTextStyle.resolve({
            context.platformVariant,
            FTabVariant.selected,
          }),
          unselectedLabelStyle: tabsStyle.labelTextStyle.resolve({
            context.platformVariant,
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: tabsStyle.spacing),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final (i, entry) in entries.indexed)
                  centeredViewportScrollTab(
                    maxContentWidth: _maxContentWidth,
                    child: KeyedSubtree(
                      key: ValueKey('settings-tab-${entry.label.label}-$i'),
                      child: entry.child
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
