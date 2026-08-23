import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/radii.dart';
import 'package:tawaq/theme/spacing.dart';

/// The three tab appearances used across the app.
///
/// [standard] is installed as `FThemeData.tabsStyle`, so a bare [FTabs] already
/// picks it up. The other two are opted into per call site:
///
/// ```dart
/// FTabs(style: context.theme.tabs.primary, children: [...]);
/// ```
class AppTabsStyles extends ThemeExtension<AppTabsStyles> {
  /// Creates an [AppTabsStyles] from three explicit styles.
  const new({
    required this.standard,
    required this.compact,
    required this.primary,
  });

  /// Derives the three tab styles from the palette.
  factory inherit({
    required FColors colors,
    required FTypography typography,
    required FStyle style,
    required AppRadii radii,
  }) {
    // Track and indicator share `radii.md` across every variant. A concentric
    // inner radius would be tighter, but the pill reads as its own surface at
    // this scale and a squarer corner looks like a mistake next to the track.
    ShapeDecoration shape(
      Color color,
      Color borderColor, {
      List<BoxShadow>? shadows,
    }) => ShapeDecoration(
      shape: RoundedSuperellipseBorder(
        side: BorderSide(color: borderColor, width: style.borderWidth),
        borderRadius: radii.md,
      ),
      color: color,
      shadows: shadows,
    );

    // `compact` and `primary` share one treatment: a track recessed to
    // `background`, with the selected tab tinted `primary`. They differ only in
    // density. `standard` keeps the neutral raised-surface pill.
    final recessedTrack = shape(colors.background, colors.border);
    final tintedIndicator = shape(
      colors.primary.withValues(alpha: 0.18),
      colors.primary.withValues(alpha: 0.55),
    );

    FTabsStyle build({
      required Decoration decoration,
      required Decoration indicatorDecoration,
      required TextStyle labelTextStyle,
      EdgeInsets padding = const EdgeInsets.all(4),
      double minHeight = 36,
      double spacing = AppSpacing.md,
    }) => FTabsStyle(
      decoration: decoration,
      indicatorDecoration: indicatorDecoration,
      labelTextStyle: FVariants.from(
        labelTextStyle.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.mutedForeground,
        ),
        variants: {
          [.selected]: .delta(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        },
      ),
      focusedOutlineStyle: style.focusedOutlineStyle,
      padding: padding,
      minHeight: minHeight,
      spacing: spacing,
    );

    return AppTabsStyles(
      standard: build(
        decoration: shape(colors.muted, colors.border),
        indicatorDecoration: shape(
          colors.background,
          colors.border.withValues(alpha: 0.6),
          shadows: [
            BoxShadow(
              color: colors.barrier.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelTextStyle: typography.body.sm,
      ),
      compact: build(
        decoration: recessedTrack,
        indicatorDecoration: tintedIndicator,
        labelTextStyle: typography.body.xs,
        padding: const EdgeInsets.all(2),
        minHeight: 28,
        // Compact tabs drive state that renders elsewhere, so their own
        // content slot is empty and needs no gap below the bar.
        spacing: 0,
      ),
      primary: build(
        decoration: recessedTrack,
        indicatorDecoration: tintedIndicator,
        labelTextStyle: typography.body.sm,
      ),
    );
  }

  /// Tabs on a page or card surface. Also the app-wide default.
  final FTabsStyle standard;

  /// [primary] at a smaller scale, for headers and dialogs where the bar is a
  /// control rather than a section divider, and labels may be icon-only.
  final FTabsStyle compact;

  /// Tabs on a `secondary` surface, where the default track would sit within
  /// one lightness step of the card. Recesses the track and tints the selected
  /// tab with `primary`.
  final FTabsStyle primary;

  @override
  AppTabsStyles copyWith({
    FTabsStyle? standard,
    FTabsStyle? compact,
    FTabsStyle? primary,
  }) => AppTabsStyles(
    standard: standard ?? this.standard,
    compact: compact ?? this.compact,
    primary: primary ?? this.primary,
  );

  @override
  AppTabsStyles lerp(AppTabsStyles? other, double t) {
    if (other == null) return this;
    return AppTabsStyles(
      standard: standard.lerp(other.standard, t),
      compact: compact.lerp(other.compact, t),
      primary: primary.lerp(other.primary, t),
    );
  }
}
