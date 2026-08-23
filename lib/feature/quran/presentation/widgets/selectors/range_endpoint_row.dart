import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_in_surah_select.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/theme/theme.dart';

/// A compact from/to row for the grouped custom-range card.
class RangeEndpointRow extends ConsumerWidget {
  /// Creates a [RangeEndpointRow].
  const new({
    required this.prefix,
    required this.surah,
    required this.ayah,
    required this.surahLabel,
    required this.ayahLabel,
    required this.onSurahChanged,
    required this.onAyahChanged,
    this.enabled = true,
    super.key,
  });

  /// Short prefix label (e.g. "From" / "To").
  final String prefix;

  /// Selected surah number.
  final int surah;

  /// Selected ayah number within [surah].
  final int ayah;

  /// Accessibility label for the surah field.
  final String surahLabel;

  /// Accessibility label for the ayah field.
  final String ayahLabel;

  /// Called when the surah changes.
  final ValueChanged<int> onSurahChanged;

  /// Called when the ayah changes.
  final ValueChanged<int> onAyahChanged;

  /// Whether the controls accept input.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final prefixStyle = theme.typography.body.sm.copyWith(
      color: theme.colors.mutedForeground,
      fontWeight: FontWeight.w500,
    );

    Widget controls({required bool stacked}) {
      final surahSelect = SurahSearchSelect(
        value: surah,
        label: surahLabel,
        showLabel: false,
        size: FTextFieldSizeVariant.sm,
        enabled: enabled,
        onChanged: onSurahChanged,
      );
      final ayahSelect = AyahInSurahSelect(
        surah: surah,
        ayah: ayah,
        label: ayahLabel,
        enabled: enabled,
        compact: true,
        onChanged: onAyahChanged,
      );

      if (stacked) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            surahSelect,
            const SizedBox(height: AppSpacing.sm),
            ayahSelect,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: surahSelect),
          const SizedBox(width: AppSpacing.sm),
          ayahSelect,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Container width inside the range dialog (~336px), not viewport sm.
        final stacked = constraints.maxWidth < 280;

        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prefix, style: prefixStyle),
              const SizedBox(height: AppSpacing.sm),
              controls(stacked: true),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(prefix, style: prefixStyle),
            ),
            Expanded(child: controls(stacked: false)),
          ],
        );
      },
    );
  }
}
