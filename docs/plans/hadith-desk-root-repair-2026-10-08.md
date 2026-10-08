# Hadith desk: repair the interaction and reading model

Date: 2026-10-08. Status: implemented in the working tree. The plan below records the approved direction and original diagnosis; the implementation and verification record at the end states what was delivered and what was actually exercised.

The authority remains Moath's study-desk reference and Tawaq's existing theme. His latest screenshots and instructions override the corresponding decisions in the [earlier specification](../specs/hadith-study-desk-2026-10-07.md). Keep the distinct filters, results and reader areas where they serve the current task. Finish Arabic reading, interaction continuity and export quality before adding controls.

Latest corrections: remove cache provenance, fetch timestamps and source paging-limit explanations from the product interface entirely, including help and popovers. They are implementation diagnostics. All available share options enabled is a required design case, not an excuse for a poorly composed export.

The narration and hukm are the two primary reading anchors. The SDK's `VerdictTone { positive, negative, unmarked }` supplies their semantic emphasis. This overrides the earlier specification's neutral-only ruling treatment; the new design must make the hukm unmistakable without returning to bright, mismatched grade colors.

## 1. What went wrong

Several defects share an owner. Changing their spacing individually would preserve the causes.

| Symptoms | Evidence in the current source | Repair |
| --- | --- | --- |
| Empty filters beside Topics/category pages; a filter button with no useful operation | `HadithPage.inlineFilters` checks width, landing and saved visibility, but not endpoint capabilities. `HadithFilterForm` separately rejects non-search contexts. The panel also checks the retained search target before the current collection. | Derive applicable controls once from the current collection and endpoint. Use that decision for layout, toolbar, keyboard shortcut and sheet opening. |
| Reader surface starts below the feature navigation row | Navigation and divider wrap the entire workspace; the reader split is inside the lower `Expanded`. | Put navigation in the main workspace header. Reader surface occupies the complete feature height immediately below the global app bar. |
| Accordion closes while scrolling; edits cause flicker and loss of place | The form watches the entire session. Results scrolling writes `resultsOffset` into it. Accordions use internal state inside a lazy `ListView`. Filter edits replace the outcome with bare `AsyncLoading` and clear the reader immediately. | Keep filter interaction state outside disposable scroll children; narrow subscriptions; preserve committed results and the selected reader during requests. |
| Rebuild blamed as the complete accordion cause | Resolved Forui 0.27.3 preserves an internal managed controller on ordinary equivalent updates. | Reproduce disposal/remount and topology changes before changing controllers. Do not claim that every rebuild resets Forui. |
| Raw `|` in explanation badges; metadata and large gaps inside prose | The badge displays `ExplanationReference.rawLabel` verbatim. The text renderer concatenates source gaps into one rich text, including markup whitespace. | Keep raw source labels and text; derive clean UI labels and render structural blocks as paragraphs/citations. |
| Export repeats citation metadata and has two ruling labels | `HadithSharhContent` always builds the explanation header and embedded citation, even when `commentaryOnly` is true. `HadithShareCard` adds a ruling heading before `HadithSourceRuling` adds another one. | Give content composition an explicit purpose. One heading per ruling; one attribution per actual source record. |
| Loading layout differs from the loaded card | Skeleton draws fixed full-width metadata bars; loaded cards switch between attribution columns and compact rows. Font size and action geometry differ. | Use the same responsive card frame and slot dimensions for real and loading content. |
| Several similar input fields and large discovery buttons | Local narrator lookup and online discovery have separate text fields. Scholar-book suggestions sit under the book selector as a separate workflow. | One local lookup per dimension. Move reference upkeep into the release preparation pipeline; remove discovery workflows from the desk. |
| Jargon, repeated labels and four empty phrase slots | UI largely reflects SDK parameters. Optional phrases are always rendered four times. Sort is hidden in Advanced. | Explain user-visible consequences, reveal phrase inputs on demand, and put ordering beside results. |
| Cache labels and a paging-limit paragraph distract from the reading task | Request provenance and endpoint limits are promoted into normal product content. | Remove these labels and their UI affordances. Keep technical diagnostics in developer tooling; let pagination reflect available pages. |
| Hukm looks like secondary metadata; positive and negative judgments look almost alike | `HadithSourceRuling` uses small foreground text for all judgments. Tawaq's local heuristic identifies warnings but has no positive tone. | Use the SDK's VerdictTone and a prominent themed ruling treatment alongside narration; retain exact wording and a non-color distinction. |

The current SDK metadata extraction fix remains intact. This work must preserve original religious wording, independent citations, warning rulings, Saved keys and compatible decoding.

