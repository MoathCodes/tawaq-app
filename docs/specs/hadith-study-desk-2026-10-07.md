# Hadith study desk: replacement-screen specification

Date: 2026-10-07. Status: implemented in the current checkout; study-desk direction confirmed by Moath, with card and ruling presentation revised to align with Tawaq. See [implementation and validation notes](../releases/hadith-study-desk-2026-10-07.md). This contract does not authorize a storage migration.

## 1. Outcome and authority

Replace the Hadith screen from its composition and session model upward. A person should be able to search, refine results, inspect a narration's sources and explanation, follow related narrations, and return to the same results without losing their place. Saved records must remain available and intact.

The confirmed structural authority is [Moath's study-desk HTML](../design/hadith-study-desk/reference.html): a quiet reference workspace with separate filters, results and reading areas; clear source rulings; readable Arabic; and restrained actions. Preserve that topology and hierarchy. Tawaq's existing theme and components govern surfaces, color and control styling. Moath explicitly rejected copying the reference's card and grade-color treatment; the replacement below takes precedence over those parts of the HTML. Adapt illustrative content and unsupported controls to real Dorar responses.

The route operates as a research tool; the reader supports sustained reading. This is a desktop redesign for Linux, macOS and Windows, with compact desktop windows, Arabic/English UI, both directions, all existing palettes and text scales. It does not introduce a new application shell or mobile product.

The baseline is the current working tree after Dorar adoption, based on app commit `a5b35af8`, with core/adapter 0.6.1 at submodule revision `ed470db6c62a38a701ecb4100a7fa39a6cb2fb13`, Forui 0.27.3 and FVM Flutter 3.47.5. Preserve the adoption changes. Recheck the resolved package source if these versions change before implementation.

Completion requires one reachable screen implementation and one runtime owner for each rule. The old screen must be removed, rather than hidden behind a switch or left as a parallel route.

## 2. Scope and deliberate adaptations

| Reference element | Production decision |
| --- | --- |
| Three work areas | Filters at logical start, results in the middle, reader at logical end. Arabic mirrors the arrangement. All remain within the existing app shell. |
| Large search landing | Keep the search-first landing, real recent queries, saved-record entry and SDK thematic discovery. No request for search results occurs on route entry. |
| New icon rail, clock, player | Use the existing shell/sidebar/app bar. Do not duplicate navigation, playback or prayer/location state inside Hadith. |
| `٢١` books, `٢٠` scholars, `~١٤٬٠٠٠` narrators | Remove these illustrative numbers. Optional reference information reads the installed SDK manifest and distinguishes partial narrator coverage. Keep counts out of the main landing. |
| Hardcoded category tiles | Load observed thematic roots and children through the SDK. Source labels stay exact. Categories are a browse mode, not an invented text-search filter. |
| “Hadith of the day” | Omit. No curated corpus or daily-selection contract exists for this task. A saved-record preview may use actual local data, with an accurate label. |
| Scope chip “شروح” | Label record scope `أحاديث لها شرح` / “With an explanation”. Searching explanation prose is a separate target. |
| Detailed/quick `~30`/`~15` toggle | Omit from this release. Detailed records support the desk; prose is the other search target. Quick search is supported by the SDK but returns `Hadith` without record IDs, rich documents or detail links. A future quick mode needs its own typed result/action policy; do not fabricate a `DetailedHadith` to make it fit. |
| Circumstances tab marked “proposed” | Implement real `AsbabResult` when an eligible record is selected. Display the source's relationship label; do not turn similar circumstances into a claim about the selected narration. |
| Green/red classification, grade pills and inset stripes | Replace with a neutral labeled source-ruling row and quiet themed cards. Keep exact rulings and existing conservative warning projection. Selection uses the theme accent, independently of grading. Do not introduce a positive authenticity classifier or infer authenticity from the search filter. |
| Grouping scholars' statements | Render SDK structure and reviewed annotations only. Do not infer speakers from names, colors, quotation marks or `قال`. |
| Cached/offline banner | Show cache provenance only when supplied. Saved records and installed references work locally. A matching unexpired SDK cache entry may satisfy a request; there is no complete offline Hadith corpus or cache-history browser. |
| Fixed reader/filter widths | Use available feature width and text scale to choose three, two or one work area. The reference contains no compact-layout implementation. |
| Amiri and external font request | Keep the bundled IBM Plex Sans Arabic and existing fallback system for this release, with a larger reading scale. No Google Fonts request or unreviewed font dependency. |
| Demo state switcher | Keep only in the archived reference. Production states come from owners and responses. |

Included SDK additions: thematic roots/children/search/browse, circumstances, explicit scholar-associated book discovery and optional online narrator-choice discovery. Included detailed-search controls: exclusions, up to four optional phrase slots, source degree ordering and specialist mode. The SDK's own validation remains authoritative.

Out of scope: narrator biographies/graphs, automatic translation, invented speaker annotation, general book/scholar encyclopedia screens, daily recommendations, new bookmark formats, bulk bookmark migration, unrelated shared layout redesign and cache-management UI.

## 3. Information architecture and layouts

The existing `/hadith` route remains the entry point. Add feature-local navigation for Search, Topics and Saved; these do not become new global sidebar entries. Search target remains Records or Explanation prose. Topics and Saved are collection contexts, not additional search targets.

### Landing

Show a spacious localized title, supporting text and one primary query row. Keep the Records/Explanations target in a compact menu inside the query field. Below it, show up to eight source-backed topic tiles beside a quiet vertical list of up to five recent queries; stack these areas in compact windows. The complete topic catalogue is available through topic search. Give Saved a clear action. Empty recents have a subdued heading and empty message; topics retain their own loading and retry state. The absence or failure of thematic discovery must not block search or saved records.

Focus the query on an explicit search-focus shortcut, rather than stealing focus from the app shell on every rebuild. Clicking a recent query commits it using the currently selected target, as recents remain query-only. Its individual remove action must not also submit the query.

### Workspace geometry

Use `LayoutBuilder` constraints **inside the feature after shell/padding**, not the full window width. Minimums start at filters 260, results 380 and reader 360 logical pixels, with room for dividers. Raise the minima for the shipped large text scales using the same centralized layout policy; do not scatter breakpoint comparisons across children.

| Available feature width | Composition |
| --- | --- |
| Fits all three minimums, approximately 1,020+ at normal scale | Filters + results + reader; results expand. Initial filters approximately 280; reader approximately 420. Both side panels have a close control in their own header and independently persisted resize handles. Empty readers remain closed. |
| Fits results + reader, approximately 750–1,020 | Results + reader. Filters open in a Forui persistent side sheet from logical start. |
| Does not fit results + reader | Results occupy the route body. Selecting opens the same reader in a Forui persistent sheet from logical end, bounded to 520 pixels and 92% of the feature width. Results remain mounted and accessible behind it. Filters use a persistent sheet. |

The numbers are initial design constraints to verify at runtime, not a permission to force three columns into a 1,200-pixel window whose shell consumes space. At higher text scales the layout changes earlier. Verify whole windows at 1,440×900, 1,200×800, 800×700 and the shipped minimum 664×718.

Use independently resizable filters and reader areas. Reuse nested `PersistedHorizontalSplitPane` instances for the two boundaries; it already coordinates `FResizable` sizing and drag stability. Do not rewrite shared core split behavior to build a feature-specific three-column grid. Clamp transient extents to the current available space, but persist only explicit user resizing or visibility actions.

Viewport changes do not change the user's filter visibility preference or lose selection. Crossing into compact mode retains reader identity and scroll position in a persistent sheet, with Close and Escape/trail navigation; returning to wide mode restores the same reader. Do not accumulate hidden dialogs during resize. Use one feature-local `FSheets` host; dispose owned controllers after hiding, promote sheets back to columns on resize, and update sheet geometry/direction without clearing selection.

Results have a pinned search/filter summary and bounded, lazy scrolling list, followed by pagination. Filters scroll independently. The reader has a persistent action row and a single vertical content scroll containing narration, source metadata, the Forui section tabs and their selected content. The tab row can scroll horizontally; it need not become a custom sticky tab implementation in this release. In compact reader view, Back and the action row remain available even for very long narration.

### Visual hierarchy

Use existing theme colors, spacing/radius tokens and focus outlines. Manuscript inherits its warm surfaces and gold accent; Sage and Omarchy inherit their own palette. Do not hardcode the HTML's colors or add a Hadith-specific semantic palette. Keep specialist mode as a compact checkbox. Collapse scholar/book/narrator discovery into grouped Forui accordions. Use feature-local Forui style deltas for the reader's simple underline tab treatment rather than changing global tab styles.

Result narration is the focal content, followed by exact source rulings, then narrator/scholar/source and capability actions. Start near 20–22 logical pixels for result narration, 24–28 for reader narration, and 16–18 for explanation prose with generous Arabic line height. Apply app text scale once. Metadata uses the existing body scale; do not shrink it to make columns fit. Avoid forced justification and arbitrary truncation of rulings.

Result actions occupy a stable trailing cluster, not absolute positions overlapping long Arabic. Metadata wraps from columns into stacked labeled rows as space decreases. Selection and source warnings have separate affordances. Hover never reveals the only route to an action.

### Card and source-ruling treatment

Cards are quiet reading surfaces: `colors.card`, a one-pixel `colors.border` outline, `radii.lg`, and `AppSpacing.lg` padding. Use consistent vertical spacing rather than nested boxes around narration, ruling and metadata. No elevation, inset grade stripe, tinted grade background or decorative status dot. Narration leads; the ruling sits immediately below it; compact source metadata and actions finish the card.

Use a labeled text row, `حكم المحدث` / “Scholar's ruling”, instead of a pill. The label uses `mutedForeground`; the exact source ruling uses `foreground` with medium weight. Preserve the scholar attribution alongside the source metadata. Meaningful distinct short and expanded rulings remain in source order, with the expanded wording on a separate wrapping line. The label is localized; neither source field is translated, shortened or replaced with an app verdict. Missing rulings omit the row rather than implying approval.

| Element/state | Theme treatment |
| --- | --- |
| Ordinary result | Card surface and normal border; narration and ruling use readable foreground. |
| Hover | Subtle secondary surface with the existing interaction/focus behavior; no change to ruling meaning. |
| Selected result | Secondary surface plus primary outline and semantic selected state. Accent identifies the open record regardless of its ruling. |
| Keyboard focus | Existing theme focus outline, separately visible from selection. |
| Source warning | Same neutral ruling row, with a small foreground warning icon and stronger text weight. Include the exact source warning in accessible text; the icon never substitutes for it. |
| Saved action | Existing bookmark icon and theme accent; independent of ruling. |

The conservative `hadithSourceJudgmentTone` projection still determines whether source-warning emphasis is required; this is a presentation change, not a new religious classification. Positive, unknown and qualified wording stays exact. No green “approved”, red “rejected” or amber third grade is added. Theme destructive/error roles remain available for destructive actions and operational failures; they do not color a religious ruling. Sage's green primary, for example, denotes interaction rather than authenticity.

Use the same ruling presentation in the reader, related/context records and image-share preview/output, with layout appropriate to each surface. The reader has no large colored grade panel. Source warnings remain fully visible and mandatory in applicable copy/export options and rendering. Text-copy wording and persisted data are unchanged. Verify contrast, long qualified rulings and both source fields in every palette; no warning may disappear through truncation or muted text.

## 4. Search and filter contracts

One session controller owns committed query, target, filters, collection context, loaded page, pending operation and reader selection. The editable query draft and text-field focus belong to the widget. Forui controls receive lifted values and callbacks; they do not own competing filter, selected-tab or pagination state.

Submitting commits the trimmed query without normalizing source wording. Search runs on Enter/Search, target changes for a committed query, and filter changes after a 250 ms debounce. Do not make remote search fire for every typed character. A blank record query can submit when a valid optional phrase is provided; prose requires a nonempty query. Validate field lengths and phrase count using the resolved SDK rules and show field-level feedback before sending.

Changing a request dimension invalidates pending work, resets to page one, clears the old reader selection and next-page empty boundary, and starts the new request. A stale completion may populate its provider/cache but cannot replace the active page or reader. Preserve generation guards through any controller rewrite. Filters remain editable during pending requests; newest intent wins.

### Filter vocabulary

| Group | Control and behavior |
| --- | --- |
| Search method | Single-choice All words / Any word / Exact phrase. Default remains Any word. |
| Record scopes | Multi-choice Marfoo, Qudsi, Companion reports, With explanation. “All” is an empty set, not a fifth value. |
| Source degree | All four existing `HadithDegree` values; retain source meaning and current localized labels. Multiple values allowed. |
| Scholar | Searchable multi-select of `ReferenceChoice` IDs/labels from installed reference data. Historical choices remain decodable and selected. |
| Book | Offline searchable multi-select. With scholars selected, offer an explicit “Books associated with these scholars” discovery action, with current-selection coverage. Returned books describe assessments, not authorship. |
| Narrator choice | Offline multi-select with a partial-coverage hint. After a local query, an explicit “Search Dorar” action may fetch online choices. Do not send the query automatically as an offline-lookup fallback. |
| Advanced | Excluded words/phrases, optional phrases (0–4), specialist mode and source degree ordering. Default sort is null; the only exposed sort is `HadithSort.degree`. Specialist copy describes the source's specialist/takhrij mode without making an expertise claim about the user. |

Scholar-associated books must retain selected books even when an updated discovery response omits them. Mark an omitted selection as outside the returned suggestions; absence from a scoped list does not invalidate its ID. Scholar changes invalidate the discovery response key, not the selected books. Store the current scholar ID set with discovery state and reject stale responses.

Lookup queries use the SDK's reference search and the established symmetric Arabic normalization for any app-side matching. Display labels stay exact. Debounce lookups at 200 ms and use the current minimum of two trimmed characters. Loading, empty, error and retry content remain inside the affected select. Selection uses scoped ID identity rather than label or full-object equality, because distinct IDs can share a name. Preserve selected labels when they are outside the current suggestion page. Bound/scroll suggestions rather than building all 11,479 narrator choices into a menu.

Active chips are derived from the applied request, labeled individually and removable by one callback. Count selected criteria consistently; do not count the default Any word or All scope. Inactive record filters are retained when switching to prose, shown under a concise “Retained for record search” notice, and excluded from the request and active-count display. The prose target sends only `SharhTextSearchParams`. Topics expose only category navigation and specialist mode; retained text-search filters must not appear applied there.

The filter sheet commits changes with the same controller/debounce as the desktop column. Closing it does not undo edits. Use Close, not an Apply button that implies a draft transaction. Reset clears the relevant record filter set, not query, target, recents or saved records.

### Result types and paging

Use distinct page variants: detailed record search, explanation prose, category records and saved entries. Do not store both nullable record/snippet lists and a separately writable target in the loaded page. Requests likewise distinguish detailed search from `CategoryBrowseParams` and prose search.

Detailed search normally returns up to 30 records per page and has a ten-page accessible limit. Show current page count separately from source-reported totals. When totals are truncated, explain the accessible limit and suggest refinement; never request ordinary page 11. Category browse normally uses 20 per page and is not constrained by the detailed-search ten-page limit. Prose uses its own metadata/hints; no invented total-page count.

Use numbered pagination only when a positive reachable page count is known. For unknown totals, show Previous / current page / Next from evidence. Keep previous results and selection visible while requesting another page; commit page number and reset selection only on success. Failed pagination keeps the old page and shows a local retry. A full hinted page followed by a recognized empty success retains the previous page and disables repeated Next; do not rewrite its original response metadata. A new request clears this boundary.

## 5. Results and reader behavior

### Record cards

Display exact narration and all meaningful distinct source rulings. Missing-value placeholders are absent fields. The existing judgment projection is reused for warnings; there is no new classification engine.

Expose source category labels from `record.categories` in a compact Topics menu alongside card actions, rather than another wall of links. Clicking a category opens real category browse through `CategoryId` and saves the origin workspace as a return context; it does not translate the label into a text query.

Capability actions have meaningful labels and keyboard focus. Explanation labels distinguish direct and similar relationships using the selected record's `ExplanationReference`. Counts appear only after an endpoint returns them; no prefetch of every result's explanation, sources and related lists to manufacture counts. Copy/save/share act on that card without also selecting or navigating it.

The list lazily builds cards with stable keys. Selecting keeps its position and opens the reader; changing the selected record does not replace the list. The full narration is selectable in the reader; a lengthy result may use a clearly truncated preview. Exact rulings and mandatory warning information are not silently ellipsized away.

Retain the reference's query highlighting only as a display projection. Match query and candidate with the established Arabic search normalization, map matches back to the original UTF-16 source ranges, and render the original substrings. Do not use the prototype's regex-over-generated-HTML replacement. Highlighting never edits copied/shared text, SDK annotations or persisted records; no approximate highlight is better than an incorrect source range. Cover diacritics, folded letters, supplementary characters and multiple matches.

### Prose cards

Show a readable snippet from the SDK document, a source action and selection affordance. A `SharhSnippet` identifies an explanation, not a complete record. No Hadith bookmark, grading badge or image-share action is attached to the snippet. Selection uses `SharhId` and loads the document independently. Its own page-header record may be inspected as a sourced record, but it is never presented as the searched snippet's invented metadata.

### Reader sections

| Section | Owner/data and display |
| --- | --- |
| Narration and attribution | Selected `DetailedHadith`, exact source rulings and locator. Immediately readable without optional detail requests. |
| Explanation | `Sharh` by `SharhId`. Selected origin, explanation-page header and embedded citation retain separate metadata. Render `SourcedDocument` tokens; retain legacy plain-text display when no valid rich document exists. |
| Circumstances | `ApiResponse<AsbabResult>` by `HadithRecordId`. Show source context plus every narration/document in returned order, each with its own ruling, metadata and relationship label. |
| Takhrij | Selected record's supplied `takhrij`; do not invent a separate endpoint or infer content from Usul. |
| Sources/chains | `ApiResponse<UsulHadith>` by `HadithRecordId`. All sources; `chainContent` and `narrationContent` when supplied, otherwise the exact scalar fields. No fabricated arrows, narrator graph or truncated collection. |
| Similar narrations | `ApiResponse<RelatedHadithResult>` with `.similar`. Source separated from all related records, in source order. |
| Authentic alternatives | Same result with `.alternate`. Preserve the endpoint's source label and each record's own rulings; the section title is not a blanket new authentication claim. |

Availability and request outcome are separate. An advertised section can fail and retry. Omit source-marked unadvertised sections. Selecting an unknown Usul/Asbab tab with a valid record ID requests it directly; there is no second confirmation button or checked-section state; do not claim either availability or absence before the response. Other links must not be guessed from unrelated IDs. A legacy ID-less record remains readable/shareable from stored fields and explains why remote detail cannot be opened.

Section tabs use stable semantic section IDs with a derived tab index. Omit unsupported sections for the selected kind; present recognized empty collections as one empty state without repeating source metadata first. Choose Explanation initially when an explanation reference exists, otherwise the first meaningful local section or narration-only content. Selection resets the section predictably; Back restores the previous reader section and scroll.

Mount optional providers only for the selected section or a requested share option. Inactive tabs do not fetch. Every section has independent loading, recognized-empty, error and retry states. On selection changes, slow results from the prior selection cannot supply the new record's origin label or citation metadata.

Selecting a related/context narration pushes a **reader trail**; it does not enter a replacement result-list mode. The result page, query, filters, selection highlight and scroll remain intact. Back pops that trail, then closes the reader at its root. Store parent data references and reader position without copying entire remote documents into a parallel cache. Reader navigation does not create recents.

### Documents and actions

Keep source content separate from search normalization and display transformations. Use SDK half-open UTF-16 ranges on `sourceText`. Preserve source gaps, separators, glossary occurrences, neutral quotations and source-marked Quran links. No app HTML scraping, speaker inference, text-cleaning parser or reconstructed citation model is introduced.

Glossary annotations expose the exact term and definition through a focusable action and Forui dialog. Source links use the established external-link provider and allowed HTTP(S) destinations. UI labels can be English; religious content stays in its source language with RTL content direction. Do not translate religious passages or rewrite source rulings.

Reuse the existing record copy and image-share contracts. Copy retains full source wording and attribution. Commentary copy/export uses the SDK commentary projection, excluding repeated matn while preserving scoped source context. Mandatory judgment warnings remain enforced at both options and render boundaries. Failed selected optional content blocks export, with Retry or deselection as recovery. Keep the shared preview/save/copy/drag flow and its shared-core layout; do not create a second share interaction model or broaden image options to Asbab/related collections in this release.

## 6. Topics and Saved

Topics is an explicit browse context with source-provided breadcrumbs, roots, children, category search and category result pages. Root selectors preserve their exact value, including significant trailing spaces; leaf IDs are opaque. Do not invent a complete hierarchy, translated category names, hardcoded roots or arbitrary filter combinations. A root may only offer child discovery, not direct browse; browse uses an actual category ID.

Topic discovery uses repository methods that wrap SDK services and preserve response metadata. Opening Topics triggers its roots request; cached data is labeled when supplied. Each discovery step has its own loading/error/empty/retry state. Choosing a category saves the current search workspace once; Back returns to its loaded page and position without a new remote search. A category link followed from the reader also restores its originating reader context on return.

Saved is a collection of `SavedHadithEntry` using its **actual stored key**, not a rederived display ID. Readable entries use record cards; recovered scalar records carry the existing rich-content-unavailable note; unreadable entries are visible with explicit remove/retry controls. Counts describe all stored entries and distinguish unreadable entries where needed. Empty, local load failure and failed remove/toggle states are reachable and covered.

Opening Saved suspends the current workspace in memory. Back restores it exactly. Save/remove mutations are owned by `HadithFavoritesStore`; projections never write. Removing a selected entry selects the next surviving entry or closes the reader. A failed mutation keeps the entry and reports retry; never optimistically discard a corrupt value.

The database, original keys/values, scalar recovery, unreadable retention, pruning rules and serialized recent-write ordering remain unchanged. No state cleanup deletes user data or silently rekeys ID-less favorites.

## 7. State ownership and persistence

Replace the screen/session coupling with a feature presentation session model. UI async outcomes belong in presentation rather than a domain model importing Riverpod. Keep feature-neutral identity, ruling and filter/request rules in domain where they perform actual work. Reuse SDK content models.

Remove the remote initialization gate from local collection access. The current `hadithRepositoryProvider` awaits the Dorar client before favorites and recents can load. Construct the repository with local storage independently and resolve the shared client only inside remote methods, or let the existing local owners use a narrow local repository projection. Choose the smaller coherent option; do not duplicate favorite identity/mutation rules. A failed narrator asset install must not prevent Saved, recent-query removal or local record copy/share. Remote retry still uses the established failed-initialization recovery path.

Suggested minimal owners:

| Owner | Responsibility |
| --- | --- |
| `HadithSessionController` | Current request/context, committed page and pending request, generation guard, one reader selection/trail, return workspace. No persistence writes for favorites, recents or settings. |
| `HadithFavoritesStore` | Existing durable entry mutations and published snapshot. |
| `HadithRecentSearchesStore` | Existing query-only recents and serialized durable writes. |
| `HadithScreenSettingsNotifier` | Hydrated layout preferences; keep alive through layout/route transitions. |
| `HadithRepository` and keyed providers | SDK I/O mapping, local storage access, independently keyed explanation/Usul/related/Asbab/category/discovery outcomes. |
| Widget-local state | Query draft, focus, overlay presentation and scroll controllers. No competing remote page or filter set. |

Use a discriminated collection context (Search, Category, Saved) and typed reader selection (record or explanation). Related drill-down stays in the reader trail. Replace `selectedHadithKey` plus separately writable `selectedSharhId` with one selection type. A selected root record is derived from its visible collection by identity; only a related reader item not present there carries its record reference. No two mutable copies of the same root record.

Keep one suspended origin workspace for entering Saved or category browsing, with its actual loaded page, request, selection and viewport position. A new explicit search commits a new context and ends that return path. This is not a general navigation-history framework or persisted document cache. A query/filter-only snapshot that reruns the endpoint on Back is insufficient.

New layout preferences add `filtersVisible`, a filter width in logical pixels and a reader width ratio to the existing persisted object with compatible defaults. Preserve the existing persistence key (pin it explicitly if the provider class is renamed), forever cache and `persist(...).future` hydration ordering. Map legacy `sidePanelRatio` to the reader split and `sidePanelCollapsed` to wide-reader visibility. Legacy `activeTab: filters` can seed filter visibility on first decode; otherwise use the new default, visible when all three areas fit. New fields take precedence when present.

Remove the old details/filters enum from live UI. Handle its historical string in a small backward-compatible decoder; retain legacy layout fields when encoding where needed for compatibility. Do not reset the stored object or change `destroyKey` to force a clean launch. Clamp invalid ratios only in the UI projection. Current storage lifecycle regression coverage is mandatory. Search filters, pages, reader trail and result bodies remain session-only.

Split the existing `hadith_provider.dart` by actual ownership into session, saved, recents, lookup/discovery and detail providers as the code warrants. This is a cleanup of the current 674-line fan-out, not a reason to add service interfaces, dependency injection frameworks or parallel controllers. Rename/move together with consumers and generated inputs.

## 8. Forui implementation map

The resolved 0.27.3 source is the API authority. Maintainer documentation confirms [resizable regions](https://forui.dev/docs/widgets/layout/resizable), [tabs](https://forui.dev/docs/widgets/navigation/tabs), [pagination](https://forui.dev/docs/widgets/navigation/pagination) , [persistent sheets](https://forui.dev/docs/widgets/overlay/persistent-sheet) and [breadcrumbs](https://forui.dev/docs/widgets/navigation/breadcrumb). Inspect matching constructors before implementation; online examples can move ahead of the lockfile.

| Surface | Use | Verified constraint |
| --- | --- | --- |
| Filters/results and results/reader dividers | Existing `PersistedHorizontalSplitPane` over `FResizable` | Finite constraints required. Region reconfiguration resets drag extents; do not recreate configuration for unrelated provider updates. Keep `onResizeEnd` as the persistence boundary. |
| Query | `FTextField`, existing app search-focus registration | Exactly one draft controller/focus node. Explicit submission, disabled empty action and field error. |
| Target / method / sort | Inline `FPopoverMenu` for target; lifted `FSelect` for filters | Typed values; do not make target a filter or duplicate its state in a tab controller. |
| Scopes/degrees | `FSelectGroup` with multivalue lifted state | One commit from the final selection set; All means empty selection. |
| Book/scholar/narrator filters | `FMultiSelect.searchBuilder` | Async `filter`, content/loading/error/empty builders, `FSelectSearchFieldProperties`, lifted `FMultiValueControl`. `items` label maps cannot represent duplicate labels reliably; use rich items with scoped IDs and independent formatting. |
| Filter sections | `FAccordion`/`FAccordionItem` | Expansion is local view state, not active filters. Keep active selections visible in chips when collapsed. |
| Reader sections | `FTabs`, `FTabEntry`, lifted `FTabControl` | `scrollable: true`. `expands: false` mounts the selected child inside the reader's content scroll. Avoid `expands: true` inside unbounded scroll; its `TabBarView` and desktop wheel/swipe behavior are not needed here. `onPress` fires before controller update; side effects use the committed section. |
| Known page counts | `FPagination` with lifted `FPaginationControl` | Forui is zero-based; SDK is one-based. `pages` must be positive. Control committed value, pending disabling and explicit previous/next actions from the session; do not let its internal controller claim a failed page succeeded. |
| Unknown page counts | `FButton` Previous/Next and current-page text | No fabricated numbered page range. |
| Compact filters/reader | `FSheets`, `showFPersistentSheet` | Choose logical start/end from ambient direction, bound the width and preserve the underlying result list. Panel-local Close and Escape coordinate session state and controller disposal. |
| Topic and reader navigation | `FBreadcrumb`, `FBreadcrumbItem` | Preserve exact SDK labels/selectors in the session. Ancestor actions restore the relevant topic path; reader ancestors retain the loaded page. Bound long trails with horizontal scrolling. |
| Actions | `FButton.icon`, `FTooltip`, optionally `FPopoverMenu` | Semantic labels plus tooltips; no clickable spans. Prevent nested action propagation to the card's selection. |
| Result surfaces and source rulings | Existing accessible result interaction wrapper plus Forui theme tokens; labeled wrapping text for rulings | One feature-local ruling presentation shared by list, reader and image export. Do not use status-colored `FBadge` variants for religious grades or force rich result content into a restrictive stock tile. |
| Passive category/cache/count labels | `FBadge` | No unlabeled interactive filter removal; removable chips use actual buttons. Rulings use the text presentation above. |
| Notices and errors | `FAlert` and existing error/toast helpers | Typed failure mapping, localized recovery, exact source context. |
| Loading | Feature-local card bones in `Skeletonizer.zone` | Keep card surfaces still; pulse only neutral text, ruling, attribution and action bones. Honor reduced motion with a solid effect. No white shimmer slab or invented religious text. |

Forui owns widget-level interaction/accessibility; Riverpod owns session and request state. Retain only adapters that coordinate real behavior. Before replacing the lookup controller's current retry technique, prove that a retry reruns the same async filter while retaining query, selection and focus; cosmetic simplification is not enough.

## 9. Loading, failure, cache and accessibility

| State | Required result |
| --- | --- |
| First route visit | Usable landing, recents and target. SDK initialization is lazy; reference/topic readiness does not freeze local controls. |
| New query loading | Clear old selection, show result placeholders and pending query; controls accept a new intent. No stale results presented as the new query. |
| Pagination loading | Previous page remains readable, pagination reflects pending state and disables duplicate requests. |
| Recognized empty search | State the committed query/target; offer explicit filter reset or edits. Do not silently change matching method or start prose search. |
| Request/initialization failure | Localized error and user retry; reset failed initialization owners only when appropriate. Retain input and selected filters. |
| Parse/layout failure | Say the source response could not be read. Do not treat as no results or show prototype content. Strict parsing remains the default. |
| Timeout/rate limit/server failure | Derive from SDK exception, including reset time when supplied. Do not claim “15 seconds after three attempts” or an offline state without evidence. |
| Detail loading/error | Existing narration and other sections remain usable; retry only the failed section. |
| Cache hit | A subtle cache label, with fetched time/source on request when available. It does not assert the OS is offline. |
| No network/cache for request | Explain remote content is unavailable; Saved and installed references remain usable. No auto-repeated retry loop or cache purge. |
| Lookup/discovery failure | Local retry plus retained selections. Available offline suggestions remain visible when explicit online discovery fails. |
| Export/mutation failure | Keep selected options or saved entry; retry/recovery remains reachable. |

All controls use stable keys, labels and logical traversal order. Scope ArrowUp/ArrowDown to result navigation while result focus is active; do not steal arrow keys from query editing, select menus, reader text selection or scrolling. `/` and the existing platform search shortcut focus the query outside text entry. `F` toggles filters outside text entry; register it through the shortcut catalog with ARB labels and collision tests. Enter submits query or activates the focused result. Escape closes the topmost popover/sheet first, then pops reader trail/closes reader, without discarding the search.

Compact Back, reader close and overlay dismissal restore focus to the triggering control/card. Announce settled result count and selection concisely; asynchronous lookups must not announce stale results. Keep source text selectable without nesting controls into selection gestures. UI mirrors with locale while Arabic passages remain RTL. Reduced motion disables loading shimmer/pulse and uses established transition behavior. No continuous animation solely for visual atmosphere.

## 10. Cleanup and fan-out ledger

Removal is a deliverable in each implementation step. Change imports, consumers, tests and generated inputs together. Do not wait until a final “cleanup” PR to remove duplicate paths.

| Current area | Disposition |
| --- | --- |
| `presentation/screens/hadith_screen.dart`: `_HadithSidePanel`, two-tab filters/details composition and compact-specific detail opening | Replace with the desk layout policy and shared reader presentation. Keep only the public route entry if its name remains useful. |
| `widgets/hadith_search_column.dart` | Replace old back-to-specific-mode/search chrome with landing/workspace toolbar and target control. Keep app search-focus mechanics. |
| `widgets/hadith_results_column.dart`: mode-switching orchestration, `_ProseResults` modal, bookmark rendering branches, old pager | Replace with typed collection rendering, separate saved-entry handling and capability-aware pager. Delete unreachable branches. |
| `widgets/detail/hadith_detail_pane.dart`: inline detail accordion and embedded-card navigation | Replace composition with the reader and lazy section bodies; reuse exact source field/Usul rendering where sound. |
| `widgets/filters/hadith_filter_form.dart` | Replace with filter-column/sheet body and new supported controls. No duplicated wide/compact forms. |
| `widgets/filters/hadith_lookup_section.dart` | Refactor into scoped typed select/discovery behavior; retain proven async retry, normalization and selection contracts. |
| `domain/models/hadith_session_state.dart` | Replace legacy `HadithViewMode.specificList`, mixed list payloads, compatibility aliases (`isLoading`, `error`, unknown-page `0`) and query-only return snapshot. Async presentation state moves to presentation. |
| `presentation/provider/hadith_provider.dart` | Separate durable owners from the session. Remove `bootstrap`/signature machinery when unused, `openSpecificList`, `exitSpecificMode`, side-panel tab writes and visible-results helpers superseded by the typed context. Preserve cancellation/pagination/mutation contracts. |
| `domain/models/hadith_persisted_settings.dart`, settings notifier | Evolve compatible layout preferences. Remove obsolete enum usage from runtime; preserve historical decode and storage key. |
| Existing detail provider families | Reuse typed ID/content contracts; add Asbab/category/discovery. Share and reader use the same keyed fetch owners, not parallel caches. |
| `data/repository/hadith_repository.dart` and local-store readiness | Separate local access from Dorar readiness while retaining one mutation/identity implementation. Add coverage proving saved/recents access when remote initialization fails. |
| `hadith_identity.dart`, `hadith_judgment.dart`, SDK renderer | Retain exact-source and identity logic. Update representative consumers if interfaces change. No new parser pipeline. |
| `widgets/results/hadith_hukm_badge.dart` and its list/detail/share consumers | Replace the tinted badge with the shared labeled source-ruling presentation. Remove obsolete tint/ink helpers after the last consumer moves. Port exact-wording, warning, wrapping and contrast coverage in `hadith_result_card_test.dart`; retain judgment and mandatory-share enforcement tests. |
| Local DB/favorites/recents | Retain compatible storage and mutation ownership. Any move/rename keeps decoding, keys and serialized writes unchanged. |
| Share options/card/text/export/actions | Retain behavior and shared layout; update provider imports and reader entry points. Preserve warning constraints and commentary scoping tests. |
| ARBs/generated localizations | Add the new vocabulary, remove truly unused Hadith screen strings after tracing references; regenerate. Do not hand-edit generated Dart. |
| Tests | Replace assertions enforcing the discarded topology/`specificList`; port behavioral assertions rather than deleting coverage. Keep source/persistence/ordering/stale-request tests. |
| `tool/launch_visual_harness.dart`, recovery harness, fixture capture | Replace Hadith scenarios/selectors with the new flow; retain other feature scenarios. Keep SDK fixture capture and package-storage isolation. |
| `lib/app/routing/route_provider.dart` and shell | `/hadith` remains compatible. App-wide search focus and shortcut documentation/labels are affected consumers. Preserve playback, prayer and tray composition. |
| Shared split/dialog/share-card/select/theme infrastructure | Retain unless an actual contract defect is demonstrated. Any change requires representative Quran/Fortress/settings checks and full app verification. |

The old Dorar cleaner, sharh metadata parser/normalizer/tokenizer/zone splitter and private-cache tools were already removed by adoption. Confirm they remain absent; do not recreate them under new names. Remove abandoned parser fixtures only after searching all consumers, including tooling and current source-rendering tests. Historical release/audit documents remain evidence, not live code to purge.

## 11. Implementation sequence

1. **Freeze contracts and fixtures.** Preserve the adoption working tree. Capture realistic SDK pages/documents for records, prose, categories, Asbab, direct/similar explanation origins, all related records and unavailable/failed responses with provenance. Record current UI and durable storage behavior. Add failing tests for exact Back restoration, layout transitions and category-specific paging. No hardcoded prototype religious data enters fixtures.
2. **Replace session/navigation ownership.** Add typed requests/pages/selection, saved origin workspace and reader trail; port generation/debounce/pagination tests. Keep existing durable stores and detail families. Remove old modes, aliases and side-panel tab mutations as their last consumer is replaced. Preserve settings decode/hydration and add new preferences compatibly.
3. **Build the desk and complete search.** Landing, toolbar, filter column/sheet, active chips, typed lazy results, pager and compact reader navigation. Add supported advanced fields and capability-aware target switching. Replace the old screen/search/results/filter composition in this step; no visible legacy mode remains.
4. **Finish the reader and SDK discovery.** Shared source-aware reader, lazy section tabs, Asbab and reader-local related trail. Add Topics and explicit scholar-book/narrator discovery. Wire real categories into landing/cards. Complete empty/error/unknown/retry states and source context.
5. **Integrate durable actions and cleanup.** Saved entries, recents, copy/share and export recovery. Update all provider consumers, ARBs, shortcut catalog and harnesses. Delete obsolete widgets/helpers/strings/tests and inspect for duplicate owners. This is a verification sweep; removals should already accompany earlier cutovers.
6. **Verify and hand off.** Generate, analyze and run required tests; inspect the runtime flows below with the project SDK. Capture comparable wide/compact states. Fix all demonstrated defects, recheck affected consumers and inspect the final diff. Commit/PR work is a separate user instruction.

Each step is a bounded implementation batch with working behavior and tests. The screen rewrite can be substantial; shared core, storage schemas and source parsing remain deliberately constrained.

## 12. Acceptance and verification

The redesign is complete only when all of these agree:

- Three, two and one-area compositions preserve query, applied filters, committed page, root selection, reader trail and scroll through resize. Automatic adaptation never writes collapsed preferences.
- Search/filter/target changes reject stale responses. Prose never receives record filters; category browse never receives invented text-filter parameters; detailed search never requests page 11.
- Numbered and unknown paging, empty hinted next pages, failed pagination and retry work with correct metadata. Category page 11 is allowed when its source metadata permits it.
- Related/context exploration stays inside the reader. Back restores the original loaded search/category/saved workspace without a network replay.
- Direct/similar origin, explanation header, embedded citation, circumstances and Usul/related records retain independent exact wording and metadata. No synthetic matn, grading, translation, source count or speaker is introduced.
- Optional detail requests are lazy and independent. Every advertised/unknown/unavailable, empty/error/retry state has a truthful reachable presentation.
- Offline references, explicit online discovery, partial coverage and cache labels accurately describe their source. Dependent suggestions cannot silently remove selected books or replace newer queries.
- Existing bookmarks/recents/settings survive restart. Original unreadable values/keys remain intact. Hydration survives layout detachment; no destructive cleanup or rekeying occurs.
- Failed Dorar initialization cannot block local Saved, recents or record copy/share; retry repairs only remote readiness.
- Source rulings and mandatory warning fields remain intact in list, reader, copy and image export. Commentary-only output does not repeat narration; optional-content failure blocks export until retry/deselection.
- Cards and reader use existing palette tokens. Source rulings have no grade-colored pills, surfaces or stripes. Selection/focus remain distinguishable from warning emphasis in Manuscript, Sage and Omarchy, dark/light and large text; image-share presentation agrees with the reader.
- Long Arabic, qualified rulings, absent metadata, duplicate reference labels, large text, RTL/LTR, focus, selection, wheel scrolling, resize and Escape recovery are verified.
- No old screen route, `specificList` controller path, obsolete panel-tab mutation, app sharh parser or unused replacement widget remains. Shared consumers still work.

Keep current Hadith regression suites as contracts where behavior survives. Add/port controller tests for origin restoration and reader trails; category/Asbab/discovery request tests; layout/settings compatibility and delayed hydration tests; widget tests for source context and reachable failures. Test behavioral boundaries, not every new wrapper or style constant.

Generate with FVM from changed inputs: root build runner and `fvm flutter gen-l10n`. Include tracked localization/generated outputs where applicable. Run `fvm flutter analyze --no-fatal-infos` and `fvm flutter test`; run separate analyzer/tests for any changed local package because root analysis excludes `packages/**`. The SDK itself should not need modification for this spec.

Use the Flutter UI debugging skill for a normally launched Linux debug app with the existing gated driver flag. Verify settled live record/prose search, thematic drill-down, Asbab/related reader Back, cache/error recovery, saved-record restart and share failure/retry. Exercise Arabic/English, dark/light, normal/large text at the listed window sizes. Inspect screenshots and runtime errors, and record actual viewport, build mode and data profile. Avoid private `dbus-run-session` launch isolation on this machine.

Driver operations do not prove native keyboard or pointer delivery. Validate those separately when available and state any gap. No speed or performance improvement claim is accepted from source inspection alone; use comparable runtime measurements for the affected flow if making one.

## Evidence used for this proposal

- Attached HTML inspected in the collaborative browser at a measured 1,683×1,052 viewport; source confirms fixed 280/result/470 columns and no compact layout. Browser resize automation timed out, so this proposal does not claim a verified compact prototype.
- Existing native Hadith captures and the earlier normal-session Flutter verification show the current two-panel baseline. These are baseline evidence, not proof of the proposed screen.
- App owners: `lib/feature/hadith/`, the app route/shortcut composition, shared split/share infrastructure, settings storage gate and architecture boundary test.
- Card/ruling refinement: existing `hadith_result_card.dart`, `hadith_hukm_badge.dart` and its detail/share consumers, conservative judgment contracts, `custom_themes.dart`, app theme builder and spacing/radius tokens. The archived reference remains unchanged; this spec records Moath's requested visual override.
- Resolved Forui source inspected: resizable/region/control, multi-select/search content, tab/control, pagination/control and modal sheet. Use public `package:forui/forui.dart` imports; source paths are audit pointers, not permission to import package internals.
- Resolved Dorar source inspected: search capability/parameter/serializer contracts, record/prose models and services, category/discovery, Asbab/related/Usul, source documents/render tokens, cache transport, manifest and SDK README. [Adoption evidence](../releases/dorar-hadith-0.6.1-adoption.md) remains the dependency/source/storage baseline.
