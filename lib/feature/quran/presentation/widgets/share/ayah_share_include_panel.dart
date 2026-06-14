import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_include.dart';

/// Multi-select panel for share image include options.
class AyahShareIncludePanel extends StatelessWidget {
  /// Creates the include options panel.
  const AyahShareIncludePanel({
    required this.selected,
    required this.basmalahAvailable,
    required this.lineBreaksToggleAvailable,
    required this.onChanged,
    super.key,
  });

  /// Currently selected include options.
  final Set<AyahShareInclude> selected;

  /// Whether basmalah can be shown for the current ayah range.
  final bool basmalahAvailable;

  /// Whether the partial-page line-break toggle should appear.
  final bool lineBreaksToggleAvailable;

  /// Called when the selected include options change.
  final ValueChanged<Set<AyahShareInclude>> onChanged;

  void _handleChange(Set<AyahShareInclude> value) {
    var next = value;
    if (!basmalahAvailable) {
      next = next.difference({AyahShareInclude.basmalah});
    }
    if (!lineBreaksToggleAvailable) {
      next = next.difference({AyahShareInclude.preserveLineBreaks});
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FSelectTileGroup<AyahShareInclude>(
      label: Text(l10n.shareIncludeInImage),
      control: .lifted(value: selected, onChange: _handleChange),
      children: [
        FSelectTile(
          value: AyahShareInclude.surahHeader,
          title: Text(l10n.shareSurahHeader),
        ),
        if (basmalahAvailable)
          FSelectTile(
            value: AyahShareInclude.basmalah,
            title: Text(l10n.shareBasmalah),
          ),
        if (lineBreaksToggleAvailable)
          FSelectTile(
            value: AyahShareInclude.preserveLineBreaks,
            title: Text(l10n.sharePreserveLineBreaks),
          ),
        FSelectTile(
          value: AyahShareInclude.appName,
          title: Text(l10n.shareAppName),
        ),
      ],
    );
  }
}
