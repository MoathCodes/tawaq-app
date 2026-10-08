# Hadith study desk

The Hadith screen now follows the confirmed study-desk hierarchy: a spacious search landing, eight source-backed topic entry points, a searchable catalogue, quiet recent-query rows and distinct card/reader surfaces. Search target selection stays inside the query field. Scholar, book and narrator filters expand on demand; specialist mode is a compact checkbox.

Filters and reader resize independently and close from their own headers in either direction. A reader opens only after selection. Compact readers and filters use Forui persistent sheets, preserving the underlying results. Topic ancestors and reader trails use Forui breadcrumbs. Both normal and compact readers load the selected detail tab directly; obsolete checked-section state and the extra confirmation label were removed. Empty endpoint collections show one empty state before any source-context rendering.

Loading uses card-shaped text, ruling, metadata and action bones with a restrained neutral pulse. Reduced motion uses a solid effect. Card attribution forms columns when space permits; source categories remain reachable through a compact menu beside share/copy/save. Exact source rulings stay neutral and readable, including long warnings.

The Dorar adoption, local Saved/recents readiness, original bookmark keys, compatible settings decoding and hydration order remain intact. The new filter width has a compatible default. Related narration Back preserves the committed page and reader position. Shared ruling and action consumers, including image export, are covered by app tests. No destructive migration, religious text rewriting, shared navigation redesign or SDK package source change is part of this correction.

The archived HTML is unchanged. Its navigation rail was hidden only in the collaborative browser review, as requested.

Validation passed in the dirty working tree at base `a5b35af8866ace6dbdee265acbe156ab0037cfbf`:

- Full app suite: 1,242 tests passed. The Hadith suite has 96 passing tests, covering direct detail requests, topic search and breadcrumbs, compact reader retention, independent panel closing/resizing in Arabic and English, and recovery paths.
- `fvm flutter analyze --no-fatal-infos`: no errors or warnings; 618 informational diagnostics remain.
- `fvm flutter build linux --release`: passed.
- Localization and root code generation completed. Compatible legacy settings decoding and the new filter-width round trip passed an additional eight-test contract run.
- Final diff whitespace check passed. An independent source/evidence review found no additional material source defect. Its compact-sheet capture concern was resolved with settled captures in all four locale/theme combinations.

Native Linux review used the normal desktop session and isolated settings, Saved and recent-query data. The SDK used its default managed reference/cache directory. The main capture batch covers 38 states across Arabic/English, light/dark, compact and wide windows, larger text, existing palettes, Saved, and reader navigation. Four additional compact captures wait until the persistent sheet controller stops animating. Both batches recorded no Flutter errors. Live SDK responses and reported cache provenance supplied the result/reader data.

Evidence is stored outside the checkout:

- [Arabic dark landing](/home/moath/.local/state/tawaq-delivery/hadith-desk-correction-20261007/runtime-settled2/desk-landing-ar-dark.png)
- [Three-pane Arabic desk](/home/moath/.local/state/tawaq-delivery/hadith-desk-correction-20261007/runtime-final/desk-ar-dark-1440.png)
- [Settled compact Arabic reader](/home/moath/.local/state/tawaq-delivery/hadith-desk-correction-20261007/runtime-settled2/desk-ar-light-664-settled.png)
- [Settled compact English reader](/home/moath/.local/state/tawaq-delivery/hadith-desk-correction-20261007/runtime-settled2/desk-en-dark-664-settled.png)
- [Loading pulse clip](/home/moath/.local/state/tawaq-delivery/hadith-desk-correction-20261007/runtime-settled2/loading-pulse.mp4)

The loading clip contains 24 captured production-widget frames over approximately 4.2 seconds, encoded to a 4.4-second H.264 clip and fully decoded for verification. It uses a synthetic pending state, so it demonstrates loading appearance and motion, not network duration or performance. The initial Arabic light compact capture in the main batch caught the entrance transition; use the settled confirmation above for that state.

Native screenshots were captured from Flutter render buffers, with interactions driven by the isolated review harness. Native OS pointer/keyboard input and macOS/Windows runtime behavior were not verified. Widget tests cover pane dragging, closing, Escape/focus return and direction changes. No performance improvement is claimed. The installed user app, settings and Saved data were untouched; owned review processes have exited. No commit or PR was requested.


## Category metadata follow-up

Category browse displayed field labels as narrator, scholar, source, locator and ruling values. Dorar category pages wrap the label in the first span and the actual value in a later span or link. The SDK selected the first span. Earlier category verification checked rendering and record counts without asserting the citation values.

The SDK now extracts the scoped text after the source label separator in both the parsed record and retained raw metadata. Label matching is exact, and a label without a value cannot satisfy the required metadata contract. Original narration text and source HTML are unchanged. This also covers detailed search, record/related/source-chain results and embedded explanation citations that share the parser. Existing raw-response caches are reparsed correctly; no cache reset, storage migration or generated Dart change is needed. Previously saved snapshots are unchanged.

Four new SDK regression tests use the captured Dorar category HTML. They cover all citation fields and retained source HTML, legacy text labels, a genuinely missing narrator value, and fresh versus raw-cached category responses. Three tests fail before the fix; all four pass after it.

The SDK's 367 tests and the Flutter adapter's seven tests pass. Both packages analyze without issues. Adapter verification used a temporary local-core override and refreshed stale generated hosted-package assets; those test artifacts and the temporary override were cleaned up afterward. The app's first concurrent test batch hit the 30-second limit in the existing 500-favorite storage test while native compilation was running. All eight storage tests pass on rerun. The Linux release rebuild passes. The sequential full app suite passes all 1,242 tests. App analysis reports no errors or warnings, with the existing 618 informational diagnostics.

Native verification captured the category cards and reader with actual source values and no Flutter errors. All 20 captured category records have real required metadata, including the cached response's first record: أبو هريرة / البخاري / صحيح البخاري / 1145 / [صحيح]. The SDK used its default managed raw cache; settings, Saved and recents were isolated. Native OS input was not verified.

[Corrected category card and reader](/home/moath/.local/state/tawaq-delivery/hadith-metadata-fix-20261007/runtime/desk-category-reader.png) · [Record and provenance verification](/home/moath/.local/state/tawaq-delivery/hadith-metadata-fix-20261007/metadata-verification.json)

The rebuilt bundle is in `build/linux/x64/release/bundle`. The installed app at `/home/moath/.local/share/flutter-apps/tawaq` was not replaced.