## 2. Context controls the workspace

Use a small exhaustive projection of the existing collection/target types, rather than another navigation state machine. It answers which query, filters and result tools are meaningful.

| Context | Main header | Side filters | Result tools |
| --- | --- | --- | --- |
| Hadith text search | Hadith query, target menu, search action | Search method, scope, source judgments, scholar, book, narrator, additional phrases/exclusions | Order; optional “with takhrij” mode; count and paging |
| Explanation prose search | Query with explanation target | None | Count; only supported prose paging |
| Topic catalogue/subtopics | One topic-search field and breadcrumbs | None | Topic discovery/navigation |
| Category results | Breadcrumb/title; return to Topics | None | Count/paging; category's supported takhrij mode in the toolbar menu |
| Saved | Saved heading and existing collection actions | None | Local count, record actions; no remote filter controls |

Important consequences:

- Remove the normal Hadith query row from the topic catalogue. It currently duplicates topic search and exposes irrelevant target/filter controls.
- Hide the filter button, resize divider, empty region, reset action and filter shortcut where filters do not apply. Do not persist `filtersVisible = false` merely because the user visits Topics; restore their preference on returning to record search.
- Close an open filter sheet when its context stops supporting filters. Retained record-search criteria remain in memory without a dedicated empty explanatory sidebar.
- The SDK does support `specialist` for category browsing. This is one toolbar option, not a reason to retain the whole filter panel. Name it by its consequence: `أحاديث لها تخريج` / “With takhrij”. Keep `التخريج` for the actual source-reference section, so these two functions are distinguishable.
- Search mode changes should follow endpoint capability, not a stale target value retained from another collection.

## 3. Stable editing and requests

This is the first implementation phase because visual changes must not conceal state loss.

1. Reproduce four reported cases: choose a scholar, type an extra phrase, scroll the results while a filter accordion is open, and scroll a fully expanded filter form out and back. Observe widget/controller mount and disposal, filter offset, focused field and request transitions. Diagnostics remain scoped to tests or the review harness.
2. Give the route a small owner for filter interaction state: expanded group identities, filter scroll offset and phrase-row identities. These are ephemeral UI state, not durable settings and not part of every request snapshot.
3. The filter form is small and bounded. Use a scrolling, mounted form body instead of lazy disposal of its accordion groups. Own Forui controls above the scroll content, with explicit stable expansion state where column/sheet transitions can remount the panel. Results and large select menus stay virtualized.
4. Watch only the fields a control consumes. A result scroll offset must not rebuild the filter form. Editing a narrator must not recreate book/search-method controllers.
5. Keep the last committed page together with the criteria that produced it. Pending criteria and pending request status are separate from the displayed page. Chips must not claim that old results were fetched with new criteria.
6. During refinement, keep cards and their scroll position mounted. Show a small `جار تحديث النتائج…` status; replace the page on successful commit. On failure, keep the last page with a local retry. Use a full skeleton only when there is no committed page to show.
7. The reader owns the record it displays and its navigation origin. Do not clear it on each filter edit. It can continue showing the selected record while results update, even if the new page does not contain that record. Selecting another record or explicitly closing it changes the reader.
8. Preserve existing debounce, cancellation and generation guards. Accepting an old response must remain impossible. Typing, cursor selection and accordion state must survive debounce, loading, success and failure.

Do not add blanket global persistence or rebuild suppression. Fix ownership and mounted identity.

## 4. Layout and hierarchy

The global app bar and global navigation remain the app's owners. Within the Hadith feature:

- Filters, main workspace and reader are full-height regions. Reader and applicable filter surfaces start immediately below the global app bar, with no feature-wide empty strip above them.
- Move Search, Topics and Saved into the main workspace header as a compact icon-and-label navigation group: search, library/topics, bookmark. Keep labels visible at ordinary desktop widths. At genuinely tight widths, use one labeled current-view menu with those same items and icons.
- Breadcrumbs sit with the current collection heading, not as a second full-width feature header. Reader trails stay within its header.
- Keep query and results tools aligned within the main area. Reader copy/share/save/close actions stay in its own header; closing it never changes the filter panel.
- Persistent sheets remain the compact adaptation. They start under the global app bar, preserve underlying results and have their own close/Escape behavior.
- Move ordering to the result toolbar: `ترتيب الدرر` / “Dorar order” and `حسب درجة المصدر` / “Source degree”. Only expose it for the endpoint that supports it. Do not suggest that this is a new app-authored authenticity ranking.
- Move takhrij mode into the same compact result-options menu. Remove the isolated checkbox below each category heading and its duplicate form checkbox.
- Remove cache banners, fetch timestamps, provenance buttons and their help/popover replacements entirely. Preserve request metadata internally where recovery and debugging need it. Keep religious source citations visible: narrator, scholar, book and locator are reading content.
- Remove the paging-limit paragraph and any equivalent tooltip/help icon. Render the available pages and disable navigation when no further page exists. Preserve the SDK's endpoint limits internally; category browsing must remain uncapped by the ordinary-search rule. Do not replace the removed paragraph with another permanent instruction.
- Error and recovery feedback explains the action the reader can take in plain language. It does not expose cache strategy, response provenance or endpoint architecture.

