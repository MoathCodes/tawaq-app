# TAW-76 / TAW-79 review evidence

## Scope

- TAW-76: compact Fortress chapter header, readable collapsed prose, explicit
  localized disclosure copy, restrained metadata, and chapter-scoped expansion
  identity.
- TAW-79: explicit no-records state for periods with no recorded completions;
  explicit missed/late records remain data even when success is zero.
- TAW-82 Fortress contribution: the existing search controller and shortcut are
  surfaced as a labeled Search action in the browse toolbar. Quran, Hadith, and
  global shell search are outside this change.

## Acceptance checklist

- [x] Header is content-sized with title/favorite, quiet recurrence/count
      metadata, and one filled Start reading action.
- [x] Start reading wraps below the header content at narrow desktop widths.
- [x] Collapsed source prose uses the normal foreground and up to four lines;
      source text is never mutated.
- [x] Show more / Show less is localized and paired with the repetition target
      and chevron in a footer below the prose; expanded content keeps complete
      screen-reader content.
- [x] Sharh and virtue are readable metadata, not decorative button-like pills.
- [x] Expansion is keyed by sourced `contentId` and resets when the chapter
      changes.
- [x] Empty prayer periods replace repeated zeros with a concise localized
      instruction while period scope remains visible.
- [x] Explicit missed/late rows set `hasRecordedData` and continue to render
      honest zero-success analytics.
- [x] Loading/error ownership remains in the existing analysis provider flow;
      the no-records copy is not shown while analytics are unavailable.
- [x] Hydrating or unavailable prayer inputs remain skeleton/loading content;
      they are not labelled as factual absence.

## Rendered evidence

The following portable widget renders use the bundled Fortress chapter title
`أَذْكَارُ الصَّبَاحِ`, the bundled Quranic Ayatul Kursi passage, and the
packaged IBM Plex Arabic and Uthmanic Hafs fonts. They contain no user data:

- [Before: Desktop English, Manuscript light](taw-76-79-screenshots/baseline_desktop_en_manuscript_light.png)
- [Before: Narrow Arabic, Manuscript dark, text scale 1.3](taw-76-79-screenshots/baseline_narrow_ar_manuscript_dark_large.png)
- [Before: Desktop English, Neutral light](taw-76-79-screenshots/baseline_desktop_en_neutral_light.png)
- [Before: Narrow Arabic, Neutral dark](taw-76-79-screenshots/baseline_narrow_ar_neutral_dark.png)
- [Desktop English, Manuscript light](taw-76-79-screenshots/fortress_desktop_en_manuscript_light.png)
- [Narrow Arabic, Manuscript dark, text scale 1.3](taw-76-79-screenshots/fortress_narrow_ar_manuscript_dark_large.png)
- [Desktop English, Neutral light](taw-76-79-screenshots/fortress_desktop_en_neutral_light.png)
- [Narrow Arabic, Neutral dark](taw-76-79-screenshots/fortress_narrow_ar_neutral_dark.png)
- [Expanded narrow Arabic, Manuscript dark, text scale 1.3](taw-76-79-screenshots/fortress_expanded_narrow_ar_manuscript_dark_large.png)
- [Composed browse toolbar with existing search field](taw-76-79-screenshots/fortress_browse_search_en_manuscript_light.png)
- [Prayer empty state, English Manuscript light](taw-76-79-screenshots/prayer_empty_en_manuscript_light.png)
- [Prayer explicit missed-data state, Arabic Neutral dark, text scale 1.3](taw-76-79-screenshots/prayer_data_ar_neutral_dark_large.png)

The before images are a documented reconstruction of the pre-change header
arrangement from `github/main`; that old header was private and was not directly
renderable as a stable review fixture. They are comparative evidence, not a
claim of a captured running baseline. The after images show the corresponding
compact header, four-line preview, footer disclosure, expanded content, and
composed browse toolbar. The native Linux surface was also inspected during a
running `flutter run -d linux` session. Its Wayland accessibility bridge
reported a zero-sized Tawaq window, so no private desktop capture is committed;
the portable widget renders are the review artifacts.

## Regression coverage

- `fortress_category_detail_header_test.dart`: narrow/wide header wrapping and
  metadata/action presence.
- `fortress_preview_semantics_test.dart`: localized disclosure semantics,
  complete expanded content, readable foreground, four-line preview, target
  count, and 320px/360px Arabic large-text footer placement.
- `prayer_analysis_section_test.dart`: actual TrendAnalysisCard empty/no-chart,
  explicit missed zero-success metrics, period switching, pending/error states,
  unready hydration gating, and empty/data-state renders in both locale/theme
  directions.
- `fortress_review_screenshots_test.dart`: English/Arabic, desktop/narrow
  desktop, Manuscript/Neutral, light/dark, large-text, expanded, composed
  toolbar/search, and reconstructed before/after renders.
