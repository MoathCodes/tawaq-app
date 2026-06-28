import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/volume_slider.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/adhan_locale_extensions.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Adhan notification and sound controls with optional settings chrome.
class PrayerAdhanSettings extends HookConsumerWidget {
  /// Creates [PrayerAdhanSettings].
  const PrayerAdhanSettings({this.chrome = SettingsChrome.none, super.key});

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(adhanSettingsProvider).value;
    final ready = settings != null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        SettingsGroup(
          title: l10n.adhanSoundLabel,
          child: FSelect<AdhanSound>(
            enabled: ready,
            contentConstraints: selectPopoverPortalConstraints(context),
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
            contentConstraints: selectPopoverPortalConstraints(context),
            control: .lifted(
              value: settings?.iqamahSound ?? IqamahSound.misharyAlafasi,
              onChange: (value) {
                if (value == null) return;
                ref.read(adhanSettingsProvider.notifier).setIqamahSound(value);
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
          child: PersistedVolumeSlider(
            enabled: ready,
            persistedVolume: settings?.volume ?? 80,
            onPreview: (v) =>
                ref.read(adhanSettingsProvider.notifier).setVolumePreview(v),
            onCommit: (v) =>
                ref.read(adhanSettingsProvider.notifier).commitVolume(v),
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
            contentConstraints: selectPopoverPortalConstraints(context),
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
              l10n.adhanAlertPositionTopStart: AdhanAlertPosition.topStart,
              l10n.adhanAlertPositionCenter: AdhanAlertPosition.center,
            },
          ),
        ),
      ],
    );

    if (chrome == SettingsChrome.none) return content;
    if (!isDesktopPlatform) return const SizedBox.shrink();

    return SettingsSection(
      title: l10n.adhanSectionTitle,
      subtitle: l10n.adhanSectionSubtitle,
      child: content,
    );
  }
}