The layout must stay quiet in both themes and directions. Do not add a second global rail or redesign the app shell.

## 5. Understandable controls

Use `FTooltip` on small question-mark buttons next to unfamiliar labels. Help opens on keyboard focus as well as hover; icon controls have Arabic/English accessible names. Tooltips must explain an outcome, not repeat a label or dump parameter names.

Suggested Arabic wording, to be checked against the SDK contracts while implementing:

| Control | Help |
| --- | --- |
| `جميع الكلمات` | `تبحث عن روايات تحتوي الكلمات التي كتبتها كلها.` |
| `أي كلمة` | `تبحث عن روايات تحتوي واحدة على الأقل من الكلمات التي كتبتها.` |
| `العبارة نفسها` | `تبحث عن الكلمات بالترتيب الذي كتبته.` |
| `أحاديث لها شرح` scope | `يحصر نتائج الأحاديث في روايات لها شرح. للبحث داخل الشروح، اختر «الشروح» من حقل البحث.` |
| Source judgment choices | `هذه أحكام المحدثين في الدرر. الحكم على الإسناد يختلف عن الحكم على الحديث.` |
| `أحاديث لها تخريج` | `يعرض وضع الدرر المتخصص: روايات تتضمن معلومات التخريج.` |
| Source-degree order | `يرتب النتائج بحسب درجة المصدر كما تعرضها الدرر.` |
| Exclusions | `اكتب الكلمات أو العبارات التي لا تريدها في النتائج.` |

Keep distinctions that carry religious meaning. The SDK's four judgment filters distinguish a judgment on a hadith from a judgment on its chain. Present those choices under clear “الحديث” and “الإسناد” groupings, retaining the source's “ونحو ذلك” qualification. Do not merge them into a simple authentic/weak classifier. Preserve exact judgments on cards.

Additional phrases:

- No four empty numbered fields at rest. Show `+ إضافة عبارة بحث` and add one input per press, up to the SDK's four-slot limit. Each row has a remove action; removing one must not overwrite another row or unexpectedly change focus.
- Use one section heading, not `عبارة اختيارية 1/2/3/4` repeated above inputs. Slot order and values remain compatible with request serialization.
- Verify the actual relationship between the main query and additional phrases using the captured phrase matrix before shipping explanatory copy. Serialization alone does not prove AND/OR semantics. Do not publish an invented promise about how phrases combine.
- Hide/remove the add action at the limit and explain the limit accessibly. External reset updates fields without losing cursor position during ordinary edits.

Remove repeated field labels inside an accordion when its heading already supplies the label.

## 6. Advertised details, without speculative tabs

Cards and reader tabs must consume one shared capability projection from the selected record.

- An Asbab pill appears when `asbabAvailability == Availability.advertised`. Use the Hadith term `أسباب الورود`, with an appropriate icon.
- The normal reader presents advertised sections and existing takhrij/explanation data. Merely having a valid record ID or `Availability.unknown` does not create a primary tab that makes the user wait to discover it is empty.
- Apply the same policy to Usul and other optional sections, accounting for compatible legacy flags. Do not change `unknown` to “absent” in source data.
- For legacy records with unknown capability, an explicit secondary source-check action can remain in the reader's overflow menu; it is never automatic, selected by default or required for already-advertised sections.
- Fetch only the selected remote section. Advertised links still need a request for their content; the UI must not promise zero network wait. Distinguish loading, request failure and recognized empty response.
- Empty responses show one local message. Circumstances associated with a similar narration remain identified as such; do not attribute them silently to the selected hadith.

Use localized relationship labels for explanation pills, such as `شرح الحديث` and `شرح حديث مشابه`. Keep the original label on the model, including its raw punctuation; remove verified source UI separators from the display label only. Never globally strip `|` from narration or commentary text.

## 7. Narration and hukm are the reading anchors

The first scan of a result card, reader or share image must reveal both what the narration says and the source scholar's ruling. Attribution, availability and actions sit below those two in the hierarchy.

### SDK authority

