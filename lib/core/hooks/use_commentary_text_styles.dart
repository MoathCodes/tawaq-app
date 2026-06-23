import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';

/// Memoized [CommentaryTextStyles] derived from theme colors and [baseStyle].
CommentaryTextStyles useCommentaryTextStyles({
  required TextStyle baseStyle,
  required FColors colors,
  required bool isDark,
  bool useUthmanTnProse = false,
  bool includeSelectionStrut = true,
}) {
  return useMemoized(
    () => CommentaryTextStyles.from(
      baseStyle: baseStyle,
      colors: colors,
      isDark: isDark,
      useUthmanTnProse: useUthmanTnProse,
      includeSelectionStrut: includeSelectionStrut,
    ),
    [
      baseStyle,
      isDark,
      useUthmanTnProse,
      includeSelectionStrut,
      colors.primary,
      colors.foreground,
      colors.mutedForeground,
    ],
  );
}
