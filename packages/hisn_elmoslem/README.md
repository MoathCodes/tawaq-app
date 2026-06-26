# Hisn Elmoslem

Pure Dart library for **Hisn al-Muslim** (Fortress of the Muslim) — offline access to adhkar, duas, takhreej, commentary, Quranic passages, and search.

Extracted from the open-source [HisnElmoslem_App](https://github.com/muslimpack/HisnElmoslem_App) by Muslim Pack. The Flutter UI was stripped out; this package exposes only the structured data and business logic as a modern Dart API.

Works in **any Dart program** (CLI, server, tests) and in **Flutter apps** with a small asset-copy step.

## Features

- **135 titles** and **335 dhikr items** from the bundled SQLite database
- **Structured content** with sealed classes (`HisnPlainLine`, `HisnQuranLine`) for switch-based rendering
- **Quranic passages** parsed from `QuranText[(surah:ayah:ayah)]` markers into typed `HisnVerseRange` objects
- **Takhreej / source** (`source`), **virtue** (`fadl`), and **authenticity** (`hokm`) on every item
- **Commentary** (sharh, related hadith, benefit) from a separate database (~311 entries)
- **Fake hadith warnings** — known weak or fabricated narrations (~20 entries)
- **Remote audio URLs** from the `audio_url` column (no bundled MP3s)
- **Full-text search** over titles and contents with three matching modes
- **Source and authenticity filters** ported from the original app
- **Uthmani plain-text resolution** for Quranic placeholders via bundled Quran database
- **Upstream sync tooling** to keep databases aligned with the original repo

## Data attribution

Content is sourced from [muslimpack/HisnElmoslem_App](https://github.com/muslimpack/HisnElmoslem_App). Database files are synced from:

```
packages/HisnElmoslem_App/hisnelmoslem/assets/db/
```

into this package's `assets/database/`. See [Keeping data up to date](#keeping-data-up-to-date).

Current bundled snapshot (see `assets/upstream.lock.json`):

| Database | Tables | Rows |
|---|---|---|
| `hisn_elmoslem.db` | `titles`, `contents` | 135, 335 |
| `commentary.db` | `commentary` | 311 |
| `fake_hadith.db` | `fakeHadith` | 20 |
| `quran.ar.uthmani.v2.db` | `arabic_text` | 6236 |

## Installation

### Dart / CLI

```yaml
dependencies:
  hisn_elmoslem:
    path: ../hisn_elmoslem   # or git/pub reference
```

```bash
dart pub get
```

### Flutter

Add the dependency and ensure Flutter can bundle the SQLite assets (included automatically when depending on this package):

```yaml
dependencies:
  hisn_elmoslem:
    path: packages/hisn_elmoslem
```

Because Flutter assets are not direct filesystem paths, copy the databases to a writable directory before opening the client. See [Flutter integration](#flutter-integration).

## Quick start

```dart
import 'package:hisn_elmoslem/hisn_elmoslem.dart';

Future<void> main() async {
  await HisnClient.use((client) async {
    // List all titles (chapters)
    final titles = client.titles.all();
    print('${titles.length} titles');

    // Morning adhkar
    final morning = client.titles
        .byNameFragments([HisnFeaturedTitles.morning])
        .firstOrNull;

    if (morning != null) {
      final items = client.contents.byTitleId(morning.id);
      for (final item in items) {
        print('Repeat: ${item.repeatCount}×');
        if (item.hasSource) print('Source: ${item.source}');
        if (item.hasVirtue) print('Virtue: ${item.virtue}');

        for (final line in item.lines) {
          switch (line) {
            case HisnPlainLine(:final text):
              print(text);
            case HisnQuranLine(:final presentation):
              print('Quran presentation: $presentation');
          }
        }
      }
    }
  });
}
```

`HisnClient.use()` opens the client, runs your callback, and always calls `close()` in a `finally` block — even when the callback throws. For long-lived access (for example, in a Flutter provider), use `HisnClient.open()` and call `close()` when done.

## Architecture

```
HisnClient
├── titles      → TitleService
├── contents    → ContentService
├── commentary  → CommentaryService
├── fakeHadith  → FakeHadithService
├── search      → SearchService
└── uthmani     → UthmaniTextResolver
         ↓
    HisnDatabase (sqlite3, read-only)
    ├── hisn_elmoslem.db
    ├── commentary.db
    ├── fake_hadith.db
    └── quran.ar.uthmani.v2.db
```

All domain models are immutable. Content lines use **sealed classes** so consumers can use exhaustive `switch` expressions (Dart 3).

## Opening the client

| Method | Use case |
|---|---|
| `HisnClient.open()` | Dart CLI, tests, desktop — resolves bundled package assets via `Isolate.resolvePackageUri` or filesystem fallbacks |
| `HisnClient.openFromDirectory(path)` | Flutter apps — open after copying `.db` files from `rootBundle` to app documents |
| `HisnDatabase.openFromPaths(...)` | Advanced — explicit path per database file |

Always call `client.close()` when done to release SQLite handles.

## API reference

### `HisnClient`

Main entry point. Exposes service objects and helper methods.

```dart
final client = await HisnClient.open();

// Load content with commentary attached
final full = client.contentWithCommentary(15);

// Filter a list of contents
final filtered = client.filterContents(
  items,
  HisnFilterCriteria(
    filterByAuthenticity: true,
    activeAuthenticities: {HisnAuthenticity.sahih},
  ),
);

client.close();
```

### Titles — `client.titles`

| Method | Returns | Description |
|---|---|---|
| `all({HisnRecurrence? recurrence})` | `List<HisnTitle>` | All titles ordered by `order` |
| `byId(int id)` | `HisnTitle?` | Single title |
| `byNameFragments(Iterable<String>)` | `List<HisnTitle>` | Titles whose name contains any fragment |

**`HisnTitle` fields:** `id`, `name`, `order`, `recurrence`, `searchText`, `audioFileName`

**`HisnRecurrence`** (from DB column `freq`):

| DB code | Enum |
|---|---|
| `d` | `HisnRecurrence.daily` |
| `w` | `HisnRecurrence.weekly` |
| `m` | `HisnRecurrence.monthly` |
| `y` | `HisnRecurrence.yearly` |

**Featured title fragments** — `HisnFeaturedTitles`:

```dart
HisnFeaturedTitles.morning   // أَذْكَارُ الصَّبَاحِ
HisnFeaturedTitles.evening   // أَذْكَارُ الْمَسَاءِ
HisnFeaturedTitles.sleep     // أَذْكَارُ النَّوْمِ
HisnFeaturedTitles.waking    // أَذْكَارُ الاسْتِيقَاظِ
HisnFeaturedTitles.fragments // all four, in order
```

Prefer matching by name fragment rather than hard-coded IDs so upstream DB changes do not break callers.

### Contents — `client.contents`

| Method | Returns | Description |
|---|---|---|
| `all()` | `List<HisnContent>` | All dhikr items |
| `byTitleId(int titleId)` | `List<HisnContent>` | Items for one title, ordered |
| `byId(int id)` | `HisnContent?` | Single item |
| `countByTitleId()` | `Map<int, int>` | Item count per title |

**`HisnContent` fields:**

| Field | DB column | Description |
|---|---|---|
| `id` | `id` | Primary key |
| `titleId` | `titleId` | Parent title |
| `order` | `order` | Order within title |
| `repeatCount` | `count` | Recommended repetitions |
| `lines` | `content` (parsed) | Structured content lines |
| `rawContent` | `content` | Raw DB string |
| `virtue` | `fadl` | Virtue / reward text |
| `source` | `source` | Takhreej / reference |
| `hokm` | `hokm` | Authenticity ruling (Arabic) |
| `searchText` | `search` | Normalized search text |
| `audio` | `audio_url` | Remote `HisnAudio` (URI) |
| `commentary` | — | Set when loaded via `contentWithCommentary` |
| `authenticity` | — | Parsed `HisnAuthenticity?` getter |

**Extension getters** (`HisnContentX`):

```dart
item.hasVirtue
item.hasSource
item.hasHokm
item.hasAudio
item.isQuranic
item.hasCommentary
item.quranRanges   // Iterable<HisnVerseRange>
item.plainText     // non-Quranic lines joined
```

### Sealed content lines

Raw `content` strings are parsed into a list of sealed line types:

```dart
sealed class HisnContentLine { ... }

final class HisnPlainLine extends HisnContentLine {
  final String text;
}

final class HisnQuranLine extends HisnContentLine {
  final HisnQuranPresentation presentation;

  /// Verse ranges referenced by this line.
  List<HisnVerseRange> get ranges => presentation.ranges;
}
```

Each `HisnQuranLine` carries a sealed **`HisnQuranPresentation`** that tells consumers how to render:

```dart
sealed class HisnQuranPresentation { ... }

final class HisnQuranSingleAyah extends HisnQuranPresentation {
  final HisnVerseRange range;  // one ayah → AyahWidget
}

final class HisnQuranPassage extends HisnQuranPresentation {
  final List<HisnVerseRange> ranges;  // partial passage → continuous flow
}

final class HisnQuranMushafPages extends HisnQuranPresentation {
  final List<int> pages;              // 1–604 → MushafPage per page
  final List<HisnVerseRange> ranges;
}
```

Classification happens at parse time via `QuranPresentationClassifier`:

| Marker example | Presentation |
|---|---|
| `(2:255:255)` | `HisnQuranSingleAyah` |
| `(112:1:4),(113:1:5),(114:1:6)` | `HisnQuranMushafPages` |
| `(32:1:30)` (full surah) | `HisnQuranMushafPages` |
| `(2:1:3)` (partial surah) | `HisnQuranPassage` |

**Example — mixed content in Flutter:**

```dart
for (final line in item.lines) {
  switch (line) {
    case HisnPlainLine(:final text):
      Text(text);
    case HisnQuranLine(:final presentation):
      switch (presentation) {
        case HisnQuranSingleAyah(:final range):
          AyahWidget.fromSurahAyah(surah: range.surah, ayah: range.startAyah);
        case HisnQuranMushafPages(:final pages):
          for (final page in pages) MushafPage(page: page, hideHeader: true);
        case HisnQuranPassage(:final ranges):
          QuranPassageWidget(ranges: ranges); // your continuous-flow widget
      }
  }
}
```

### Quranic markers — `QuranText[...]`

Some items store Quranic text as placeholders instead of inline Arabic:

```
QuranText[(2:152:152)]
QuranText[(3:190:200)]
QuranText[(2:1:3),(3:190:200)]   // multiple ranges in one line
```

Format: `QuranText[(surah:startAyah:endAyah), ...]`

Parsed by `QuranTextParser.parseContent(raw)` into `HisnQuranLine` with `HisnVerseRange` objects:

```dart
final range = HisnVerseRange(surah: 2, startAyah: 152, endAyah: 152);
range.length        // number of ayahs
range.isSingleVerse // true when start == end
```

### Plain-text resolution — `client.uthmani`

When you need readable Arabic instead of mushaf rendering, resolve placeholders using the bundled Uthmani database:

```dart
// Replace Quranic lines with resolved Arabic prose
final resolved = item.resolvePlainText(client.uthmani);

// Or get a single string
final text = item.toPlainText(client.uthmani);

// Low-level: fetch ayah text for a range
final arabic = client.uthmani.getArabicText(
  surah: 2,
  startAyah: 255,
  endAyah: 255,
);
```

### Commentary — `client.commentary`

| Method | Returns |
|---|---|
| `byContentId(int contentId)` | `HisnCommentary?` |

**`HisnCommentary` fields:** `sharh`, `hadith`, `benefit`

Or use the convenience helper:

```dart
final item = client.contentWithCommentary(contentId);
if (item?.hasCommentary ?? false) {
  print(item!.commentary!.sharh);
}
```

### Fake hadith — `client.fakeHadith`

| Method | Returns |
|---|---|
| `all()` | `List<HisnFakeHadith>` |

**`HisnFakeHadith` fields:** `text`, `darga`, `source`

### Search — `client.search`

Returns `(int total, List<T> items)` for pagination.

```dart
// Search contents — all words must match
final (total, results) = client.search.searchContents(
  HisnSearchQuery(
    value: 'الصباح',
    mode: HisnSearchMode.allWords,
    limit: 20,
    offset: 0,
  ),
);

// Search titles
final (titleTotal, titles) = client.search.searchTitles(
  HisnSearchQuery(value: 'النوم', mode: .typical),
);

// Dispatch by target
client.search.search(
  HisnSearchQuery(value: 'بسم', target: .title),
);
```

**`HisnSearchMode`:**

| Mode | SQL behaviour |
|---|---|
| `typical` | `LIKE %query%` |
| `allWords` | every word must appear |
| `anyWords` | any word may appear |

**`HisnSearchTarget`:** `title` or `content`

Dot-shorthand works with Dart 3.7+ enums:

```dart
HisnSearchQuery(value: 'الصلاة', mode: .allWords, target: .content)
```

### Filtering — `HisnFilterService` / `client.filterContents`

Port of the original app's source/hokm filters. Caller supplies active criteria; no persistent storage.

```dart
final criteria = HisnFilterCriteria(
  filterBySource: true,
  activeSources: {
    HisnSourceFilter.sahihBukhari,
    HisnSourceFilter.sahihMuslim,
  },
);

final criteriaByHokm = HisnFilterCriteria(
  filterByAuthenticity: true,
  activeAuthenticities: {
    HisnAuthenticity.sahih,
    HisnAuthenticity.hasan,
  },
);

final filtered = client.filterContents(allItems, criteria);
// or
HisnFilterService.apply(allItems, criteria);
```

**`HisnSourceFilter`** matches substrings in the `source` column (e.g. `بخار` → Bukhari).

**`HisnAuthenticity`** matches the exact `hokm` string:

| Enum | DB value |
|---|---|
| `quran` | قرآن |
| `sahih` | صحيح |
| `hasan` | حسن |
| `daeif` | ضعيف |
| `mawdu` | موضوع |
| `athar` | أثر |

Parse from raw string: `HisnAuthenticity.tryParse(item.hokm)`

### Audio

Audio is exposed as remote URLs only (no bundled MP3 files):

```dart
if (item.hasAudio) {
  final url = item.audio!.remoteUrl; // e.g. http://www.hisnmuslim.com/audio/ar/1.mp3
}
```

The `audio` column (local filename) is stored on `HisnTitle.audioFileName` but not used for playback in this package.

## Flutter integration

SQLite cannot read Flutter asset bundles directly. Copy the four database files to a writable directory, then open the client from that directory.

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _assetPrefix = 'packages/hisn_elmoslem/assets/database/';
const _files = [
  HisnDatabaseNames.hisn,
  HisnDatabaseNames.commentary,
  HisnDatabaseNames.fakeHadith,
  HisnDatabaseNames.uthmani,
];

Future<HisnClient> openHisnClient() async {
  final dir = p.join(
    (await getApplicationDocumentsDirectory()).path,
    'my_app',
    'hisn_databases',
  );
  await Directory(dir).create(recursive: true);

  for (final name in _files) {
    final target = File(p.join(dir, name));
    if (target.existsSync()) continue;
    final data = await rootBundle.load('$_assetPrefix$name');
    await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  return HisnClient.openFromDirectory(dir);
}
```

In the Tawaq app, this is handled by `hisnDataSourceProvider` in `lib/feature/muslim_fortress/data/repository/hisn_repository.dart`.

For **widget tests**, point directly at the package assets on disk:

```dart
final client = await HisnClient.openFromDirectory(
  'packages/hisn_elmoslem/assets/database',
);
```

## Keeping data up to date

Databases are maintained upstream in [muslimpack/HisnElmoslem_App](https://github.com/muslimpack/HisnElmoslem_App). This repo tracks that project as a git submodule at `packages/HisnElmoslem_App`.

### Manual sync

```bash
# 1. Update the upstream submodule
git submodule update --remote packages/HisnElmoslem_App

# 2. Copy databases into this package and refresh the lock file
cd packages/hisn_elmoslem
dart run tool/sync_upstream.dart
```

The sync tool:

1. Copies `hisn_elmoslem.db`, `commentary.db`, `fake_hadith.db`, and `quran.ar.uthmani.v2.db`
2. Writes `assets/upstream.lock.json` with the upstream commit SHA and table row counts

### Automated sync

GitHub Actions workflow `.github/workflows/sync-hisn-upstream.yml` runs weekly (and on manual dispatch) to update the submodule, run the sync tool, test, and open a PR if databases changed.

### Lock file

`assets/upstream.lock.json` records:

```json
{
  "source_repo": "https://github.com/muslimpack/HisnElmoslem_App",
  "source_commit": "1d52411b6d8457630693a9394190ef30265e68f5",
  "synced_at": "2026-06-03T04:28:12.230606Z",
  "databases": { ... }
}
```

Tests assert expected row counts against this snapshot. After a sync, verify counts and update tests if the upstream maintainer added or removed content intentionally.

## Database schema

### `hisn_elmoslem.db`

**`titles`**

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER | Primary key |
| `order` | INTEGER | Display order |
| `name` | TEXT | Arabic title |
| `freq` | TEXT | Recurrence: `d`, `w`, `m`, `y` |
| `search` | TEXT | Normalized search text |
| `audio` | TEXT | Local audio filename (optional) |

**`contents`**

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER | Primary key |
| `order` | INTEGER | Order within title |
| `titleId` | INTEGER | FK → `titles.id` |
| `content` | TEXT | Body (may contain `QuranText[...]`) |
| `count` | INTEGER | Repeat count |
| `fadl` | TEXT | Virtue text |
| `source` | TEXT | Takhreej |
| `hokm` | TEXT | Authenticity ruling |
| `search` | TEXT | Normalized search text |
| `audio_url` | TEXT | Remote MP3 URL |

### `commentary.db`

**`commentary`:** `id`, `contentId`, `sharh`, `hadith`, `benefit`

### `fake_hadith.db`

**`fakeHadith`:** `id`, `text`, `darga`, `source`

### `quran.ar.uthmani.v2.db`

**`arabic_text`:** `sura`, `ayah`, `text` — Uthmani script for plain-text resolution

## Testing

```bash
cd packages/hisn_elmoslem
dart test
```

Tests cover:

- `QuranText` parsing (single ayah, multi-range, mixed content)
- Database smoke queries and row counts
- Featured title lookup by name fragment
- Commentary loading
- Search and authenticity filtering
- Uthmani plain-text resolution

## Project layout

```
packages/hisn_elmoslem/
├── assets/
│   ├── database/           # Bundled SQLite files (synced from upstream)
│   └── upstream.lock.json  # Sync metadata + row counts
├── lib/
│   ├── hisn_elmoslem.dart  # Public barrel export
│   └── src/
│       ├── client/         # HisnClient
│       ├── database/       # HisnDatabase, HisnDatabaseNames
│       ├── models/         # Domain models, enums, sealed lines
│       ├── parsers/        # QuranText parser, row mapper, Uthmani resolver
│       ├── services/       # Title, content, search, commentary, filters
│       └── utils/          # Database path resolution
├── test/
├── tool/
│   └── sync_upstream.dart  # Upstream database sync script
├── pubspec.yaml
└── README.md
```

## What is not included

- Flutter UI (themes, bookmarks, alarms, tally, share-as-image, etc.)
- Local MP3 audio files (remote URLs only)
- `data.db` — per-user runtime storage from the original app (bookmarks, read state)
- Online network APIs — everything is offline SQLite

## Related packages in Tawaq

| Package | Role |
|---|---|
| `hisn_elmoslem` | This package — structured Hisn al-Muslim data |
| `mushaf_reader` | Quranic ayah rendering in the Muslim Fortress UI |
| `packages/HisnElmoslem_App` | Upstream git submodule (data source only, not compiled) |

## License

Data originates from the HisnElmoslem_App project. Refer to the upstream repository for content licensing. Package code follows the Tawaq project license.
