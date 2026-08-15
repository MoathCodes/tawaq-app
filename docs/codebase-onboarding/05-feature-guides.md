# Feature guides

## Prayer

Start at [`PrayerScreen`](../../lib/feature/prayer/presentation/screens/prayer_screen.dart) and [`prayer_day.dart`](../../lib/feature/prayer/presentation/provider/prayer_day.dart).

Effective prayer settings and the shared clock feed `computePrayerDayBundle`, then `prayerDayProvider`, then derived providers for schedules, cards, countdowns, and current slots. Prayer completion data is user-owned Hive data. Slot decisions live in domain code (`prayer_slots.dart`), not widgets; historical dates use `prayerDayBundleForDateProvider`.

## Quran

Start at [`QuranScreen`](../../lib/feature/quran/presentation/screens/quran_screen.dart). The route's `page` is the live active page; persisted `lastPageNumber` is only a restore checkpoint. Study mode uses the shared responsive split convention and session-only selected ayah state.

Tafsir flows from asset-database source/repository through `tafsirForAyahProvider`, a parser, and bounded cached sections. Recitation combines pure domain policies/transitions with `recitation_provider.dart` orchestration. Quran's `mushafZoom` is independent of global UI text scale.

## Hadith

Start at [`HadithPage`](../../lib/feature/hadith/presentation/screens/hadith_screen.dart). The Dorar client initializes lazily when the feature opens. A session controller owns query, filters, results, and selection; a repository coordinates remote work with Hive favourites and recents. Wide layouts split search and reading; narrow layouts merge them into one column. Sharh parsing belongs to domain services.

## Muslim Fortress

Start at [`MuslimFortressScreen`](../../lib/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart). Its repository version-copies package databases, opens `HisnClient`, maps records, and caches chapters, duas, and commentary. It owns browsing, search, bookmarks, commentary, and focus reading. Prayer-aware recommendations read `prayerDayProvider`, then fall back to the shared app clock while data is unavailable.

## Settings, onboarding, and about

Settings is mainly a UI composition of concrete persisted providers. Its live selected tab is URL-owned, while its persisted value is a restore checkpoint. Onboarding deliberately has feature-owned state/widgets plus an app-composed standalone screen. About activates as a shell dialog, while `/about` remains a direct-navigation fallback.