- Consume the supplied `VerdictTone.positive`, `.negative` and `.unmarked` through the SDK's actual public accessor. Do not infer a tone from the active filter, scholar, book, or new app-side word matching.
- Both app dependencies now resolve from hosted `dorar_hadith: 0.7.0` and `dorar_hadith_flutter: 0.7.0`, following Moath's release instruction. The resolved SDK exposes `verdictTone`, derives it from observed source highlighting, and defaults legacy decoded records to unmarked. Its published metadata extraction handles the colon variants. The local checkout and its existing metadata work remain preserved; the app does not use it.
- Keep exact source ruling wording visible, including qualifiers, and preserve distinct short/expanded judgments. The enum has three presentation tones, not four religious grades: صحيح and حسن remain distinguishable by their text, as do ضعيف and موضوع. Do not invent additional authenticity classifications or severity rules.
- `unmarked` is an absence of semantic marking, not a favorable judgment. Its ruling remains legible and prominent. Missing ruling text has no fabricated fallback.
- Trace replacement of Tawaq's local warning heuristic through cards, reader, share options, exported images, copied text and existing persisted records. Use the SDK contract for negative-ruling sharing constraints while preserving mandatory warnings and expanded qualifications. Do not silently weaken that contract or store theme colors in records.

### Visual treatment

Use one stable ruling component across cards, reader and export, adapting its measure to each composition:

- Place the ruling immediately after narration, aligned to the same reading edge. Give it a recognizable compact surface and comfortable padding, with a small `حكم المحدث` label and a stronger exact ruling. It must read as a key answer rather than another muted metadata row.
- `positive`: a restrained green semantic foreground with a lightly tinted matching surface and a supporting confirmation icon.
- `negative`: a restrained red semantic foreground with a lightly tinted matching surface and a warning icon. Long negative or qualified wording wraps fully; no truncation, clipping or replacement with a short invented grade.
- `unmarked`: a clear neutral surface and strong foreground text, without a confirmation or warning implication.
- Resolve semantic colors through the active app palette and contrast requirements in both themes. Avoid neon fills, arbitrary per-grade hues and coloring the whole hadith card. Keep interaction selection styling separate from ruling meaning.
- Exact text, placement, weight and icon shape carry meaning alongside color. Icons supplement the source wording; accessible names do not add a religious claim. The small label can recede, but the ruling itself cannot use faint muted text.
- Short rulings form a compact callout. Long rulings grow as readable text within the same treatment. Preserve source-field order and label any distinct expanded qualification once; do not turn a long judgment into a tiny chip or a horizontal badge row.

Acceptance: at first glance, narration and hukm stand out before narrator/book/actions. Compare real positive, negative and unmarked SDK fixtures; include qualified judgments, distinct short/expanded wording and missing values. Review cards, reader and actual all-options exports in light/dark themes and compact/wide layouts, including a grayscale check of non-color cues.

## 8. Sharh is structured reading content

Restore the useful formatting of the earlier implementation using the SDK's sourced structure. Do not restore its duplicate app parser or heuristics for guessing who said a passage.

Separate three things explicitly:

1. The selected hadith and its citation, already visible in the reader.
2. The explanation page's record and any distinct embedded narration/citation.
3. Actual commentary paragraphs, headings, quotations, glossary references and source chains.

Create one feature-local presentation projection that coordinates these sections for the reader and export. It earns its place by preventing repeated source context and preserving distinct citations.

- Reader: commentary is the main body. If the explanation header refers to the same record, do not repeat the whole narration and metadata below the already-visible reader header. If it is different, show one compact related-narration/citation section, with the relationship clear.
- Establish sameness from trustworthy identity or verified exact citation evidence. Do not collapse independent versions by Arabic search normalization, shared narrator name or matching fragments.
- Render paragraphs and list items as separate blocks with controlled spacing. Present a source citation as labeled rows or a compact citation block, not a text dump of `الراوي | المحدث | المصدر` and HTML indentation.
- Quoted narration can have a readable inset/typographic treatment; commentary uses the normal reading measure. Style quotations from source structure or existing neutral annotations. No invented speaker colors or religious attribution.
- Preserve links, Quran labels/destinations, glossary definitions, source ranges and original HTML/text. Ignore layout whitespace in the display projection without rewriting source content or breaking annotation ranges.
- Review SDK block classification against the attached kind of explanation and the captured fixtures. Repair misclassified blocks in the SDK if needed; do not silently hide meaningful commentary to make the card shorter.
- Use verified endpoint display-prefix cleanup for source result numbering/dashes. The leading `-` in the shared image is another display-prefix leak; preserve the underlying sourced narration.

