import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Presentation helpers for [CompletionStatus] badges and labels.
extension CompletionStatusUi on CompletionStatus {
  /// Returns the color of the badge for this status.
  ///
  /// Uses a monochromatic gradient derived from the theme's [FColors],
  /// fading from [FColors.primary] toward [FColors.mutedForeground].
  Color getBadgeColor(FColors colors) {
    return switch (this) {
      CompletionStatus.jamaah => colors.primary,
      CompletionStatus.onTime =>
        Color.lerp(colors.primary, colors.mutedForeground, 0.35)!,
      CompletionStatus.late =>
        Color.lerp(colors.primary, colors.mutedForeground, 0.65)!,
      CompletionStatus.missed =>
        Color.lerp(colors.primary, colors.mutedForeground, 0.85)!,
      CompletionStatus.none => Colors.transparent,
    };
  }

  /// Returns the icon for this status.
  IconData? getIcon() {
    return switch (this) {
      CompletionStatus.jamaah => FLucideIcons.users,
      CompletionStatus.onTime => FLucideIcons.checkCheck,
      CompletionStatus.late => FLucideIcons.clock,
      CompletionStatus.missed => FLucideIcons.circleX,
      CompletionStatus.none => null,
    };
  }

  /// Returns the localized name of this status.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      CompletionStatus.jamaah => locale.jamaah,
      CompletionStatus.onTime => locale.onTime,
      CompletionStatus.late => locale.late,
      CompletionStatus.missed => locale.missed,
      CompletionStatus.none => '',
    };
  }
}
