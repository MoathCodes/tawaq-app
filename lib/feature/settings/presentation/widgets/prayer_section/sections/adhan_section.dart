import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/volume_slider.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/adhan_locale_extensions.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Adhan notification and sound controls with optional settings chrome.
class PrayerAdhanSettings extends ConsumerWidget {
  /// Creates [PrayerAdhanSettings].
  const new({this.chrome = SettingsChrome.none, super.key});

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ready = ref.watch(adhanSettingsProvider.select((s) => s.hasValue));
    final sound = ref.watch(
      adhanSettingsProvider.select(
        (s) => s.value?.sound ?? AdhanSound.misharyAlafasi,
      ),
    );
    final iqamahSound = ref.watch(
      adhanSettingsProvider.select(
        (s) => s.value?.iqamahSound ?? IqamahSound.misharyAlafasi,
      ),
    );
    final volume = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.volume ?? 80),
    );
    final showAdhanAlert = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.showAdhanAlert ?? true),
    );
    final showOsNotification = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.showOsNotification ?? true),
    );
    final alertPosition = ref.watch(
      adhanSettingsProvider.select(
        (s) => s.value?.alertPosition ?? AdhanAlertPosition.topEnd,
      ),
    );

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
              value: sound,
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
              value: iqamahSound,
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
            persistedVolume: volume,
            onPreview: (_) {},
            onCommit: (v) =>
                ref.read(adhanSettingsProvider.notifier).setVolume(v),
          ),
        ),
        const FDivider(),
        Column(
          spacing: AppSpacing.md,
          children: [
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: showAdhanAlert,
                onChange: (value) => ref
                    .read(adhanSettingsProvider.notifier)
                    .setShowAdhanAlert(value: value),
                label: Text(l10n.adhanShowAlertLabel),
              ),
            ),
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: showOsNotification,
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
              value: alertPosition,
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