## 9. Share images deserve their own composition

The supplied export has all options enabled. That is a valid use case. Its poor readability comes from the composition: it puts duplicate attribution before the explanation, labels a ruling twice, leaves large empty gaps, uses weak contrast for important small text, and gives source chains almost the same visual weight as the main explanation. Turning options off is not the fix.

This surface is Read mode. The narration leads, the explanation carries the reading flow, and source information supports both. Use Tawaq's established Arabic typography and theme rather than copying interactive reader widgets into an image. More selected content should lengthen a coherent document, not produce a stack of equally weighted panels.

Use the same semantic sections as the reader, with a purpose-built export layout:

- Main narration first, at a comfortable Arabic reading size and line height.
- Exact ruling with one label. Distinct short and expanded source rulings remain distinct when their wording carries additional meaning. Warning rulings remain mandatory under the existing sharing contract.
- One compact attribution block. Keep narrator, scholar, book and locator readable, with correct bidi handling for Latin numerals and punctuation.
- Commentary starts directly under a clear heading. Do not repeat the selected citation or emit page-header scaffolding merely because `commentaryOnly` was requested.
- Distinct explanation narration/citation appears once when needed. Never deduplicate different sources for visual convenience.
- Chains/Usul are optional supporting sections after the main reading content, with a clear boundary and compact spacing. Do not squeeze long selected content into smaller text to force a single short image.
- Keep the existing complete-content behavior: a long selected export can be tall, with a faithful preview and explicit selected sections. Do not silently truncate, crop paragraphs or add automatic multi-image export scope in this repair.
- Screen, preview, exported pixels and text-copy paths share source/ruling decisions, while their visual compositions differ appropriately.

### Required all-options composition

The representative preview must include every available option and follow this reading sequence:

1. **Narration:** the strongest type on the image, aligned to the Arabic reading edge, with generous side margins and a comfortable line measure. No result numbering or stray prefix punctuation.
2. **Ruling and citation:** a prominent exact ruling with the SDK tone treatment from section 7, followed by compact attribution. Narrator and scholar can form separate short lines; book and locator stay together where space permits. Long names wrap naturally. Labels recede through type weight and spacing without becoming faint.
3. **Takhrij:** a short labeled source paragraph with deliberate spacing, not another large card or a repeated attribution block.
4. **Explanation:** a clearly visible section heading, then correctly structured paragraphs. Include one compact related-narration citation only when the explanation actually uses a different record. Normal paragraph spacing replaces source-markup blank lines.
5. **Usul:** a distinct supporting section. Each source has a clear book/locator heading and its chain directly underneath; separate sources with consistent spacing. Chains remain readable at phone scale and use a quieter heading/weight hierarchy rather than tiny or washed-out text.
6. **Signature:** the selected Tawaq mark sits quietly at the end with intentional separation from the last paragraph.

Use one consistent spacing rhythm: the smallest gaps within a citation, normal gaps between paragraphs, and larger gaps between major sections. Reserve the app accent for restrained section navigation cues; do not give every label the same accent treatment. Avoid nested cards, repeated divider bands and ornamental quotation marks. Each new section should be identifiable while the whole export still reads as one document.

Judge actual exported pixels at normal phone display size, not only enlarged in the desktop preview. Review default, all-options, long-commentary and long-chain cases in both themes. Verify narrow-dialog preview scaling, line wrapping, bidi locators and export failure/retry handling. All-options must retain a clear reading order without clipping, faint citations, duplicate headings or unexplained blank space.

## 10. Loading matches the card

Introduce a small common card frame for narration, ruling, attribution, capability and action slots. Both loaded and loading content use its padding, responsive attribution layout and typography-derived dimensions.

- At wide widths, the skeleton has the same three attribution columns as the real card. At narrow widths, it has the same compact rows.
- Represent the ruling callout and capability/action rows separately. Its loading placeholder has neutral styling until a sourced tone is known. Use realistic text-line lengths; stop drawing long metadata stripes and three anonymous square buttons in unrelated positions.
- The card surface and border remain steady. Use static, low-contrast bones by default; activity belongs in the small search/update indicator. Avoid sweeping highlights and pulsating whole cards. Any brief content entrance honors reduced motion.
- Initial record, prose and reader loading states use their own applicable shapes. Refinement retains committed results rather than replaying the initial skeleton.

Line counts cannot predict unseen source text exactly. Acceptance compares slot placement, typography, surfaces and responsive shape, allowing natural narration-height variation.

## 11. Reference maintenance belongs before release

Remove `HadithReferenceDiscovery` from the filter form. Keep one scholar field, one book field and one narrator field, searching bundled references. SDK discovery APIs may remain available without becoming desk controls.

