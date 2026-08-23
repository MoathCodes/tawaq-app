import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// [TextInputFormatter] for ayah input that converts Hindu-Arabic numerals and
/// filters non-digit characters.
class AyahInputFormatter extends TextInputFormatter {
  const new();

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
  const new({
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
      fallbackName: '',
    );
  }

  String _ayahReference(
    AppLocalizations l10n,
    String surahName,
    int ayahNumber,
  ) => l10n.surahAyahInfo(surahName, ayahNumber);

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
          children: [
            NumericStepButton(
              icon: FLucideIcons.chevronsLeft,
              enabled: enabled && ayah > 1,
              onPress: () => setAyah(1),
              semanticsLabel: l10n.quranRangeFirstAyah,
              tooltip: l10n.quranRangeFirstAyah,
            ),
            const SizedBox(width: AppSpacing.xs),
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
            const SizedBox(width: AppSpacing.xs),
            NumericStepButton(
              icon: FLucideIcons.chevronsRight,
              enabled: enabled && ayah < ayahCount,
              onPress: () => setAyah(ayahCount),
              semanticsLabel: l10n.quranRangeLastAyah,
              tooltip: l10n.quranRangeLastAyah,
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
