# Quran search and Study refinement — October 6

Search results now use inset, transparent Forui rows with one shared active
result for pointer, focus and arrow-key navigation. Idle rows no longer paint
rectangular backgrounds against the popover surface. Section headings have
their own spacing; titles, references and Arabic previews have distinct type
hierarchy. Arabic previews retain their ascent/descent and vertical padding.
The repeated destination arrows are removed, and long results have a visible
scrollbar. Surah results show available sourced verse counts and starting
pages. Juz and Hizb results use repository division metadata to show their
starting Surah, ayah reference and unchanged source verse.

The wide Study pane follows ayah selection and the user's explicit collapse
preference. Deselection hides the pane and restores the reading width; selecting
an ayah shows it when it has not been explicitly collapsed. Both the header
button and the edge handle use the same opening command. With no selection,
they select the first visible fragment on the current page. A continued verse
does not jump back to the page where it began. Repeated header activation closes
Study. Visibility and outer padding derive from the same effective collapse
state, keeping the edge handle attached. Notes selection still ensures Study
opens; compact Study dismisses on deselection. Late loading cannot overwrite a
new user selection or select a fragment after the reader has changed pages.
Selection failures show the existing localized error toast.

This supersedes the empty-pane selection instruction and search-row styling in
[the October 5 follow-up](QURAN-FOLLOWUP.md). Search normalization, query bounds,
debounce, stale-result protection, Retry, reader identity, live display tabs,
recitation ownership and reduced-motion behavior remain covered by the existing
contracts. Religious source bytes, persisted schemas and local package sources
are unchanged. No localization or provider generation is required in this pass.

The installed Forui 0.27.3 source and
[official popover documentation](https://forui.dev/docs/widgets/overlay/popover)
informed focus, portal bounds, dismissal and style behavior. Regression coverage
resolves the actual Forui hover decoration, ensuring it cannot paint a second
active row. The previous empty-pane behavior was restored temporarily and the
new selection/visibility regression failed before the implementation was restored.

Final checks: **1,203 app tests pass**, including **19 focused Quran cases**.
Analysis has no errors or warnings and 424 informational findings. The regular
Linux debug build passes and the binary is restored to `lib/main.dart`.

The completed Linux matrix contains **272 captures across 16 combinations**:
Arabic/English, manuscript light/dark, 800×600/1200×860 (actual buffers
801/1201 pixels wide), normal/extra-large text. Four contact sheets and critical
full-resolution search and Study images were inspected. Native exit is zero
and the Flutter error list is empty. Some early Study images precede settled
commentary; later images also show loaded commentary. An interrupted attempt
with unchanged source is excluded from complete-matrix proof.

Verification details and candidate hashes are recorded in
[quran-refinement-verification.json](quran-refinement-verification.json).
Native review uses isolated XDG/Hive data and mounted app callbacks/text
controllers. It does not certify OS pointer/key delivery, native screen readers,
audio or complete desktop chrome visibility. Root checks cover the feature's
app composition and selection consumers; no changed package requires separate
checks. No commit, push, PR or release was performed.
