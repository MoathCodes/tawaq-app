import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/animated_icon_button.dart';
import 'package:hasanat/core/widgets/hover_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';

class ShellAppBar extends ConsumerWidget {
  const ShellAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final appSettings = ref.watch(localeNotifierProvider);
    // final formatter = DateFormat.E(appSettings.value);

    // final colors = FTheme.of(context).colors;

    final isArabic = appSettings.value?.languageCode == 'ar';
    final hijri = Hijriyah.fromDate(DateTime.now().toLocal(), isPasaran: false)
        .toFormat("EEEE, dd, MMMM(mm), yyyy")
        .toString();
    // Widget displayed next to the Sidebar.
    final nearWidgets = [
      Icon(
        FIcons.pin,
        size: 18,
        color: themeMode.value?.themeMode == ThemeMode.dark
            ? Colors.white
            : Colors.black,
      ),
      const SizedBox(
        width: 4,
      ),
      const Text(
        "Saudi Arabia, Medina",
      ),
      const Spacer(),
      Text(hijri),
    ];

    // Widgets displayed at the end from of the Sidebar
    final farWidgets = [
      if (kDebugMode)
        FButton(
            style: FButtonStyle.primary(),
            child: const Icon(FIcons.bug),
            onPress: () {
              context.go('/debug1');
            }),
      FButton(
          style: FButtonStyle.ghost(),
          onPress: () {
            ref.read(localeNotifierProvider.notifier).toggleLocale();
          },
          prefix: const Icon(FIcons.languages),
          child: Text(isArabic ? context.l10n.arabic : context.l10n.english)),
      if (themeMode.value?.themeMode == ThemeMode.light)
        AnimatedIconButton(
          primaryIcon: FIcons.sun,
          secondaryIcon: FIcons.moon,
          buttonStyle: FButtonStyle.ghost(),
          isSecondaryActive: themeMode.value?.themeMode == ThemeMode.dark,
          onPressed: () {
            ref.read(themeNotifierProvider.notifier).toggleThemeMode();
          },
        ),
    ];

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: FHeader.nested(
          // prefixes: isArabic ? suffixes : prefixes,
          suffixes: [
            Expanded(
                flex: 2,
                child: HoverCard(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: nearWidgets,
                  ),
                )),
            Expanded(
              child: Row(
                spacing: 4,
                mainAxisAlignment: MainAxisAlignment.end,
                children: farWidgets,
              ),
            )
          ],
          // prefixes: farWidgets,
          // suffixes: isArabic ? nearWidgets : farWidgets,
        ));
  }
}