The SDK already has `tool/refresh_references.dart`, captured-source checks, retained historical book/scholar IDs, a versioned reference manifest and a narrator database migration tool. Extend that pipeline rather than adding an app-side updater.

1. A separate SDK workflow, scheduled or manually run for release preparation, fetches source captures and generates candidate book/scholar JSON and narrator database data.
2. Validate response structure, source hashes, duplicate IDs, normalization, schema, reference counts and database integrity. Produce a human-readable added/renamed/historical diff.
3. Open a candidate update PR; publish the reviewed snapshot and pin its SDK revision before building Tawaq releases. Do not let every platform release job independently fetch changing live data.
4. Upstream failure must not overwrite the last good snapshot or silently produce an empty catalogue. Existing historical IDs and labels remain decodable.
5. Scholar-book associations are not book authorship. Bundle any association mapping only when backed by captured, reviewed responses; the full book list is sufficient for the first repair.
6. Narrator coverage remains partial: the current refresh samples autocomplete results and cannot establish a complete narrator catalogue. CI must not relabel it as complete. An unmatched local query has a clear empty state; coverage help can live in the lookup's help popover rather than a large permanent warning.
7. Remove the separate online narrator input and “Search Dorar” button from the desk. Do not substitute automatic background network lookup or move these same confusing controls into another main panel.

CI creates reviewed assets; it does not migrate user Saved data or refresh them silently at runtime.

## 12. Implementation order and completion gates

| Phase | Deliverable | Required proof before proceeding |
| --- | --- | --- |
| 1. State and capabilities | Applicable controls, stable filter UI state, committed-page/pending-request separation, reader ownership | Regressions for scrolling, edits, debounce/failure, retained criteria and stale completions; no unsupported filter panel/button/shortcut/sheet |
| 2. Workspace composition | Full-height reader, main-area icon navigation, one context query, toolbar sort/takhrij; removal of cache/provenance and paging-limit UI | Arabic/English, light/dark, compact/wide, both panels resized/closed; reader flush under app bar and results mounted under compact sheet |
| 3. Source presentation | SDK VerdictTone adoption and consumer migration; capability projection and advertised Asbab; structured Sharh sections and clean UI labels | Verified SDK tone contract and preserved warning-sharing constraints; real fixtures covering direct/similar/unknown explanation relationships, distinct embedded citations, glossary/Quran links, missing/empty/failed sections and source-range integrity |
| 4. Reading and export | Narration/hukm hierarchy and semantic ruling treatment; faithful skeleton; readable share composition; explanatory copy and dynamic phrase rows | Positive/negative/unmarked captures, paired loading/loaded captures; actual default/all-options and long/short exported images; negative ruling preservation; add/remove phrase focus and four-slot validation |
| 5. Reference delivery and cleanup | Candidate-refresh CI and removal of obsolete discovery UI/state/tests/localizations | Snapshot validation and offline lookup checks; historical IDs retained; old consumers removed or explicitly retained as SDK-only APIs |

Before visual implementation, make one concrete desktop/compact composition and one representative all-options share-image preview from the agreed reference, including a long Arabic record, a distinct explanation citation and multiple source chains. Inspect that direction before expanding the changes.

Final acceptance must cover:

- Every complaint above with a source change or an explicit verified adaptation. No empty functional panels, raw separator labels, duplicated metadata or unexplained counterpart controls.
- No cache provenance, fetch timestamps or source paging-limit explanation anywhere in the user interface, including tooltips and popovers. Religious citations remain readable.
- Opening all filter groups, editing every kind of field, scrolling away/back, result scrolling, pending requests, failure/retry and column/sheet transitions preserve open groups and editing state. Record widget disposal to explain any remaining reset.
- No full-card skeleton replay or immediate reader collapse during refinement. No stale page is labeled with criteria it did not use.
- The actual exported image is readable at ordinary phone scale with all available options enabled; meaningful distinct citations and source warnings remain intact. Reducing content selection is not an acceptance workaround.
- Narration and exact hukm are the two obvious reading anchors in cards, reader and exports. SDK tones carry consistent semantic emphasis; text and icons keep distinctions understandable without color. Unmarked wording is never promoted to a positive verdict.
- Settings and Saved compatibility tests pass. Existing unrelated work and the SDK metadata fix remain intact.
- SDK and adapter analyzers/tests for package changes; app analysis and full tests for this coordinated feature/package change. Regenerate only changed generator inputs/localizations.
- One bounded native inspection batch covering the affected flows, themes, locales, widths and exports; one confirmation batch after fixing its defects. Record source/provenance and qualify synthetic loading fixtures. No performance claims without runtime measurement.
- Final diff includes cleanup of replaced helpers, provider consumers and ARB strings. Preserve useful SDK services; remove dead app presentation and explanatory state rather than leaving alternate paths behind.

