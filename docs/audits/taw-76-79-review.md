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
      and chevron; expanded content keeps complete screen-reader content.
- [x] Sharh and virtue are readable metadata, not decorative button-like pills.
- [x] Expansion is keyed by sourced `contentId` and resets when the chapter
      changes.
- [x] Empty prayer periods replace repeated zeros with a concise localized
      instruction while period scope remains visible.
- [x] Explicit missed/late rows set `hasRecordedData` and continue to render
      honest zero-success analytics.
- [x] Loading/error ownership remains in the existing analysis provider flow;
      the no-records copy is not shown while analytics are unavailable.

## Rendered evidence

The following images are generated from synthetic fixture content with the
packaged IBM Plex Arabic font, so no user data is present:

- [Before: Desktop English, Manuscript light](taw-76-79-screenshots/baseline_desktop_en_manuscript_light.png)
- [Before: Narrow Arabic, Manuscript dark, text scale 1.3](taw-76-79-screenshots/baseline_narrow_ar_manuscript_dark_large.png)
- [Before: Desktop English, Neutral light](taw-76-79-screenshots/baseline_desktop_en_neutral_light.png)
- [Before: Narrow Arabic, Neutral dark](taw-76-79-screenshots/baseline_narrow_ar_neutral_dark.png)
- [Desktop English, Manuscript light](taw-76-79-screenshots/fortress_desktop_en_manuscript_light.png)
- [Narrow Arabic, Manuscript dark, text scale 1.3](taw-76-79-screenshots/fortress_narrow_ar_manuscript_dark_large.png)
- [Desktop English, Neutral light](taw-76-79-screenshots/fortress_desktop_en_neutral_light.png)
- [Narrow Arabic, Neutral dark](taw-76-79-screenshots/fortress_narrow_ar_neutral_dark.png)

The before images use the baseline header arrangement from `github/main`; the
after images show the corresponding compact header and four-line preview. The
native Linux surface was also inspected during a running `flutter run -d linux`
session. Its Wayland accessibility bridge reported a zero-sized Tawaq window,
so no private desktop capture is committed; the portable widget renders are the
review artifacts.

## Regression coverage

- `fortress_category_detail_header_test.dart`: narrow/wide header wrapping and
  metadata/action presence.
- `fortress_preview_semantics_test.dart`: localized disclosure semantics,
  complete expanded content, readable foreground, four-line preview, and target
  count.
- `prayer_analysis_section_test.dart`: empty-versus-zero-success distinction
  and period model switching.
- `fortress_review_screenshots_test.dart`: English/Arabic, desktop/narrow
  desktop, Manuscript/Neutral, light/dark, and large-text renders.
