import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/adhan_locale_extensions.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Adhan notification and sound settings (desktop-focused).
class PrayerAdhanSettingsSection extends HookConsumerWidget {
  /// Creates [PrayerAdhanSettingsSection].
  const PrayerAdhanSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktopPlatform) return const SizedBox.shrink();

    final l10n = context.l10n;
    final settings = ref.watch(adhanSettingsProvider).value;
    final ready = settings != null;
    final volume = useState(settings?.volume ?? 80);

    useEffect(
      () {
        volume.value = settings?.volume ?? 80;
        return null;
      },
      [settings?.volume],
    );

    return SettingsSection(
      title: l10n.adhanSectionTitle,
      subtitle: l10n.adhanSectionSubtitle,
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
              SettingsGroup(
                title: l10n.adhanSoundLabel,
                child: FSelect<AdhanSound>(
                  enabled: ready,
                  control: .lifted(
                    value: settings?.sound ?? AdhanSound.misharyAlafasi,
                    onChange: (value) {
                      if (value == null) return;
                      ref.read(adhanSettingsProvider.notifier).setSound(value);
                    },
                  ),
                  items: {
                    for (final sound in AdhanSound.values)
                      sound.getLocaleName(l10n): sound,
                  },
                ),
              ),
              const FDivider(),
              SettingsGroup(
                title: l10n.iqamahSoundLabel,
                child: FSelect<IqamahSound>(
                  enabled: ready,
                  control: .lifted(
                    value: settings?.iqamahSound ?? IqamahSound.misharyAlafasi,
                    onChange: (value) {
                      if (value == null) return;
                      ref
                          .read(adhanSettingsProvider.notifier)
                          .setIqamahSound(value);
                    },
                  ),
                  items: {
                    for (final sound in IqamahSound.values)
                      sound.getLocaleName(l10n): sound,
                  },
                ),
              ),
              const FDivider(),
              SettingsGroup(
                title: l10n.adhanVolumeLabel,
                child: FSlider(
                  enabled: ready,
                  control: .managedContinuous(
                    initial: FSliderValue(max: volume.value / 100),
                    onChange: (value) {
                      final next = (value.max * 100).clamp(0, 100).toDouble();
                      volume.value = next;
                      ref.read(adhanSettingsProvider.notifier).setVolume(next);
                    },
                  ),
                  label: Text('${volume.value.round()}%'),
                ),
              ),
              const FDivider(),
              Column(
                spacing: AppSpacing.md,
                children: [
                  NonSelectable(
                    child: FSwitch(
                      enabled: ready,
                      value: settings?.showAdhanAlert ?? true,
                      onChange: (value) => ref
                          .read(adhanSettingsProvider.notifier)
                          .setShowAdhanAlert(value: value),
                      label: Text(l10n.adhanShowAlertLabel),
                    ),
                  ),
                  NonSelectable(
                    child: FSwitch(
                      enabled: ready,
                      value: settings?.showOsNotification ?? true,
                      onChange: (value) => ref
                          .read(adhanSettingsProvider.notifier)
                          .setShowOsNotification(value: value),
                      label: Text(l10n.adhanShowOsNotificationLabel),
                    ),
                  ),
                ],
              ),
              const FDivider(),
              SettingsGroup(
                title: l10n.adhanAlertPositionLabel,
                child: FSelect<AdhanAlertPosition>(
                  enabled: ready,
                  control: .lifted(
                    value: settings?.alertPosition ?? AdhanAlertPosition.topEnd,
                    onChange: (value) {
                      if (value == null) return;
                      ref
                          .read(adhanSettingsProvider.notifier)
                          .setAlertPosition(value);
                    },
                  ),
                  items: {
                    l10n.adhanAlertPositionTopEnd: AdhanAlertPosition.topEnd,
                    l10n.adhanAlertPositionTopStart:
                        AdhanAlertPosition.topStart,
                    l10n.adhanAlertPositionCenter: AdhanAlertPosition.center,
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
