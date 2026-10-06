# Dorar Hadith 0.6.x adoption and cleanup

Date: 2026-10-06. Status: source audit complete; implementation not started by this document.

## Result to deliver

Make Dorar's SDK the owner of response parsing, source structure, identifiers, related collections, reference installation, and endpoint limits. Keep Tawaq responsible for interaction state, localized presentation, durable bookmarks, and sharing policy. Replace the current duplicated parsing path completely, then remove its obsolete models, tests, and cache-inspection tools.

The main deletion candidate is six files containing **811 lines** of custom sharh parsing/model/cleaning code at the audited baseline. The existing 406-line sharh widget also needs a smaller document renderer. These are baseline counts, not a promised net reduction: useful rendering and regression coverage remain necessary.

**0.6.x does not supply an automatically populated, typed authenticity degree on each result.** `Verdict.classification`, `scope`, and `evidence` are optional enrichment fields; `RecordParser.citation` constructs `Verdict(raw: record.grade)`. `HadithDegree` remains a search filter. Keep the source-wording judgment policy, destructive styling for weak/fabricated/chain warnings, and mandatory source rulings in unsafe-to-share narrations. Fix the existing placeholder/expanded-ruling omission described below. Do not infer authenticity from the filter used to obtain a result.

## Evidence and dependency baseline

Audited Tawaq HEAD: `717f1248c6c448f06b1f67f32df202e7ea8f676d`, with the existing launch-readiness and UI follow-up work present in the dirty tree. The audit used current files, not just committed HEAD.

Tawaq uses two path dependencies from the `packages/dorar_hadith` submodule. Its checked-out revision is `e08eb666697c2d2fb986d825f14d46042ec259ea`, with package version 0.5.0. Two package tests have local storage-isolation edits. Their portable counterpart is `tool/fixtures/dorar-test-storage.patch`, applied by `tool/checks.sh`. Preserve these changes until the newer upstream tests are checked for equivalent isolation.

Both published core archives were downloaded and their registry SHA-256 values verified. Core 0.6.0 and 0.6.1 have identical `lib/` content; their differences are manifests and documentation. Adopt **core 0.6.1 and Flutter adapter 0.6.1 together**. The pinned FVM SDK, Flutter 3.47.5 / Dart 3.13.4, meets their minimum requirements.

| Published package | Published UTC | Verified archive SHA-256 |
| --- | --- | --- |
| `dorar_hadith` 0.6.0 | 2026-10-06 17:30:29 | `8f85f00efcfeb463c374e21e02115fb0af7153587f1dea9737e33e35aea92ae3` |
| `dorar_hadith` 0.6.1 | 2026-10-06 17:46:02 | `ecd54bd0aa048886fcb204149eb99fa8f2301769fbd1ddc7177302c4ee3601c7` |
| `dorar_hadith_flutter` 0.6.1 | 2026-10-06 17:49:35 | `2b2e8221187273066f1ce58c383357e87305f7b2aaf2501c9271fe10d0f677a6` |

Primary sources:

- [Core changelog at audited upstream HEAD](https://github.com/MoathCodes/dorar_hadith/blob/892a6cf622965747320808627b6ca9e377e03adc/CHANGELOG.md).
- [Migration guide](https://github.com/MoathCodes/dorar_hadith/blob/892a6cf622965747320808627b6ca9e377e03adc/doc/MIGRATION_0_6_0.md) and [release checks and limitations](https://github.com/MoathCodes/dorar_hadith/blob/892a6cf622965747320808627b6ca9e377e03adc/doc/RELEASE_0_6_0.md).
- [Published core metadata](https://pub.dev/api/packages/dorar_hadith), [published adapter metadata](https://pub.dev/api/packages/dorar_hadith_flutter), and the versioned archives linked by that metadata. The downloaded published implementation, rather than a cached package landing page, is the API authority for this audit.

Upstream HEAD at audit was `892a6cf622965747320808627b6ca9e377e03adc`; peeled `v0.6.0` was `100ffed14067651b3651dd87011b56a5be9deca8`. Do not equate a moving branch with the published release. Before changing the submodule, verify the chosen revision's public sources, generated outputs, adapter, and assets against the audited 0.6.1 pair and record the final revision.

Retain Tawaq's existing submodule/path dependency convention for this migration. Upstream recommends hosted dependencies for distributable package manifests; switching Tawaq's dependency-management convention is a separate choice and is unnecessary to obtain these APIs. Confirm the adapter resolves to the same root core package, then regenerate the root lockfile.

The follow-up review parsed 24 captured explanation pages with the released parser. Header and body grades differed on 12 pages, confirming that their citations must remain separate. Synthetic decoding probes confirmed that an invalid document hash, unsupported schema, or invalid range causes `DetailedHadith.fromJson` to throw `FormatException`. A synthetic ruling probe also confirmed that `grade: 'ضعيف'` with `explainGrade: '-'` produces `hukm: '-'`. These probes establish failure paths; they do not claim malformed documents or that ruling combination were found in users' saved data.

Review evidence comes from `HadithLocalDatabase._readFavoriteEntries` and its corrupt-entry deletion test, `HadithShareOptions.constrained`, `hadithShareText`, and the SDK's `DetailedHadith.hukm`, `SourcedDocument.fromJson`, and `DorarClient` method signatures. The contracts and verification cases below include the resulting corrections.

## Complete change map

Paths in this section are relative to the repository. All Hadith paths start at `lib/feature/hadith/` unless a full prefix is given.

| SDK change | Current Tawaq owner and consequence | Adoption / cleanup |
| --- | --- | --- |
| `SourcedDocument`, structural blocks, annotations, `documentRenderTokens` | `domain/services/hadith_sharh_*`, `domain/models/hadith_sharh_models.dart`, `detail/hadith_sharh_text.dart` reconstruct structure from flattened strings. | Replace the full custom pipeline with SDK documents and a feature-local selectable renderer. Delete six obsolete files after the consumers and tools move. |
| Scoped explanation header and embedded citation | Sharh metadata is currently rediscovered with Arabic-label regexes. | Render `Sharh.hadith` and independent `Sharh.embeddedHadith` with their proper scope; carry selected-record origin separately. Remove metadata regexes and guessed zone splitting. |
| `Sharh.hadith: DetailedHadith` | Test/harness constructors use `ExplainedHadith`; sharing/detail code uses a heterogeneous provider. | Update constructors, use the detailed record directly, and retain historical JSON decoding coverage. Conversion is needed only for actual old objects. |
| Explanation relationships and availability | Result chips and accordions rely on legacy IDs/booleans. A linked explanation can concern a similar narration. | Prefer `ExplanationReference` and its relationship/raw label; use legacy ID fields only for old records. Do not relabel a similar explanation as direct. Unknown availability is not proof of absence. |
| Complete alternate collection | `hadithDetail` calls the first-item `getAlternateHadith`; detail opens a one-item list. | Use `getAlternates`, show every ordered `related` item, and preserve search-return state. Remove nullable single-alternate assumptions. |
| Seed-separated similar records | `getSimilarHadith` returns the seed with related records. | Use `getSimilarResult`; retain `source` as context and render `related` only. Do not deduplicate or discard ambiguous best-effort records by guessed identity. |
| Structured usul | Provider discards the `ApiResponse` wrapper; detail/share read source and chain strings. | Keep response metadata and consume citation/chain/narration documents where available. Remove casts and duplicate parsing; retain existing share-option semantics. |
| Typed dynamic filter IDs | `HadithLookupRef` is copied into three legacy reference classes in `_toSearchParams`. | Use SDK `ReferenceChoice` for selectable labels, then `ScholarId`, `BookId`, and `NarratorChoiceId` at the request boundary. Remove the duplicated lookup model and conversion extension. |
| Typed record/explanation IDs | Detail families accept unvalidated strings and return `Object?`. | Use `HadithRecordId` / `SharhId` at feature boundaries and typed provider return values. Convert `.value` only at SDK methods that still accept strings. |
| `types` and endpoint capabilities | `HadithFilters.zone` includes `SearchZone.sharh`, sent to detailed record search. That now throws validation. | Replace legacy zone use with record-type scopes and a distinct prose-search target. Keep detailed search as the normal record endpoint; never silently switch to quick search. |
| Explanation-prose search with AJAX paging | Existing sharh scope has no correct distinct result model. | Route prose queries through `searchSharhText(SharhTextSearchParams)`; render `SharhSnippet` results, open their full explanation by ID, and separate them from bookmarkable Hadith records. |
| Pagination limits and evidence | `HadithSearchPage.totalPages` maps unknown to zero; controller repairs an empty out-of-range page by altering old metadata. | Project navigation from SDK `PageMetadata` and retain unknown totals. Remove the workaround that manufactures page limits; retain the last good page on page-request failure. |
| Strict parse diagnostics and provenance | Existing error/retry surfaces can handle failures, but metadata is discarded for some detail calls. | Keep strict default; preserve typed errors and source metadata. A malformed layout is an error, not no matches. Explicit best-effort use must visibly disclose partial results. |
| Online scholar-associated book / narrator choices | Current lookup methods are offline despite repository comments calling them remote. | Simplify offline lookups now. New online discovery can extend them later, with explicit network state and coverage; no hidden switch or canonical-person claim. |
| Schema-2 narrator normalization and manifest | Default Flutter initializer owns reference assets already. | Let the adapter install/validate its versioned database. Keep Tawaq's Arabic normalization for other features; do not add a second narrator DB migrator. |
| Raw-response cache format 3 | App already delegates caching, but three tools read SQLite values as parsed Sharh JSON. | Rewrite/consolidate fixture acquisition through public SDK calls. Delete old cache-format readers. No cache wipe or new app cache layer. |
| Validated persisted documents | `HadithLocalDatabase` treats every decoding failure as corruption and deletes the stored entry. Rich document validation adds new failure paths. | Retain the original stored value; recover valid saved scalar fields for plain display where possible. Report unavailable rich content or an unreadable entry without automatic deletion. |
| Source ruling accessors | `hukm` prefers nonblank `explainGrade`, including `-`. Sharing can suppress a meaningful negative `grade`. | Use one presentation/share projection that handles placeholders and preserves distinct meaningful source rulings. Keep warning detection separate from the text being exported. |
| Atomic/retryable Flutter initialization | `dorarInitProvider`, client and repository are lazy, with targeted retry. | Keep the established app owners. Test new adapter failure/configuration behavior; remove the package fixture patch only if newer tests make it obsolete. |
| Native assets independent of cwd, read-only references | Default adapter already configures support-directory cache storage. | Verify a built Tawaq launch from an unrelated cwd; no extra app-level asset locator/copy workaround. |
| Source-faithful dates / parsed locators | Tawaq currently displays `numberOrPage` and book labels; no book-edition screen was found. | Preserve raw locators. Use `editionDate.components` if bibliography UI is later added; do not introduce integer/date coercion now. |
| Safe HTML, reviewed speaker attribution | Tawaq uses native Flutter text, not embedded HTML. Existing heuristics style purported speaker/section patterns. | Use native render tokens; safe HTML is only for a future HTML consumer. Quotations remain neutral without reviewed evidence; remove inferred semantic attribution. |
| Thematic discovery/browse, asbab | There is no current category-browse/asbab implementation to replace. | Map as optional follow-up features, not adoption prerequisites. Reuse SDK models if added; never reconstruct scraping in Tawaq. |
| Earlier-development book constants, headers, URL encoding, cache caps | Several fixes are already in the checked-out 0.5.0-labelled submodule's Unreleased work. | Verify compatibility during the bump. Do not count them as new app simplifications or create parallel implementations. |
| 0.6.1 documentation alignment | No additional core implementation change relative to 0.6.0. | Adopt the latest audited patch; no separate app feature phase. |

## Target ownership and contracts

### Source rendering

Replace `HadithSharhText(String)` with a small renderer accepting the SDK explanation/document rather than reparsing `sharhText`. Keep it inside Hadith presentation; shared core must not gain a dependency on a feature. Reuse existing theme text roles only where their meaning remains accurate.

The renderer must preserve paragraph/list/separator boundaries and exact source wording. Build spans from `documentRenderTokens`; ranges index canonical `sourceText` in UTF-16. Do not run `ArabicTextNormalizer`, whitespace collapse, artifact stripping, or inserted punctuation over the canonical document before resolving ranges. Any numeral isolation is a view transformation after segmentation, never a mutation of stored source or range coordinates.

Links, glossary definitions, Quran citations, and neutral quotation annotations can retain useful localized affordances. A tafsir link does not authorize inventing a Quran quote or interpreting a speaker. Validate link navigation through established external-link behavior. Keep selection/copy across the rendered content usable. Do not globally delete `commentary_inline_spans.dart`, `commentary_text_styles.dart`, `ArabicTextNormalizer`, or Quran/Fortress prose logic: those have independent consumers.

SDK structure does not classify every old heuristic, such as `أي:`, `وقيل:`, bracket notes, or scholar lead-ins. Accept faithful neutral prose for unannotated passages. Do not preserve the old semantic parser as a second fallback pipeline merely to retain its colors. Confirmed speaker attribution requires reviewed source URI, content hash, evidence, reviewer, and validated ranges; this migration supplies none automatically.

For historical records with no document, show their supplied plain text and available explicit metadata. Do not manufacture a sourced document from old flat text, guess label boundaries, or silently refresh saved religious wording. A current-detail fetch is a separate user-visible request. The lightweight plain display fallback is the only legacy rendering path.

Keep the main Hadith display/copy string from the SDK's display field. `DetailedHadith.content.sourceText` intentionally retains raw display prefixes, so substituting it blindly would reintroduce numbered prefixes. If annotated main matn rendering is used, explicitly account for the distinction between canonical ranges and cleaned display text.

### Detail loading and sharing

Replace the `Future<Object?> hadithDetail` family with typed families matching the SDK methods:

- Sharh by `SharhId`: `Future<Sharh>`. `getSharhById` returns the document directly; retain `Sharh.provenance` without manufacturing an `ApiResponse` or search metadata.
- Usul by `HadithRecordId`: `Future<ApiResponse<UsulHadith>>`.
- Alternate/similar by `HadithRecordId` and `RelatedHadithKind`: `Future<ApiResponse<RelatedHadithResult>>`.

Keep the wrappers supplied by Usul and related methods so their diagnostics/provenance survive. Avoid a new bespoke hierarchy that simply wraps SDK models.

Update both detail-pane layouts, the share dialog, mocks, and visual harness overrides together. Keep lazy accordion watches: closed sections do not fetch. Selected record, explanation-page header record, and body citation can differ; render and label each independently. Carry an originating `ExplanationReference` alongside a fetch rather than guessing it from the returned header.

A raw Sharh fetch may be shared by explanation ID. Its originating record, relationship, and raw link label belong to the current selection, not the reusable fetched document. Test two records linking to the same Sharh ID with different relationship labels, including switching selection while the shared request is pending. Detail labels and share exports must always use the current record's origin context.

Related collections should render inside the existing detail sections and enter the existing specific-list flow when opened. Every alternate must be reachable. Returning to search restores query/filters; a new detail request cannot publish into a later selection. Empty collections are explicit empty states, distinct from parser/network errors.

Share cards consume commentary blocks for the explanation section instead of the full `sharhText` body, which can repeat matn and citation. Preserve enough explicit source context for the explanation, especially when the header/body differs from the selected narration. Structured chain/narration fields should refine current usul options without silently changing what they mean.

Use one source-ruling projection across detail, badges, text copy, and image sharing. Test `grade` and `explainGrade` independently with `hasHadithMetadata`; the SDK's `hukm` getter checks only whether expanded wording is nonblank. If expanded wording is a placeholder, use the meaningful supplied `grade`. If both supplied fields are meaningful and different, retain both with their appropriate localized source labels. Do not hide the field that caused a warning behind the other field or combine them into an inferred authenticity classification. Preserve each supplied string exactly.

Text copy includes all meaningful source rulings. Image options may omit neutral rulings under the existing policy, but when either field triggers a weak/fabricated/chain warning, the complete ruling projection is mandatory at both the options and render boundaries. With `grade: 'ضعيف'` and `explainGrade: '-'`, the image must include `ضعيف`; with two distinct meaningful rulings, neither may disappear behind `hukm` precedence. Update `hadithShareText`, share constraints, the card, and judgment tests together.

Keep missing-field suppression, full plain-text copy, share-dialog optional-fetch error/retry handling, capture state, and export/drag behavior. A selected optional section that fails to load must still block incomplete export until retried or deselected. The SDK does not replace `HadithShareOptions`, `HadithShareActions`, or the shared PNG export layer.

### Search and reference choices

Keep record search on `SearchCapabilities.detailed`: 30 items per page, ordinary site search limited to 10 pages. Quick search remains a separate lightweight surface with 15-item page hints and restricted types/filters; it is not a safe optimization for Tawaq's detailed record flow.

Remove `SearchZone.sharh` from requests to record search. Make the search target explicit: Hadith records or explanation prose. Record type `withExplanation` means records with an explanation, not search inside explanation prose. Prefer a small discriminated search-page model for the two actual result types over converting snippets into fake `DetailedHadith` objects. Carry the target in return snapshots. Retain independent selection semantics: a prose snippet opens a Sharh document, while only a real Hadith record supports current bookmarking/sharing policies.

The prose target supports its own query/page contract. Do not send record-only degree/scholar/book/narrator/specialist filters to it. Retain the record filter selections when switching targets and disable/hide them with a clear localized explanation while prose search is active. Pagination cannot assume a known total: use previous/next navigation when only next-page evidence exists, numeric Forui pagination when the SDK provides a reachable page count. A full prose/quick page is a hint, not proof of a total.

Switching targets cancels pending debounce work, advances the request generation, resets paging to page 1, and clears incompatible selection and detail context while retaining the query and record filters. An old search, page, or detail response cannot publish into the new target. Keyboard next/previous navigation must select the visible result type. Opening bookmarks or a related list from prose search and returning must restore the prose target rather than reinterpret its query as a record search.

Keep recents as query-only shortcuts for this adoption. Replaying a recent query uses the currently selected target and its applicable filters; make this behavior clear in both locales. Preserve the existing query-based deduplication and removal semantics. Do not add a target field or change Hive field IDs. Restoring complete searches, including their original target and filters, remains a separate saved-search feature.

For record search, use a `Set<HadithTypeFilter>` and typed dynamic ID arrays. Keep the UI filter model for active chips, reset, session snapshots, and localization; deleting that model would move product state into request construction. Remove the old zone field/localization extension cases and three `to*Reference` conversions only after all callers move. Do not combine a typed ID array with its matching legacy array.

Use SDK `ReferenceChoice` directly for selected id/name values. Offline reference items implement `ReferenceItem`; `ReferenceChoice` does not, so map the offline results once at the repository boundary. Return plain lookup lists instead of a fabricated `ApiResponse` for offline books. Keep debounce, minimum query length, stale-response protection, retry controls, stable selection, and kind-specific request conversion. Replace synthetic nonnumeric reference IDs in tests with valid IDs where validation is exercised.

Keep local lookup available without network. Correct repository comments claiming it is remote. Current-selection browsing excludes historical scholars, but old IDs/names remain resolvable. Existing selected choices should survive a refreshed menu that omits them. Narrator choices are partially covered filter choices, not canonical person IDs.

### Pagination, errors, and state

Derive reachable page counts from `metadata.pagination` and SDK endpoint capabilities. Displayed site totals may exceed reachable results; do not offer page 11 for ordinary record search or claim a truncated set is complete. Unknown totals remain unknown rather than becoming an empty-result signal. Keep result counts labelled according to what they actually count.

Keep the session controller's generation guard, debounce, one async outcome owner, last-good-page retention, serialized recents writes, selected-key derivation, and return snapshot. These solve app behavior the SDK does not coordinate. Remove only pagination metadata repair made unnecessary by the upstream limit contract. A genuinely empty returned page still must not silently rewrite upstream metadata or erase the last good page as if a request succeeded normally.

When a full prose page supplies only a next-page hint and the following request succeeds with empty results, keep the visible page and record the empty probe as navigation evidence for that query/target/request parameters. Disable further Next navigation from that page and show a localized end-of-results message. Keep this evidence separate from the retained response metadata; do not invent `totalPages` or change its upstream totals. A failed request remains retryable and must not establish an end boundary. Clear the empty-probe boundary on a new search, query, target, or applicable-filter change so a refreshed search can discover new results.

Use strict parsing by default. Existing recovery surfaces must distinguish initial/new-query failure, pagination failure, detail failure, initialization failure, and valid empty data. Trace any exhaustive Dorar exception mapping for the new `DorarSubrequestException`; preserve its cause for diagnostics. No automatic retry using best-effort. If an explicit best-effort surface is added later, show partial-result warnings and handle nullable related `source` without assigning ambiguous narrations to the requested seed.

### Persistence and initialization

Do not rewrite saved strings or erase favorites, recents, layout settings, old references, or `cache.db`. Filters/query are session-only; there is no persisted filter-schema migration to invent. Keep historical `HadithFavorite`, bare `DetailedHadith` JSON, and envelope decoding paths.

Replace automatic deletion on decode failure in `HadithLocalDatabase._readFavoriteEntries`. An unsupported document schema, invalid hash/range, or other unreadable enrichment must not delete the bookmark. Retain the original stored value under its existing key. When the saved scalar record fields remain valid, recover those exact fields for plain display and report that rich content is unavailable; never use an invalid document's spans or manufacture a replacement document. This recovery is a read projection, not a write-back migration. If the scalar record cannot be recovered, retain the entry and surface an unreadable-bookmark state with explicit removal rather than silently losing it. Loading, pruning, and saving another favorite must not delete unreadable entries as a side effect.

Update the existing corrupt-entry test, which currently expects deletion. Cover malformed JSON alongside invalid hash, unsupported schema, and invalid ranges. Prove original stored values and keys survive repeated load/restart and that valid neighboring favorites remain usable. Keep SDK validation strict; the app owns recovery and retention, not weaker document validation.

Typed IDs do not provide a replacement bookmark key. `hadithStableKey` prefers the Dorar ID but otherwise hashes display text. `HadithLocalDatabase` already reads the real persisted key internally, then discards it when publishing records; the favorite provider reconstructs keys. Preserve stored keys through the read/repository/provider contract for legacy ID-less favorites, so display changes cannot orphan deletion or duplicate entries. Use a small saved-entry value carrying the existing key, timestamp, and record if needed. Do not rekey old entries destructively. If adopting a deterministic digest for new ID-less records, keep legacy key recognition and test save/remove/restart against both formats. Session selection identity and durable storage identity need not be conflated.

Keep lazy `DorarHadithFlutter.ensureInitialized()` and targeted invalidation of failed init/client/repository owners. Default adapter setup installs the schema-2 snapshot itself; Tawaq has no custom narrator factory requiring `migrateReferenceDatabase`. Add no app-level copy/migration routine. Custom migration is needed only if a real custom database/factory is introduced, and must write a new verified output rather than modify the input.

The audited reference manifest is snapshot `2026-10-06.1`, schema 2: 774 books, 211 scholars including retained history, and 11,479 narrator entries with **partial** coverage. Narrator asset SHA-256 is `1640cf7d0e282e2709e2ef69c39737ee5ac26f357fead5341fbdcf6841faeb69`. Record this package-managed content separately in source/release evidence. `docs/content-assets.json` currently inventories the 14 Quran commentary/translation databases; do not mislabel those as Dorar assets or change their unresolved permissions through this upgrade.

## Removal ledger

Delete after the new renderer and consumers pass their replacement regressions:

| File / symbol | Replacement |
| --- | --- |
| `domain/services/hadith_sharh_zone_splitter.dart` (67 lines) | SDK structural blocks and independently scoped citations |
| `domain/services/hadith_sharh_metadata_parser.dart` (87) | Explicit SDK header/body metadata |
| `domain/services/hadith_sharh_normalizer.dart` (31) | Source-faithful text from SDK; presentation-only numeral handling |
| `domain/services/hadith_sharh_segment_tokenizer.dart` (363), `parseHadithSharh` | `documentRenderTokens` and annotations |
| `domain/models/hadith_sharh_models.dart` (193) | SDK content/metadata models |
| `lib/core/text/dorar_text_cleaner.dart` (70) | No remaining consumer after Hadith parser deletion |
| `HadithLookupRef` and `HadithLookupRefX` | SDK `ReferenceChoice` plus typed request IDs |
| `HadithDetailKind` / heterogeneous `hadithDetail` implementation | Typed explanation/usul/related providers |
| Offline book lookup's fabricated response metadata | Repository lookup list contract |
| Legacy alternate/similar SDK calls in app | Complete/seed-separated SDK methods |
| Obsolete record-search zone mapping and out-of-range metadata repair | Explicit target/type filters and SDK pagination |

Further deletions, conditional on proving every call site:

- Narrow favorites repository/provider methods to `DetailedHadith`. Production cards already supply that type. If there is no genuine lightweight `Hadith` consumer, remove `resolveDetails` and the generic bookmarking branch instead of retaining a second text-query resolution path. Do not fabricate a detailed record from a quick result. Keep `HadithBase` uses that still correctly serve shared judgment/display code.
- Remove `tool/fixtures/dorar-test-storage.patch` and its apply logic from `tool/checks.sh` only if the new upstream checkout isolates these tests equivalently. Otherwise adapt the patch and its README to the reviewed revision without overwriting unrelated package changes.
- Remove obsolete generated lookup/provider members through regeneration, never manual edits to generated Dart.

Consolidate `tool/fetch_sharh_corpus.dart`, `tool/export_sharh_cache_fixtures.dart`, and `tool/audit_sharh_cache.dart`. They inspect cache rows/keys or old parsed JSON and are incompatible with the raw-response format. Prefer one fixture capture/validation tool using public SDK fetches and serialized documents, with explicit source URI/time/hash. It must own its temporary cache and dispose clients; do not infer record IDs from internal cache keys. Captured raw HTML may be retained as immutable evidence when available; old flattened fixtures cannot recover lost DOM annotations.

Replace the four parser-specific test suites with SDK-adoption tests for Tawaq's rendering/interaction contracts. Rewrite `hadith_sharh_text_test.dart` and `hadith_sharh_metadata_card_test.dart`; retain useful source-preservation and historical text samples, but remove assertions tied to synthetic punctuation, guessed speaker classes, and old zone models. SDK parser behavior itself belongs in package tests.

Keep the shared commentary utilities, Quran/Fortress display logic, local database/recent-search owners, app bootstrap gate, source-wording warning rules, missing-field guard, share options/export, Forui search input mechanics, and current card/sidebar design. They have no equivalent replacement in the SDK. Correct the destructive decode cleanup and ruling projection within those existing owners as specified above.

## Implementation sequence

### 1. Establish the dependency and compatibility baseline

1. Preserve the existing dirty tree and submodule fixture edits. Capture current dependency revision and migration-relevant saved JSON/key fixtures before upgrading.
2. Pin a reviewed upstream revision matching the published 0.6.1 core/adapter. Verify adapter/core resolution, transitive assets, committed generated outputs, and updated root lockfile.
3. Reconcile the package test fixture patch and `tool/checks.sh`. Check newer upstream tests rather than assuming the old patch still applies. Confirm the FVM SDK remains sufficient.
4. Update only broken constructors/mocks necessary to establish compilation: `Sharh.hadith` now takes `DetailedHadith`; update detail/share tests and `tool/launch_visual_harness.dart`. Use valid typed-ID fixtures.

Exit: both SDK packages analyze/test with isolated storage; old saved JSON decodes without erasure. Dependency changes are concrete and reviewable.

### 2. Replace request/detail contracts and fix data loss

1. Adopt typed IDs, replace duplicate lookup values/conversions, and remove offline fake metadata. Keep lookup recovery and selection semantics.
2. Introduce typed detail providers with the SDK's actual Sharh/Usul/related return shapes; migrate detail, share, tests, and harness overrides together. Verify reused Sharh fetches retain selection-specific origin labels.
3. Switch alternate/similar calls to complete collections, preserving order and seed context. Keep specific-list return behavior and lazy loading.
4. Adopt SDK pagination/capability projections and strict errors. Remove manufactured limit repair while keeping soft pagination failures.
5. Preserve actual favorite storage keys and historical decoding. Replace automatic deletion on decode failure with retained originals, safe scalar recovery, and visible unreadable-entry handling. Narrow generic bookmarking and remove unused resolution logic once the fan-out is verified.

Exit: complete related collections, no `Object?` detail casts or fabricated Sharh metadata, no silent parse-to-empty path, compatible bookmarks after restart, retained unreadable entries, and no new architecture violations.

### 3. Replace the sharh pipeline and share integration

1. Implement the feature-local document renderer, scoped header/body citation display, annotations, and plain legacy fallback.
2. Integrate it into wide/compact detail views and typed share options. Use commentary blocks for explanation export and retain source context.
3. Fix placeholder and distinct-field ruling projection across display, full text copy, share options, and card rendering. Preserve mandatory source warnings, missing-field behavior, and optional-detail fetch recovery.
4. Migrate source/range/scoping tests, then delete all six parsing/model/cleaning files and their obsolete tests. Do not leave a parallel hidden parser.

Exit: source boundaries and wording survive; attribution is evidence-based; renderer/share consumers agree; the 811-line duplicate layer is gone.

### 4. Finish search targets and supporting tools

1. Separate record-type filters from explanation prose search. Add the minimal distinct snippet page/selection flow and correct AJAX paging, with localized target and unsupported-filter communication. Complete target-switch cancellation/selection/return behavior, query-only recent replay, and empty hinted-page termination.
2. Regenerate provider/Freezed/JSON outputs and ARB localization outputs from inputs.
3. Consolidate fixture tooling, remove direct cache-layout readers, and add package manifest/source evidence to release documentation without touching unrelated content permissions.
4. Search the entire repository for obsolete symbols and reconcile harnesses, scripts, and fixture references.

Exit: no `SearchZone.sharh` reaches record search; snippets are never fake Hadiths; tooling works with format 3; removed implementations have no live consumers.

### 5. Verify behavior and UI, then inspect the final diff

Run the targeted cases below during the relevant phase. Once stable, run the complete app and changed-package checks, generation checks, and native flow review. Report failures or unavailable platform coverage accurately. Do not claim upstream CI configuration proves native release behavior.

Apply `$impeccable` when implementing the affected UI. Preserve the established Operate/Read visual identity and the user's flat cards, action footer, RTL sidebar, and spacing choices. Read resolved Forui source plus matching maintainer documentation for tabs, accordions, multi-select, popovers, and pagination before changing their behavior. Use the existing Tawaq delivery workflow for native evidence.

Inspect the affected Hadith screen, each reachable detail section, prose-search state, lookup popup, and share dialog/card in one batched native review across Arabic/English, light/dark, wide/compact, and large text. Fix the observed defects together, then use at most one confirmation round. Check clipping/dividers, padding around resize thumbs, selected/hover/focus distinction, immediate tab feedback, card action placement, long judgments, glossary/link affordances, and keyboard/selection/copy behavior. Do not reintroduce the earlier glow, thick one-sided border, duplicate ordinal/source labels, or empty half-screen behavior.

Exit: code, generated outputs, tests, fixtures, and native evidence agree. Inspect the final app/submodule diff and document changes, deletions, retained owners, generation, checks, and limitations.

## Required verification

| Contract | Meaningful regression coverage |
| --- | --- |
| Source-faithful renderer | Exact source substrings and UTF-16 ranges; Arabic marks/internal dashes; paragraph/list boundaries; neutral quotation; glossary/Quran/link annotations; no invented punctuation or attribution |
| Citation scope | Selected record, explanation header, and embedded citation with intentionally different metadata; two origins sharing one Sharh ID with different relationship labels; pending selection switch; no field/context leakage in detail or export |
| Detail provider shapes | Sharh returned directly with its provenance; Usul/related retain SDK response wrappers and diagnostics; no fabricated Sharh search metadata |
| Historical content | Six-field Sharh JSON, old DetailedHadith JSON, legacy favorite/envelope/Hive shapes, plain document-free fallback, unchanged saved wording |
| Related collections | Several ordered alternates, seed-separated similar list, empty result, failure/retry, nullable best-effort context without invented identity, specific-list open/back restoration |
| Search | Typed dynamic IDs and repeated scopes; record-with-explanation vs prose target; invalid quick inputs rejected; prose snippets not bookmarkable records; switches during debounce/search/pagination/detail reject stale work and reset page/selection while retaining filters; keyboard navigation and prose return snapshot |
| Recent queries | Historical entries remain readable; replay uses current target; query-based deduplication/removal unchanged; localized behavior; no Hive field-ID changes |
| Pagination | Site page 10 limit; no ordinary page 11; unknown totals; next-page hints; truncated totals; stale responses; prior page survives failed next request; full prose page followed by empty success retains results and disables repeated Next without rewriting metadata; errors remain retryable and a new search clears the empty boundary |
| Lookups | Offline success without network; Arabic marks/hamza/wasla/bidi symmetric search/count; literal `%`/`_`; stale query protection; historical selected values and partial coverage |
| Sharing | Negative grade with placeholder expanded ruling; reverse field arrangement; both meaningful and distinct source rulings; exact wording across detail/copy/image; mandatory warning fields at options/render boundaries; empty rawi omitted; scoped commentary without repeated matn; selected optional section failure blocks export and retry/deselect recovers |
| Storage | Actual stored keys survive load/remove/restart; ID-less favorite does not duplicate; no destructive rekeying; malformed JSON and invalid document hash/schema/ranges retain original values; valid scalars recover without write-back; unreadable entry is surfaced; repeated reads/pruning/new saves preserve unreadable entries and usable neighbors |
| Initialization/cache | Adapter retry/concurrency/configuration failures, manifest integrity/schema/count, old reference/cache files retained, old cache namespace ignored, no render/policy collisions |
| Native integration | Packaged transitive assets, read-only narrator lookup and writable app cache from unrelated cwd, lazy route initialization, wide/compact RTL/LTR usability |

Commands run through FVM:

```bash
fvm flutter test test/feature/hadith
fvm dart run build_runner build
fvm flutter gen-l10n
fvm flutter analyze --no-fatal-infos
fvm flutter test
```

Run code generation only for changed inputs; include resulting tracked outputs. Dorar commits its own generated outputs and `tool/codegen.sh` deliberately skips it. For fresh-clone/root-wide verification use `fvm exec bash tool/codegen.sh`. Analyze and test core and adapter from their own directories; the root analyzer excludes packages. The reconciled `fvm exec bash tool/checks.sh packages` supplies broader package verification. Build and run the normal Linux app as well as any evidence harness.

Keep Windows x64 and macOS arm64/x64 native release checks explicitly pending if machines remain unavailable. Browser compilation/CORS support in the SDK does not create a new Tawaq browser deployment requirement.

## Optional capabilities after the adoption pass

These are mapped opportunities, with no old Tawaq implementation to delete. They should not delay completing the core migration.

- **Online book and narrator discovery:** use `getBooksForScholars` for books associated with scholars' assessments, not authored books; key requests by selected scholar IDs and keep offline browsing reachable. Use `searchNarratorChoices` as partial online autocomplete with clear network/retry state. Never silently intersect away an existing selected book or identify a choice as a canonical person.
- **Thematic browsing:** use SDK roots/categories and `CategorySelector`/`CategoryId`, preserving opaque values and significant selector spaces. Category paging has its own contract; the ordinary 10-page search cap cannot be reused globally.
- **Asbab details:** use `getAsbab` and typed source/narration documents with relationship/raw labels; only add an accordion when this product feature is chosen. Do not derive historical claims from an unrelated narration.
- **Sorting/optional phrases:** SDK capabilities now support these on detailed search. Add only with a clear user task and localized controls; there is no existing custom implementation to remove.
- **Bibliography / reviewed attribution / HTML consumers:** the SDK supplies richer contracts, but Tawaq currently has no matching feature. Keep raw dates/locators and neutral attributions; do not invent screens, religious claims, or web rendering just because the API permits them.

## Completion checklist

- [ ] Core and adapter 0.6.1 pinned together, root lock updated, package fixture patch reconciled.
- [ ] Typed request/detail contracts adopted; every affected caller/mock/harness updated.
- [ ] Sharh stays a direct SDK result; Usul/related response metadata retained; shared fetches cannot leak origin context.
- [ ] All alternates reachable; similar context separated; source relationships retained.
- [ ] SDK document rendering and commentary sharing replace the entire old parsing pipeline.
- [ ] Six obsolete files deleted; lookup duplication, fake response wrapper, unused resolution branches, cache readers, and generated remnants removed as applicable.
- [ ] Explicit record/prose search targets and valid pagination; no silent endpoint switch or inferred totals.
- [ ] Target transitions reject stale work, query-only recents replay the active target, and empty hinted pages stop repeated Next requests.
- [ ] Source ruling placeholders and distinct fields handled consistently; mandatory warnings survive text copy and image export.
- [ ] Missing fields, app recovery, lazy loading, and durable bookmarks preserved.
- [ ] Historical decoding and stored-key compatibility proven; no database/cache/favorite wipe.
- [ ] Failed bookmark decoding retains the original entry; safe scalar recovery and unreadable-entry handling replace automatic deletion.
- [ ] Repository-wide obsolete-symbol search clean except named historical fixtures/documentation.
- [ ] Generation, package checks, full app analysis/tests, normal Linux runtime, and bounded Impeccable review complete with evidence.
- [ ] Final diff reviewed and remaining platform limitations stated; optional new features remain separately scoped.
