import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/hijri_provider.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/theme_mode_button.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// The app bar for the main shell.
class ShellAppBar extends ConsumerWidget {
  /// Creates a new instance of [ShellAppBar].
  const ShellAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(localeProvider);
    final locationName = ref.watch(
      prayerSettingsProvider.select((value) => value.value?.locationName),
    );
    // final formatter = DateFormat.E(appSettings.value);

    // final colors = FTheme.of(context).colors;

    final isArabic = appSettings.value?.languageCode == 'ar';

    final hijriDate = ref.watch(hijriClockProvider);

    final Widget? locationChip =
        (locationName != null && locationName.isNotEmpty)
        ? Row(
            children: [
              Icon(
                FIcons.mapPin,
                size: 16,
                color: context.theme.colors.secondaryForeground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(locationName, overflow: TextOverflow.ellipsis),
            ],
          )
        : null;

    // Widget displayed next to the Sidebar.
    final nearWidgets = [
      ?locationChip,
      const Spacer(),
      switch (hijriDate) {
        AsyncData<String>() => Text(hijriDate.value),
        _ => const SizedBox.shrink(),
      },
    ];

    final Widget? debugButton = kDebugMode
        ? FButton(
            style: FButtonStyle.primary(),
            child: const Icon(FIcons.bug),
            onPress: () {
              context.go('/wizard');
            },
          )
        : null;

    // Widgets displayed at the end from of the Sidebar
    final farWidgets = [
      ?debugButton,
      FButton(
        style: FButtonStyle.ghost(),
        onPress: () {
          ref.read(localeProvider.notifier).toggleLocale();
        },
        prefix: const Icon(FIcons.languages),
        child: Text(isArabic ? context.l10n.arabic : context.l10n.english),
      ),
      const ThemeModeButton(),
    ];

    return FHeader.nested(
      // prefixes: isArabic ? suffixes : prefixes,
      suffixes: [
        Expanded(
          flex: 2,
          child: HoverCard(
            padding: const .all(AppSpacing.sm),
            child: Row(children: nearWidgets),
          ),
        ),
        Expanded(
          child: Row(
            spacing: 4,
            mainAxisAlignment: .end,
            children: farWidgets,
          ),
        ),
      ],
      // prefixes: farWidgets,
      // suffixes: isArabic ? nearWidgets : farWidgets,
    );
  }
}
