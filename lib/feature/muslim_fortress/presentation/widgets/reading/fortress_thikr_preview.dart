import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Plain-text thikr excerpt for category browse previews (no mushaf widgets).
class FortressThikrPreviewText extends StatelessWidget {
  /// Creates a preview text block.
  const FortressThikrPreviewText({
    required this.dua,
    required this.isExpanded,
    super.key,
  });

  final FortressDuaItem dua;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isQuran = dua.isQuranicPassage;

    var style = theme.typography.body.sm.copyWith(
      color: isExpanded ? theme.colors.foreground : theme.colors.mutedForeground,
      height: isQuran ? 2 : 1.6,
      fontSize: isQuran ? (isExpanded ? 22 : 20) : null,
      fontWeight: isExpanded && isQuran ? FontWeight.w600 : FontWeight.w500,
    );
    if (isQuran) {
      style = style.copyWith(fontFamily: FontFamily.uthmanicHafs);
    }

    return Text(
      dua.text,
      style: style,
      textAlign: TextAlign.start,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
    );
  }
}
