import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';

/// English / Arabic language picker for onboarding and settings.
class LocaleSelectTileGroup extends ConsumerWidget {
  /// Creates [LocaleSelectTileGroup].
  const LocaleSelectTileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider) == 'ar';

    return FSelectTileGroup<bool>(
      control: FMultiValueControl.managedRadio(
        initial: isArabic,
        onChange: (selected) {
          final next = selected.firstOrNull;
          if (next == null) return;
          ref.read(localeProvider.notifier).setLocale(
                Locale(next ? 'ar' : 'en'),
              );
        },
      ),
      children: [
        FSelectTile(
          value: false,
          title: Text(l10n.onboardingLanguageEnglish),
          subtitle: Text(l10n.onboardingLanguageEnglishSubtitle),
        ),
        FSelectTile(
          value: true,
          title: Text(l10n.onboardingLanguageArabic),
          subtitle: Text(l10n.onboardingLanguageArabicSubtitle),
        ),
      ],
    );
  }
}
