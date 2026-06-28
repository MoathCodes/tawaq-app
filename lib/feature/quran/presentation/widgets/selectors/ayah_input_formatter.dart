import 'package:flutter/services.dart';

import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';

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
