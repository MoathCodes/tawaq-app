import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_number_search.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Localized label for a repeat count (1, 2, or N times).
String repeatCountLabel(AppLocalizations l10n, int count) {
  return switch (count) {
    1 => l10n.quranRangeRepeatOnce,
    2 => l10n.quranRangeRepeatTwice,
    _ => l10n.quranRangeRepeatTimes(count),
  };
}

/// Searchable ayah picker within a surah for range endpoint editing.
class AyahInSurahSelect extends ConsumerWidget {
  /// Creates an [AyahInSurahSelect].
  const AyahInSurahSelect({
    required this.surah,
    required this.ayah,
    required this.onChanged,
    required this.label,
    this.enabled = true,
    this.compact = false,
    super.key,
  });

  /// Selected surah number (1–114).
  final int surah;

  /// Selected ayah number within [surah].
  final int ayah;

  /// Called when the user picks a different ayah.
  final ValueChanged<int> onChanged;

  /// Field label shown above the control (full layout only).
  final String label;

  /// Whether the control accepts input.
  final bool enabled;

  /// When true, renders a horizontal inline stepper without an outer card.
  final bool compact;

  String _surahName(
    MushafReaderController mushaf,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final surahMeta = mushaf.getSurahSync(surah);
    return AyahReferenceLogic.surahName(
      surahMeta,
      surah,
      preferArabic: isArabic,
      fallbackName: l10n.surahNameDefault(surah),
    );
  }

  String _ayahReference(
    AppLocalizations l10n,
    String surahName,
    int ayahNumber,
  ) =>
      l10n.surahAyahInfo(surahName, ayahNumber);

  Widget _ayahSelect(
    BuildContext context,
    WidgetRef ref, {
    required MushafReaderController mushaf,
    required AppLocalizations l10n,
    required bool isArabic,
    required int ayahCount,
    required String surahName,
    required TextStyle itemStyle,
  }) {
    final theme = context.theme;

    void setAyah(int v) => onChanged(v.clamp(1, ayahCount));

    return FSelect<int>.searchBuilder(
      enabled: enabled,
      label: compact ? const SizedBox.shrink() : Text(label),
      contentConstraints: selectPopoverPortalConstraints(context),
      style: selectStyle(
        colors: theme.colors,
        style: theme.style,
        typography: theme.typography,
        useQuranFont: isArabic,
      ),
      control: FSelectControl.lifted(
        value: ayah,
        onChange: (v) {
          if (v != null) setAyah(v);
        },
      ),
      format: (v) => compact ? '$v' : _ayahReference(l10n, surahName, v),
      filter: (q) => searchAyahNumbers(ayahCount: ayahCount, query: q),
      contentBuilder: (_, _, vals) => vals
          .map(
            (v) {
              final reference = _ayahReference(l10n, surahName, v);
              return FSelectItem<int>(
                value: v,
                title: isArabic
                    ? AyahReferenceText(reference, style: itemStyle)
                    : Text(reference, style: itemStyle),
              );
            },
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mushaf = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final ayahCount = mushaf.getSurahSync(surah)?.ayahCount ?? ayah;
    final surahName = _surahName(mushaf, l10n, isArabic);
    final itemStyle = theme.typography.body.sm;

    void setAyah(int v) => onChanged(v.clamp(1, ayahCount));

    final select = _ayahSelect(
      context,
      ref,
      mushaf: mushaf,
      l10n: l10n,
      isArabic: isArabic,
      ayahCount: ayahCount,
      surahName: surahName,
      itemStyle: itemStyle,
    );

    if (compact) {
      return QuranSemantics.labeledControl(
        name: label,
        value: _ayahReference(l10n, surahName, ayah),
        enabled: enabled,
        excludeChild: true,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colors.background,
            border: Border.all(color: theme.colors.border),
            borderRadius: theme.radii.lg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NumericStepButton(
                icon: FLucideIcons.minus,
                enabled: enabled && ayah > 1,
                onPress: () => setAyah(ayah - 1),
                semanticsLabel: l10n.back,
                tooltip: l10n.back,
              ),
              SizedBox(
                width: 52,
                child: select,
              ),
              NumericStepButton(
                icon: FLucideIcons.plus,
                enabled: enabled && ayah < ayahCount,
                onPress: () => setAyah(ayah + 1),
                semanticsLabel: l10n.next,
                tooltip: l10n.next,
              ),
            ],
          ),
        ),
      );
    }

    return QuranSemantics.labeledControl(
      name: label,
      value: _ayahReference(l10n, surahName, ayah),
      enabled: enabled,
      excludeChild: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          border: Border.all(color: theme.colors.border),
          borderRadius: theme.radii.lg,
        ),
        child: Row(
          children: [
            Expanded(child: select),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NumericStepButton(
                  icon: FLucideIcons.plus,
                  enabled: enabled && ayah < ayahCount,
                  onPress: () => setAyah(ayah + 1),
                  semanticsLabel: l10n.next,
                  tooltip: l10n.next,
                ),
                const SizedBox(height: AppSpacing.xs),
                NumericStepButton(
                  icon: FLucideIcons.minus,
                  enabled: enabled && ayah > 1,
                  onPress: () => setAyah(ayah - 1),
                  semanticsLabel: l10n.back,
                  tooltip: l10n.back,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact from/to row for the grouped custom-range card.
class RangeEndpointRow extends ConsumerWidget {
  /// Creates a [RangeEndpointRow].
  const RangeEndpointRow({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

/// Formats a global range for display in the player chrome.
String formatAyahRangeLabel({
  required MushafReaderController mushaf,
  required AppLocalizations l10n,
  required AyahReference from,
  required AyahReference to,
}) {
  String refLabel(AyahReference r) {
    final name =
        mushaf.getSurahSync(r.surah)?.displayName ??
        l10n.quranSurahLabel('${r.surah}');
    return '$name · ${r.ayah}';
  }

  if (from.surah == to.surah && from.ayah == to.ayah) {
    return refLabel(from);
  }
  if (from.surah == to.surah) {
    final name =
        mushaf.getSurahSync(from.surah)?.displayName ??
        l10n.quranSurahLabel('${from.surah}');
    return '$name · ${from.ayah}–${to.ayah}';
  }
  return '${refLabel(from)} → ${refLabel(to)}';
}
