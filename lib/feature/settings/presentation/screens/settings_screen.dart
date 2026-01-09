import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/icon_label.dart';
import 'package:hasanat/feature/settings/presentation/widgets/app_theme_selector.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

/// Screen for application settings.
class SettingsScreen extends HookWidget {
  /// Creates a new [SettingsScreen] instance.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);

    final entries = useMemoized(
      () => [
        (
          label: IconLabel(
            label: context.l10n.appearance,
            icon: FIcons.palette,
          ),
          child: SettingsSection(
            title: context.l10n.colorTheme,
            subtitle: context.l10n.colorThemeSubtitle,
            child: const ColorThemeSelector(),
          ),
        ),
        (
          label: IconLabel(
            label: context.l10n.timeSectionTitle,
            icon: FIcons.clock,
          ),
          child: const PrayerSettingsTimeSection(maxWidth: 800),
        ),
        (
          label: IconLabel(
            label: context.l10n.locationSectionTitle,
            icon: FIcons.mapPin,
          ),
          child: const PrayerSettingsLocationSection(maxWidth: 800),
        ),
      ],
      [context.l10n],
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