## Evidence and references

Sources inspected: `hadith_screen.dart`, `hadith_provider.dart`, the session model, filter form/lookups/discovery, results/card/loading widgets, detail/Sharh rendering, share-card composition/options, the prior Sharh widget at HEAD, SDK parsers/render tokens/capabilities/query serializer/refresh tool, relevant Hadith tests and both release/package workflows. Implementation dependency authority is the resolved hosted Dorar SDK and Flutter adapter 0.7.0, Forui 0.27.3 and Skeletonizer 3.0.0. The initial diagnosis inspected local SDK 0.6.1; reference-maintenance tooling changes remain in that separate SDK checkout.

Forui's public [control ownership model](https://forui.dev/docs/concepts/controls), [accordion](https://forui.dev/docs/widgets/data/accordion) and [tooltip](https://forui.dev/docs/widgets/overlay/tooltip) documentation support the planned component choices. The resolved implementation, rather than current documentation alone, remains the API authority.

## Implementation record

- The active endpoint owns filter applicability. Topics, category browsing, Saved and explanation search have no empty filter panel, button or sheet. Category takhrij remains available in result options. The reader fills the feature height beneath the app bar; the main region owns icon navigation. Compact layouts use the persistent sheet and breadcrumbs.
- Filter interaction state belongs to the mounted route. Accordions use an immutable selection snapshot, and scroll, query text, phrase identity, cursor and focus survive panel remounts. Regression tests reproduced and fixed the accordion predicate and scroll reset. Optional phrases are added on demand, up to the SDK's four slots. Lookup drafts remain local; the separate online narrator and scholar-book discovery controls were removed.
- Filter requests retain committed cards, their matching query/criteria and the selected reader. Pending and failed refinements do not replay the initial skeleton or unmount cards. Retry and stale-completion handling remain covered. Pagination uses the criteria of the displayed committed page.
- Narration and exact source ruling are the reading anchors in results, the reader and exports. SDK positive/negative/unmarked tones drive appearance; positive/negative icons preserve a distinction beyond color. Contrast is tested against each actual tinted surface in every app palette and theme. The legacy warning heuristic remains only in the mandatory warning-sharing guard for old unmarked Saved records.
- Advertised Asbab appears as a pill and opens directly, like other available sections. Unknown availability is not probed automatically. Raw explanation separators are removed only from display labels. Structured Sharh blocks render as paragraphs and citations; matching citations appear once and distinct qualifications remain visible.
- Exports retain all selected content with readable narration, ruling, one primary citation, compact distinct explanation citations and separately spaced Usul chains. The inspected all-options example includes both a related explanation and three source chains. Display projections preserve stored religious text and source ranges; copy text remains sourced.
- Loading and loaded cards share the responsive frame and attribution geometry. Loading is quiet and static. Sort and takhrij moved to compact result options, with simple tooltip explanations. Cache provenance, fetch times and paging-limit explanations were removed entirely from product UI and localization outputs.
- Build Runner and localization generation were performed. Existing Saved/settings compatibility, negative-warning sharing, structured source annotations and architecture contracts remain covered.
- The local SDK now has a reference-candidate workflow and portable refresh command. Offline candidate validation, SDK tests and adapter checks passed. This workflow is inside the separate SDK repository and must be delivered there before its automation runs; it was not run upstream or published in this task. Hosted 0.7.0 assets are the app's runtime authority.

## Verification record

Evidence directory: `/home/moath/.local/state/tawaq-delivery/hadith-root-repair-20261008`.

The first native inspection batch contains 38 captures across Arabic/English, light/dark, app palettes, compact/wide widths, large text, loading/results, reader trails, Saved, prose, Topics/categories and export. The confirmation batch contains 24 captures, including the corrected skeleton and positive/negative ruling treatment, compact sheets and full-height reader, plus default and all-options export images. Selected images from both batches were opened and inspected. `record-page.json` and `category-page.json` retain response provenance; the confirmation record sample contains 17 positive and 13 negative tones.

The app was normally launched with FVM on Linux in debug mode. App settings and Saved were isolated in the task directory. Responses used the real Dorar SDK, including its existing response cache. The loading preview changes async presentation state synthetically. The harness drives mounted Flutter callbacks and text controllers and captures app render buffers; native pointer/keyboard delivery was not verified. The owned process/window was placed by verified PID and checkout without moving the user's windows, then exited normally. No Flutter exceptions were recorded in either completed batch. Resize-related GTK/OpenGL warnings are retained in the logs; no performance improvement is claimed.

