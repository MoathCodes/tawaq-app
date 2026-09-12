import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_preview_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';

/// Icon preview control for the selected Adhan sound.
///
/// Sits next to its selector and shares one [adhanPreviewProvider] slot with
/// the iqamah control, so only one candidate sound plays at a time.
/// Previewing never changes the saved choice; applying stays on the selector
/// itself.
class AdhanSoundPreviewButton extends ConsumerWidget {
  /// Creates a preview button for [sound] shown as [label].
  const new({required this.sound, required this.label, super.key});

  /// Candidate sound to preview.
  final AdhanSound sound;

  /// Display name used for the preview track title.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.sound),
    );
    final ready = ref.watch(adhanSettingsProvider.select((s) => s.hasValue));
    final preview = ref.watch(adhanPreviewProvider);
    final volume = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.volume ?? 80),
    );
    _stopStalePreview(
      context,
      ref,
      preview.adhanSound,
      selected,
      preview.status,
    );
    return _PreviewButton(
      enabled: ready,
      active: ready && preview.isActiveAdhan(sound),
      loading:
          ready &&
          preview.isActiveAdhan(sound) &&
          preview.status == AdhanPreviewStatus.loading,
      hasError:
          ready &&
          preview.status == AdhanPreviewStatus.error &&
          preview.adhanSound == sound,
      onPress: ready
          ? () {
              unawaited(
                ref
                    .read(adhanPreviewProvider.notifier)
                    .previewAdhan(sound, label: label, volume: volume),
              );
            }
          : null,
    );
  }
}

/// Icon preview control for the selected Iqamah sound.
///
/// Sits next to its selector and shares one [adhanPreviewProvider] slot with
/// the adhan control, so only one candidate sound plays at a time.
class IqamahSoundPreviewButton extends ConsumerWidget {
  /// Creates a preview button for [sound] shown as [label].
  const new({required this.sound, required this.label, super.key});

  /// Candidate sound to preview.
  final IqamahSound sound;

  /// Display name used for the preview track title.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.iqamahSound),
    );
    final ready = ref.watch(adhanSettingsProvider.select((s) => s.hasValue));
    final preview = ref.watch(adhanPreviewProvider);
    final volume = ref.watch(
      adhanSettingsProvider.select((s) => s.value?.volume ?? 80),
    );
    _stopStalePreview(
      context,
      ref,
      preview.iqamahSound,
      selected,
      preview.status,
    );
    return _PreviewButton(
      enabled: ready,
      active: ready && preview.isActiveIqamah(sound),
      loading:
          ready &&
          preview.isActiveIqamah(sound) &&
          preview.status == AdhanPreviewStatus.loading,
      hasError:
          ready &&
          preview.status == AdhanPreviewStatus.error &&
          preview.iqamahSound == sound,
      onPress: ready
          ? () {
              unawaited(
                ref
                    .read(adhanPreviewProvider.notifier)
                    .previewIqamah(sound, label: label, volume: volume),
              );
            }
          : null,
    );
  }
}

/// Stops a preview whose candidate is no longer selected.
///
/// When the selector moves on while its old voice is still audible, the stale
/// preview is released instead of lingering under the new choice. Only the
/// button's own kind is considered, so the adhan and iqamah controls never
/// treat each other's preview as stale. Safe to evaluate when idle;
/// [AdhanPreview.stop] is a no-op then.
void _stopStalePreview(
  BuildContext context,
  WidgetRef ref,
  Object? previewTarget,
  Object? selectedSound,
  AdhanPreviewStatus status,
) {
  final stale =
      previewTarget != null &&
      previewTarget != selectedSound &&
      (status == AdhanPreviewStatus.loading ||
          status == AdhanPreviewStatus.playing);
  if (stale) {
    // Post-frame: never drive another provider while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        unawaited(ref.read(adhanPreviewProvider.notifier).stop());
      }
    });
  }
}

/// Shared compact preview button: play/stop icon plus error recovery.
class _PreviewButton extends StatelessWidget {
  const new({
    required this.enabled,
    required this.active,
    required this.loading,
    required this.hasError,
    required this.onPress,
  });

  /// Whether the adhan settings have finished hydrating.
  final bool enabled;

  /// Whether this candidate is the audible (or opening) preview.
  final bool active;

  /// Whether the preview asset is still opening.
  final bool loading;

  /// Whether the last preview of this candidate failed.
  final bool hasError;

  /// Toggles the preview.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = hasError
        ? l10n.previewFailed
        : active
        ? l10n.adhanStop
        : l10n.previewListen;
    return SizedBox(
      width: 44,
      height: 44,
      child: FButton.icon(
        semanticsLabel: message,
        semanticsTooltip: message,
        onPress: enabled ? onPress : null,
        child: loading
            ? const FCircularProgress(size: FCircularProgressSizeVariant.sm)
            : Icon(
                hasError && !active
                    ? FLucideIcons.circleAlert
                    : active
                    ? FLucideIcons.square
                    : FLucideIcons.play,
              ),
      ),
    );
  }
}
