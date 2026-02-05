# Prayer Analytics UI & Data Changes (Summary + Rationale)

This document captures the work completed for the new analytics section in the Prayer screen, why each change was made, and the final architecture. It is intended to help future contributors understand how the feature is wired and where to extend it.

## 1) UI: New Analysis Section

### What was built
- A new `AnalysisSection` widget that replaces the old analytics cards in the prayer sidebar.
- The section is composed of two stacked cards:
  - **Daily Achievement**: semi‑circle gauge + daily status counts.
  - **Trends Analysis**: stacked bar chart with period tabs (daily/weekly/monthly/yearly).

### Why it was built this way
- The design requirements asked for a visually richer “daily” card with a gauge and a stacked trend chart.
- The previous analytics cards did not match the new design or layout.
- Using a dedicated widget keeps the UI modular and isolated from the sidebar container.

### Key UI files changed
- [lib/feature/prayer/presentation/widgets/analysis_section.dart](../lib/feature/prayer/presentation/widgets/analysis_section.dart)
- [lib/feature/prayer/presentation/widgets/prayer_stats_sidebar.dart](../lib/feature/prayer/presentation/widgets/prayer_stats_sidebar.dart)

### Notable UI adjustments
- **Gauge sizing** is driven by `LayoutBuilder` to avoid overflow and layout overlap.
- **Daily stats row** is centered, uses RTL, and only shows meaningful statuses (jamaah/on-time/late/missed).
- **Chart tooltips** are themed using `FTheme` colors and display a readable breakdown (including total).

## 2) Data: Analysis Section Provider

### What was added
- A dedicated provider (`PrayerAnalysisSectionNotifier`) to supply both:
  - Daily status counts.
  - Trend buckets for charts.

### Why it was added
- The existing analytics provider returned only summary percentages, not the raw per‑status counts or bucketed data needed by charts.
- Separating this provider keeps analytics UI concerns distinct from summary analytics used elsewhere.

### Key data files changed
- [lib/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart](../lib/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart)
- [lib/feature/prayer/domain/models/prayer_analysis_section.dart](../lib/feature/prayer/domain/models/prayer_analysis_section.dart)

### Notes on how data is computed
- Daily counts are computed from completions for **today**.
- Trend buckets:
  - **Daily period**: buckets are created per prayer (Fajr, Dhuhr, Asr, Maghrib, Isha).
  - **Weekly/monthly/yearly**: buckets are created by day/week/month and aggregated by status.

## 3) Storage Layer: Date‑Range Queries

### What was added
- A new query pipeline to load completions by date range:
  - `PrayerDatabase.getCompletionsBetween`
  - `PrayerRepo.getCompletionsBetween`
  - `PrayerService.getCompletionsBetween`

### Why it was added
- The trend chart needs historical data across a range, not just “today”.
- The data pipeline aligns with the existing layered architecture (DB → repo → service → provider).

### Key files changed
- [lib/feature/prayer/data/database/prayer_database.dart](../lib/feature/prayer/data/database/prayer_database.dart)
- [lib/feature/prayer/data/repository/prayer_repo.dart](../lib/feature/prayer/data/repository/prayer_repo.dart)
- [lib/feature/prayer/domain/services/prayer_service.dart](../lib/feature/prayer/domain/services/prayer_service.dart)

## 4) Layout: Prayer Screen Alignment

### What was changed
- The horizontal layout was updated so that:
  - The **hero header** and **sidebar** begin on the same top row.
  - The **schedule list** sits below the hero, removing the empty space.

### Why
- The earlier layout caused unwanted vertical gaps and visual misalignment between the hero and sidebar.

### Key file changed
- [lib/feature/prayer/presentation/screens/prayer_screen.dart](../lib/feature/prayer/presentation/screens/prayer_screen.dart)

## 5) Theme Alignment & Color System

### What was changed
- Prayer status colors were updated to a more modern, calmer palette.
- Chart colors and tooltip text align with the `FTheme` palette.

### Why
- The previous defaults looked harsh and inconsistent with the rest of the UI.
- Centralizing colors using `CompletionStatus.getBadgeColor` ensures consistency across badges, charts, and tooltips.

### Key file changed
- [lib/feature/prayer/data/models/prayer_completion.dart](../lib/feature/prayer/data/models/prayer_completion.dart)

## 6) Persistence of Analytics Period

### What was changed
- Added `prayerAnalyticsPeriod` to `StateSettings` and persisted it.
- Analysis tabs now use `FTabControl.lifted` and read/write the period via `StateSettingsNotifier`.
- Analysis provider reads the persisted period.

### Why
- The selected tab should remain stable across rebuilds and app restarts.
- Using `StateSettings` matches existing app state storage patterns.

### Key files changed
- [lib/feature/settings/data/models/state_settings.dart](../lib/feature/settings/data/models/state_settings.dart)
- [lib/feature/settings/data/models/state_settings.freezed.dart](../lib/feature/settings/data/models/state_settings.freezed.dart)
- [lib/feature/settings/data/models/state_settings.g.dart](../lib/feature/settings/data/models/state_settings.g.dart)
- [lib/feature/settings/presentation/provider/settings_provider.dart](../lib/feature/settings/presentation/provider/settings_provider.dart)
- [lib/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart](../lib/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart)

## 7) Reactive Updates on Status Changes

### What was changed
- Analysis provider watches `prayerCompletionProvider` so UI updates immediately when a completion changes.

### Why
- Without this, the analytics UI could lag behind the current status changes.

---

## Optimization / Fixes Applied During Review

- Removed the gauge glow and used a cleaner gradient to keep the gauge readable.
- Fixed tooltip readability (padding, background, total line).
- Avoided invalid l10n keys (e.g., removed reliance on a missing `total` string).
- Ensured chart bucket labels for **daily** show prayer names instead of weekday labels.

---

## Where to Extend Next

- If you want more granular monthly buckets (e.g., by day), adjust `_initializeBuckets` and label formatting in the analysis provider.
- If you want different scoring weights, update `_weightedScore` in `analysis_section.dart`.
- If you add new completion statuses, update `CompletionStatus` and the chart/legend to keep the UI consistent.
