import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/utils/hijri_provider.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_hint.dart';
import 'package:tawaq/core/widgets/theme_mode_button.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Compact shell actions (location, date, language, theme) laid out for the
/// title bar.
///
/// Returns a locale-directional row with [dragArea] as a draggable spacer in
/// the middle, so these controls share the title bar row with the window
/// controls instead of occupying a separate header row.
class ShellAppBar extends ConsumerWidget {
  /// Creates a new instance of [ShellAppBar].
  const ShellAppBar({required this.dragArea, super.key});

  /// The draggable window region placed between the leading and trailing
  /// action clusters.
  final Widget dragArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = ref.watch(prayerLocationNameProvider);

    final isArabic = context.l10n.localeName == 'ar';
    final showLanguageLabel = isAtLeast(context, FBreakpoint.md);

    final Widget? locationChip =
        (locationName != null && locationName.isNotEmpty)
        ? FButton(
            variant: .ghost,
            size: FButtonSizeVariant.xs,
            onPress: () => const SettingsRoute(
              $extra: kSettingsLocationTabKey,
            ).go(context),
            prefix: Icon(
              FLucideIcons.mapPin,
              size: 14,
              color: context.theme.colors.secondaryForeground,
            ),
            child: Text(
              resolveLocationDisplayName(context.l10n, locationName),
              overflow: TextOverflow.ellipsis,
            ),
          )
        : null;

    final languageButton = ShortcutTooltip(
      shortcut: AppShortcut.toggleLocale,
      child: showLanguageLabel
          ? FButton(
              variant: .ghost,
              size: FButtonSizeVariant.xs,
              onPress: () => ref.read(localeProvider.notifier).toggleLocale(),
              prefix: const Icon(FLucideIcons.languages, size: 14),
              child: Text(
                isArabic ? context.l10n.arabic : context.l10n.english,
              ),
            )
          : FButton.icon(
              variant: .ghost,
              size: FButtonSizeVariant.xs,
              onPress: () => ref.read(localeProvider.notifier).toggleLocale(),
              child: const Icon(FLucideIcons.languages, size: 14),
            ),
    );

    // The title bar is forced LTR so the window controls keep a fixed side;
    // restore the locale direction for these actions.
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Row(
            spacing: AppSpacing.lg,
            children: [
              ?locationChip,
              Consumer(
                builder: (context, ref, child) {
                  final hijriDate = ref.watch(hijriClockProvider);
                  return Text(
                    hijriDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
          Expanded(child: dragArea),
          Row(
            spacing: AppSpacing.sm,
            children: [
              languageButton,
              const ThemeModeButton(),
            ],
          ),
        ],
      ),
    );
  }
}
