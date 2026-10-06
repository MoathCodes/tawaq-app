# Hadith card cleanup — October 6

Selected Hadith cards use a flat neutral fill and a uniform one-pixel border.
Hovering a selected card preserves that appearance. Unselected cards use subtle
neutral hover feedback; keyboard focus retains Forui's focused outline.
The shared `HoverCard` remains unchanged for other features.

The visible result-number row and selected-result detail heading are removed.
Each result and detail view presents its source citation once in the metadata.
Result ordinals remain only in accessibility labels. Source text, rulings,
Share, bookmarks, keyboard selection and detail scroll behavior are preserved.
Both the wide detail pane and compact detail popover use the simplified layout;
the preview tool is updated to match the removed detail-heading parameter.

Regression tests drive Flutter pointer and keyboard events, check uniform
borders and shadow-free hover, verify one source citation, retain accessible
selection, and prove same-result scroll retention/new-result reset. No generator
inputs or local packages changed; no generation was required.

The native review covers idle, hover, selected and selected-hover states in
16 Arabic/English, Manuscript light/dark, compact/wide, normal/extra-large
combinations. It uses the real app with isolated XDG/Hive data and mounted
Forui pointer callbacks. It does not certify native OS input or AT-SPI.
The first capture round also hovered adjacent actions; the confirmation narrows
the callback to the card body. App source is identical between those rounds.

Final check results and source/artifact hashes are recorded in
[hadith-card-cleanup-verification.json](hadith-card-cleanup-verification.json).
All **1,224 app tests** and **101 Hadith tests** pass. Analysis reports zero
errors and zero warnings (439 informational diagnostics). The confirmed native
run exits zero with no Flutter errors; all 64 captures were decoded and inspected
in four contact sheets plus two complete views. The normal `lib/main.dart` Linux
debug build is restored and passes.
No commit, push, PR or release was performed.
