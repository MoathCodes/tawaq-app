# Dorar Hadith 0.6.1 adoption

The core and Flutter adapter resolve to the vendored checkout at `ed470db6c62a38a701ecb4100a7fa39a6cb2fb13`. The root override ensures the adapter uses the app's path-based core. Both packages' public `lib/` and bundled `assets/` files match their published 0.6.1 archives byte for byte.

| Package | Published archive SHA-256 |
| --- | --- |
| dorar_hadith 0.6.1 | ecd54bd0aa048886fcb204149eb99fa8f2301769fbd1ddc7177302c4ee3601c7 |
| dorar_hadith_flutter 0.6.1 | 2b2e8221187273066f1ce58c383357e87305f7b2aaf2501c9271fe10d0f677a6 |

The adapter manages installation of reference snapshot `2026-10-06.1`, schema 2, normalization version 1. It contains 774 books, 211 scholars including retained historical choices, and 11,479 narrator filter choices with **partial coverage**. Narrator choices are not canonical person identifiers. The narrator asset SHA-256 is `1640cf7d0e282e2709e2ef69c39737ee5ac26f357fead5341fbdcf6841faeb69`. Capture sources, timestamps, coverage and collection hashes are preserved in `packages/dorar_hadith/assets/data/reference_manifest.json`. These are package-managed Dorar references; the Quran asset inventory in `docs/content-assets.json` remains separate.

The upstream client tests now isolate their caches. The remaining client-use test still needs Tawaq's in-memory reference-storage fixture; `tool/fixtures/dorar-test-storage.patch` applies only that isolation change.

The app uses SDK documents, scoped explanation citations, typed detail endpoints, complete related collections, reference choices and endpoint limits. The old sharh parser and cache-inspection tools were removed. `tool/capture_sharh_fixtures.dart` captures public SDK documents with provenance using its own disposable cache.

Bookmark recovery retains original values and keys. Invalid rich content is displayed through exact scalar fields when possible; unreadable entries require explicit removal. This is a read projection, with no write-back migration. Record and prose search remain separate targets; recents remain query-only. Original and expanded rulings are projected independently across detail, warnings and sharing.

Validation: FVM generation and localization completed. All 1,229 app tests pass; the Hadith suite includes a further settings-hydration lifecycle regression. App analysis reports no errors or warnings, with informational lints remaining. The package check suite passes; the final core analysis and isolated client-use tests also pass. The Linux release build launches from `/tmp` with isolated data.

The native confirmation batch covers Arabic/English, light/dark, wide/compact and normal/large text, with 216 captures and zero Flutter errors. It exercises mounted Flutter callbacks, scoped documents, prose selection, reference lookup, Usul/related sections and image-sharing recovery. The installed narrator database retains the published hash and the app cache is separate. OS pointer/keyboard delivery could not be verified because the desktop driver's production Hyprland input plugin is unavailable.

Flutter driver verification also ran against a normally launched Linux debug app on the user desktop session. Live record search returned 30 results; prose search returned 15 results. Record selection and explanation loading worked. Prose selection opened its document in the compact dialog at 800×700 and restored the detail pane at 1200×800. The replay reported no runtime errors after a restart applying the settings lifetime change. Driver text entry was emulated; native keyboard delivery remains unverified. Runtime inspection found and fixed settings hydration being disposed during layout transitions. Commentary-only images now omit repeated header/citation matn while retaining each source’s metadata and rulings.
