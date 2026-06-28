import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/theme/theme.dart';

/// Filter chips for the reciter dialog search bar.
class ReciterDialogFilterBar extends StatelessWidget {
  /// Creates the filter bar.
  const ReciterDialogFilterBar({
    required this.downloadedFilter,
    required this.styleFilter,
    required this.riwayahFilter,
    required this.riwayahOptions,
    super.key,
  });

  /// Downloaded-only filter toggle.
  final ValueNotifier<bool> downloadedFilter;

  /// Selected recitation styles.
  final ValueNotifier<Set<RecitationStyle>> styleFilter;

  /// Selected riwayah names.
  final ValueNotifier<Set<String>> riwayahFilter;

  /// Distinct riwayah labels from the catalog.
  final List<String> riwayahOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterChip(
          label: l10n.quranReciterFilterDownloaded,
          active: downloadedFilter.value,
          onPress: () => downloadedFilter.value = !downloadedFilter.value,
        ),
        _FilterChip(
          label: l10n.quranReciterStyleMurattal,
          active: styleFilter.value.contains(RecitationStyle.murattal),
          onPress: () => styleFilter.value = _toggle(
            styleFilter.value,
            RecitationStyle.murattal,
          ),
        ),
        _FilterChip(
          label: l10n.quranReciterStyleMujawwad,
          active: styleFilter.value.contains(RecitationStyle.mujawwad),
          onPress: () => styleFilter.value = _toggle(
            styleFilter.value,
            RecitationStyle.mujawwad,
          ),
        ),
        for (final riwayah in riwayahOptions)
          _FilterChip(
            label: riwayah,
            active: riwayahFilter.value.contains(riwayah),
            onPress: () =>
                riwayahFilter.value = _toggle(riwayahFilter.value, riwayah),
          ),
      ],
    );
  }

  static Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.remove(value)) next.add(value);
    return next;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onPress,
  });

  final String label;
  final bool active;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: active ? FButtonVariant.primary : FButtonVariant.outline,
      size: FButtonSizeVariant.sm,
      mainAxisSize: MainAxisSize.min,
      onPress: onPress,
      child: Text(label),
    );
  }
}
