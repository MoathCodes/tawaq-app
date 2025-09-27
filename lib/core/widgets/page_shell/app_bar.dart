import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/theme_mode_button.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';

class ShellAppBar extends ConsumerWidget {
  const ShellAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(localeNotifierProvider);
    final locationName = ref.watch(
      prayerSettingsNotifierProvider.select(
        (value) => value.valueOrNull?.locationName,
      ),
    );
    // final formatter = DateFormat.E(appSettings.value);

    // final colors = FTheme.of(context).colors;

    final isArabic = appSettings.value?.languageCode == 'ar';

    final hijriStream = Stream.periodic(const Duration(seconds: 1), (_) {
      Hijriyah.setLocal(appSettings.value?.languageCode ?? 'en');
      final hijriDate = Hijriyah.fromDate(
        DateTime.now().toLocal(),
      ).toFormat('EEEE, dd MMMM yyyy');
      return hijriDate;
    });

    final Widget? locationChip =
        (locationName != null && locationName.isNotEmpty)
        ? Row(
            children: [
              Icon(
                FIcons.mapPin,
                size: 16,
                color: context.theme.colors.secondaryForeground,
              ),
              const SizedBox(width: 4),
              Text(locationName, overflow: TextOverflow.ellipsis),
            ],
          )
        : null;

    // Widget displayed next to the Sidebar.
    final nearWidgets = [
      ?locationChip,
      const Spacer(),
      StreamBuilder(
        stream: hijriStream,
        builder: (context, asyncSnapshot) {
          return Text(asyncSnapshot.data ?? '');
        },
      ),
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
          ref.read(localeNotifierProvider.notifier).toggleLocale();
        },
        prefix: const Icon(FIcons.languages),
        child: Text(isArabic ? context.l10n.arabic : context.l10n.english),
      ),
      const ThemeModeButton(),
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
              child: Row(children: nearWidgets),
            ),
          ),
          Expanded(
            child: Row(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.end,
              children: farWidgets,
            ),
          ),
        ],
        // prefixes: farWidgets,
        // suffixes: isArabic ? nearWidgets : farWidgets,
      ),
    );
  }
}