The confirmation's refinement frame sample stayed on explanation search, where record filters do not apply. It is excluded as proof of filter continuity or request motion. The harness now explicitly selects record search and rejects capture if filters are absent. The passing interaction regressions, rather than that sample, prove accordion, draft/cursor, scroll, card identity and reader continuity. No third visual polish pass was performed.

Checks:

- Full app analysis: passed with no errors or warnings (648 informational diagnostics), recorded in `analyze-handoff-final.log`.
- Full app suite: all 1,249 tests passed, recorded in `app-tests-handoff.log`.
- Local SDK analysis: no issues; 367 tests passed.
- Local Flutter adapter analysis: no issues; seven tests passed after regenerating stale test assets in an isolated build directory and restoring the pre-existing build artifacts.
- Release acceptance tooling: six Python tests passed. Offline reference-candidate validation passed.
- Root and SDK diff whitespace checks passed. Baseline diffs and status were retained; unrelated prior changes and the SDK's metadata work were preserved.

The first full-suite attempt passed 1,236 tests and failed 13 Fortress tests because the concurrent Linux build temporarily removed a generated SQLite shared library. This was a build artifact failure, not a Fortress source change. The suite was restarted after the native build completed; its final outcome is above.


## Desktop sizing follow-up

Moath's subsequent screenshots exposed a landing-only branch that forced a filter overlay on wide windows. The overlay inherited transparent content, so its heading and controls painted over the main navigation and landing content. Wide landing pages now use the same remembered, resizable filter column as record search. Compact filter sheets paint an opaque theme surface. No extra preference or parallel interaction state was introduced.

The main reading area now caps its width at 880 logical pixels and centers inside the remaining desktop workspace. This applies to search, loading, Saved, Topics and category results, while the reader and filter surfaces retain their full feature height. Topic children and topic search results use two columns where their available width permits and one column when compact. Result-card rulings fit their text; reader and exported rulings retain their prior layout.

Four Arabic/English regressions failed before the repair: the card was 1,888 pixels wide at a 1,920-pixel viewport, and landing filters never reserved a desktop column. They now pass, together with checks for an opaque compact sheet, short ruling width, two-column subtopics and compact single-column fallback. All 108 Hadith tests pass. Full app analysis passes with no errors or warnings (651 informational diagnostics). No generation was needed for this follow-up, and no dependency or source content changed.

Evidence: `/home/moath/.local/state/tawaq-delivery/hadith-desktop-density-20261008`. The initial native inspection captured the corrected desktop filter layout, then its harness clicked before the resize reached the compact layout and stopped. The harness now waits for that layout before opening the sheet. One confirmation batch contains 24 captures covering Arabic/English, light/dark, desktop/compact filters, subtopics, results and readers. Representative PNGs were opened and inspected; the completed batch recorded no Flutter errors. Responses came through hosted Dorar 0.7.0, including SDK cache. Captures exercise mounted callbacks and render buffers; native pointer/keyboard delivery remains unverified. Owned processes exited normally and the user's existing windows were left in place. No performance claim or additional polish loop is made.


## Sidebar and request feedback follow-up

The app sidebar now owns Hadith navigation. Its parent opens the study desk and preserves filter drafts; Topics and Saved are indented destinations. Both expanded and collapsed sidebars retain these destinations. Viewports without the app sidebar use a compact menu. The redundant feature header and Back button were removed; reader and category breadcrumbs remain. Home navigation invalidates pending requests so late completions cannot reopen results.

The filter column has a 300 logical-pixel minimum, scaled with the app typography. Every selected filter tag wraps its complete source label within the available width and retains a reachable remove button. This also covers scholar, book and narrator lookup selections.

Pending refinements show localized updating text and a thin progress bar in a fixed toolbar slot. Committed cards, query highlights, reader selection and editor state remain visible. Regression coverage checks both card identity and position during refresh. Matching words use a restrained primary tint and stronger text weight; exact source ranges are unchanged and foreground contrast passes in every app palette and theme.

Native evidence: `/home/moath/.local/state/tawaq-delivery/hadith-pr-20261009/native`. The completed inspection includes 24 states across Arabic/English and light/dark, with zero captured Flutter errors. It exercises mounted sidebar callbacks and real SDK results; the six-second refresh clip is an intentionally extended pending-state preview from native render frames. OS pointer/keyboard delivery and request latency are not measured. The owned app process exited normally. No additional visual polish pass was needed.
