import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/core/widgets/page_shell/hijri_date_chip.dart';
import 'package:tawaq/core/widgets/shell_a11y.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_hint.dart';
import 'package:tawaq/core/widgets/theme_mode_button.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_destination.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_display.dart';
import 'package:tawaq/theme/theme.dart';

/// The app bar for the main shell.
class ShellAppBar extends ConsumerWidget {
  /// Creates a new instance of [ShellAppBar].
  const ShellAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = ref.watch(prayerLocationNameProvider);

    final isArabic = context.l10n.localeName == 'ar';

    final Widget? locationChip =
        (locationName != null && locationName.isNotEmpty)
        ? FButton(
            variant: .outline,
            onPress: () => const SettingsRoute(
              $extra: SettingsLocationDestination(),
            ).go(context),
            child: Row(
              spacing: AppSpacing.xs,
              children: [
                Icon(
                  FLucideIcons.mapPin,
                  size: 16,
                  color: context.theme.colors.secondaryForeground,
                ),
                Text(
                  resolveLocationDisplayName(context.l10n, locationName),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        : null;

    final Widget? debugButton = kDebugMode
        ? MergedActionSemantics(
            label: ShellA11y.openSetupWizard(context.l10n),
            child: FButton(
              child: const Icon(FLucideIcons.bug),
              onPress: () {
                const WizardRoute().go(context);
              },
            ),
          )
        : null;

    return FHeader.nested(
      // prefixes: isArabic ? suffixes : prefixes,
      // suffixes: [
      //   Expanded(
      //     flex: 2,
      //     child: StaticCard(
      //       padding: const .all(AppSpacing.sm),
      //       child: Row(children: nearWidgets),
      //     ),
      //   ),
      //   Expanded(
      //     child: Row(
      //       spacing: 4,
      //       mainAxisAlignment: .end,
      //       children: farWidgets,
      //     ),
      //   ),
      // ],
      suffixes: [
        ?debugButton,
        const SizedBox(width: AppSpacing.sm),
        ShortcutTooltip(
          id: AppShortcutId.toggleLocale,
          child: FButton(
            variant: .ghost,
            onPress: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
            prefix: const Icon(FLucideIcons.languages),
            child: Text(isArabic ? context.l10n.arabic : context.l10n.english),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        const ThemeModeButton(),
      ],
      prefixes: [
        ?locationChip,
        const SizedBox(width: AppSpacing.sm),
        const HijriDateChip(),
      ],
    );
  }
}
