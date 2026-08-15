# UI, layout, and localization

## Forui and theme

Forui is the primary UI library; Material remains the app bridge. Read the active theme through `context.theme`, including `colors`, `radii`, `durations`, and `tabs`. Use `AppSpacing` constants for standard spacing.

[`buildAppTheme`](../../lib/theme/app_theme_builder.dart) combines palette, light/dark mode, touch/desktop density, `IBMPlexSansArabic`, persisted text scale, and custom theme extensions. Supported palettes are the custom default `manuscript` and Forui `neutral`.

Derive hierarchy and status colors from `FColors` and `Color.lerp`; fixed accent/status hex colors break palette and brightness adaptation.

## Responsive layout

Use viewport helpers from `core/layout/responsive.dart` for page-level mode changes. Use `LayoutBuilder` and container helpers when a pane or dialog's allocated width is what matters.

Quran, Hadith, and Muslim Fortress share the study-pane convention: `ResponsiveHorizontalSplitGate` decides whether a horizontal split fits; `CollapsibleHorizontalSplitPane.feature(...)` manages the split; each feature persists the side width as a ratio from 0 to 1; and the narrow branch has a feature-specific stacked/single-column layout. Resize handles are intentionally LTR in RTL contexts, while content directionality is restored inside each pane.

Use themed `FTabs` for tab/segmented controls. The supplied styles are `standard`, `primary`, and `compact`; do not recreate tabs from button rows.

## Accessibility, selection, and scrolling

- Icon-only or constrained actions must have an `FTooltip`.
- Use `MergedActionSemantics` for shared icon-only chrome, not ordinary page content.
- Use the desktop selection helpers for readable desktop content.
- `TawaqAppScrollBehavior` already provides a subtle scrollbar only where scrolling is meaningful; avoid one-off replacements.

## Localization and RTL

The ARB sources are [`app_en.arb`](../../lib/l10n/app_en.arb) and [`app_ar.arb`](../../lib/l10n/app_ar.arb). Read strings through `context.l10n.someKey`, then run `fvm flutter gen-l10n` after changing ARB files.

Test English and Arabic for visible changes. Use directional alignment/padding where appropriate, do not assume leading means left, and keep intentionally LTR interactions such as resize handles explicit.
