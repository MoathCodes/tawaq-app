import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
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

/// Converts Hindu-Arabic numerals (٠-٩) to standard and strips non-digits.
String normalizeAyahInput(String input) {
  return input
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll(RegExp('[^0-9]'), '');
}

/// [TextInputFormatter] for ayah input that converts Hindu-Arabic numerals and
/// filters non-digit characters.
class AyahInputFormatter extends TextInputFormatter {
  const AyahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final normalized = normalizeAyahInput(newValue.text);
    if (normalized != newValue.text) {
      return TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    return newValue;
  }
}

/// Inline ayah input within a surah for range endpoint editing.
class AyahInSurahSelect extends HookConsumerWidget {
  const AyahInSurahSelect({
    required this.surah,
    required this.ayah,
    required this.onChanged,
    required this.label,
    this.enabled = true,
    this.compact = false,
    super.key,
  });

  final int surah;
  final int ayah;
  final ValueChanged<int> onChanged;
  final String label;
  final bool enabled;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mushaf = ref.watch(quranMushafControllerProvider);
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final ayahCount = mushaf.getSurahSync(surah)?.ayahCount ?? ayah;
    final surahName = _surahName(mushaf, l10n, isArabic);

    final controller = useTextEditingController(text: '$ayah');
    final focusNode = useFocusNode();

    void setAyah(int v) {
      final clamped = v.clamp(1, ayahCount);
      controller
        ..text = '$clamped'
        ..selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      onChanged(clamped);
    }

    void handleSubmitted(String value) {
      final normalized = normalizeAyahInput(value);
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        setAyah(parsed);
      } else {
        controller
          ..text = '$ayah'
          ..selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
      }
    }

    useEffect(() {
      if (!focusNode.hasFocus && controller.text != '$ayah') {
        controller.text = '$ayah';
      }
      return null;
    }, [ayah, surah]);

    if (compact) {
      return QuranSemantics.labeledControl(
        name: label,
        value: _ayahReference(l10n, surahName, ayah),
        enabled: enabled,
        excludeChild: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            NumericStepButton(
              icon: FLucideIcons.minus,
              enabled: enabled && ayah > 1,
              onPress: () => setAyah(ayah - 1),
              semanticsLabel: l10n.back,
              tooltip: l10n.back,
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 68,
              child: FTextField(
                control: FTextFieldControl.managed(
                  controller: controller,
                ),
                focusNode: focusNode,
                size: FTextFieldSizeVariant.sm,
                textAlign: TextAlign.center,
                inputFormatters: const [AyahInputFormatter()],
                onSubmit: handleSubmitted,
                onTapOutside: (_) => handleSubmitted(controller.text),
                enabled: enabled,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            NumericStepButton(
              icon: FLucideIcons.plus,
              enabled: enabled && ayah < ayahCount,
              onPress: () => setAyah(ayah + 1),
              semanticsLabel: l10n.next,
              tooltip: l10n.next,
            ),
          ],
        ),
      );
    }

    return QuranSemantics.labeledControl(
      name: label,
      value: _ayahReference(l10n, surahName, ayah),
      enabled: enabled,
      excludeChild: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: controller,
              ),
              focusNode: focusNode,
              label: Text(label),
              inputFormatters: const [AyahInputFormatter()],
              onSubmit: handleSubmitted,
              onTapOutside: (_) => handleSubmitted(controller.text),
              enabled: enabled,
            ),
          ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
///
/// A null [to] means the range is open-ended and continues to the end of the
/// Quran.
String formatAyahRangeLabel({
  required MushafReaderController mushaf,
  required AppLocalizations l10n,
  required AyahReference from,
  required AyahReference? to,
}) {
  String refLabel(AyahReference r) {
    final name =
        mushaf.getSurahSync(r.surah)?.displayName ??
        l10n.quranSurahLabel('${r.surah}');
    return '$name · ${r.ayah}';
  }

  if (to == null) {
    return '${refLabel(from)} → ${l10n.quranRangePresetContinueFromHere}';
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
