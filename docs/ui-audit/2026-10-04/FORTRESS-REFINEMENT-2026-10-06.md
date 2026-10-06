# Fortress browse refinement — October 6

The catalog sidebar now follows the interface direction: right in Arabic, left
in English. The split primitive takes a physical side index, so the screen
explicitly derives it from the locale direction. Outer and divider padding also
use logical start/end. The collapse control sits in the sidebar title row with
its own width; the shared split's overlay control is disabled for this screen.
The collapsed edge tab remains attached on the corresponding side.

The selected-chapter header has one reading action. Its duplicate bookmark is
removed; catalog bookmarks and the existing chapter context-menu action remain.
Chapter and dhikr source content are unchanged.

One always-visible sidebar field replaces the global toolbar and local filter.
It has a search icon and uses the existing canonical session query, debounce,
clear and submit behavior. Full title/content results appear in the sidebar;
the selected reading pane remains available alongside them. Compact browsing
keeps the field visible while typing and opens a reading destination after a
result is chosen. The favorites tab retains its chapter filter and saved order.
Selecting a chapter resets the field and cancels pending input. Choosing an
already-selected search title still opens the compact destination. Ctrl+K
reveals the catalog and focuses its sole field, including from a collapsed
pane. Focus requests run immediately; an unattached node retains the request
until its field remounts.

The unified path preserves the old catalog's symmetric Arabic title matching.
The upstream SQLite title search column removes tashkeel, while a fully
vowelled query is passed through unchanged. The app repository therefore matches
cached chapter names with `arabicSearchContains` before bounding results. It
retains exact sourced names, counts, catalog order and total matches. Content
search keeps its existing upstream path. Regression coverage compares the
native-review queries against the previous title results and verifies full
vowelled names, alef variants, ta marbuta and limits.

The source fan-out covers screen composition, sidebar query/focus, search-result
opening, detail headers, provider documentation and the old toolbar screenshot
fixtures. Shared split-pane code, focus-reading ownership, persisted settings
fields and package sources are unchanged. Root generation was rerun after provider
documentation changes; existing localization strings are reused.

The Linux review uses isolated XDG/Hive data and mounted callbacks/text
controllers. Its precise candidate, inspected captures, test results and hashes
are recorded in [fortress-refinement-verification.json](fortress-refinement-verification.json).
It does not certify native OS input, screen readers, audio or full desktop
chrome visibility. No commit, push, PR or release was performed.

Final checks: **1,213 app tests pass**. After mechanical import/const cleanup,
**30 focused cases pass**, including nine new browse regressions, the Arabic
title regression and ten golden cases. Analysis has no errors or warnings;
information-level findings remain in the recorded log. Root generation and the
normal `lib/main.dart` Linux debug build pass. Build output is restored to that
entry point.

The native confirmation contains **128 captures across 16 combinations** of
Arabic/English, manuscript light/dark, 800×600/1200×860 and normal/extra-large
text. Four contact sheets and critical full-size Arabic selected, collapsed and
content-search views were inspected. Native exit is zero; the Flutter error
list is empty. The first pass exposed the unscheduled compact focus request;
its incomplete matrix is excluded from complete-matrix proof.

The composition candidate predates the cached Arabic title-matching correction
and mechanical imports. The repository regression proves the captured queries
retain identical title IDs and ordering; content search and the rendered UI
are unchanged. The final normalized-title behavior has repository and mounted
compact-widget coverage. This scope does not imply an additional native pass.
