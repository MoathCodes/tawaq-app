import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ShellAppBar extends ConsumerWidget {
  const ShellAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final appSettings = ref.watch(localeNotifierProvider);

    final isArabic = appSettings.value?.languageCode == 'ar';

    return AppBar(
      leading: [
        OutlinedContainer(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 12,
            children: [
              const Icon(BootstrapIcons.pinAngle),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Saudi Arabia, Jeddah").small.bold,
                  Text(HijriDateTime.now().format(isArabic)),
                ],
              ),
            ],
          ),
        )
      ],
      trailing: [
        if (kDebugMode)
          PrimaryButton(
              child: const Icon(BootstrapIcons.bug),
              onPressed: () {
                context.go('/debug');
              }),
        Button.ghost(
            onPressed: () {
              ref.read(localeNotifierProvider.notifier).toggleLocale();
            },
            child: Text(isArabic ? context.l10n.arabic : context.l10n.english)),
        Button.ghost(
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).toggleThemeMode();
            },
            child: Icon(themeData.colorScheme.brightness == Brightness.light
                ? BootstrapIcons.sun
                : BootstrapIcons.moon)),
      ],
    );
  }
}
