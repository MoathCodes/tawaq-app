# Content sources

This inventory records the sources used by the implementation. It does not
extend Tawaq's MIT license to religious text, recordings, fonts or translations.
Bundled source text has not been changed by the launch-readiness work.

| Content | Repository authority / upstream |
| --- | --- |
| Prayer calculation | `packages/adhan_dart`, pinned Git submodule; calculation settings remain user-selected |
| Hadith search, grading and references | [Dorar](https://dorar.net), through the pinned `dorar_hadith` package |
| Reciter catalog, recordings and ayah timing | [MP3Quran](https://www.mp3quran.net), runtime API metadata and exact reciter/moshaf IDs |
| Hisn al-Muslim | `packages/hisn_elmoslem`; [HisnElmoslem_App](https://github.com/muslimpack/HisnElmoslem_App), using the bundled source metadata |
| Mushaf data and glyph preparation | `packages/mushaf_reader/assets/hive/manifest.json` and its data generator; package README records Wahy and quran_library as implementation resources |
| QCF4 fonts | [King Fahd Quran Printing Complex](https://qurancomplex.gov.sa); separate source terms, as recorded in the package LICENSE |
| Adhan recordings | [Athan-MP3](https://github.com/abodehq/Athan-MP3), as recorded in README.en.md |
| Interface fonts | IBM Plex Sans Arabic and Noto families; bundled SIL Open Font License files |

The four tafsir and ten translation edition names below come from
`TafsirId` and `TranslationId`. [content-assets.json](content-assets.json)
records the current asset bytes' SHA-256 digests. The repository does not
currently record a verified upstream revision and redistribution permission
for each SQLite edition. Those fields remain explicitly unresolved; do not
infer them from an edition name or from the app's code license. Complete this
provenance review before public distribution of these datasets.

| Asset | Edition recorded by the app |
| --- | --- |
| `assets/database/tafseer_ar/tafseer_mouaser.db` | Tafsir Al-Muyassar / التفسير الميسر |
| `assets/database/tafseer_ar/Quraan_Ba.db` | Tafsir Al-Baghawi / تفسير البغوي |
| `assets/database/tafseer_ar/Quraan_IK.db` | Tafsir Ibn Kathir / تفسير ابن كثير |
| `assets/database/tafseer_ar/Quraan_AS.db` | Tafsir As-Sa’di / تفسير السعدي |
| `assets/database/saheeh_international.db` | Saheeh International (English) |
| `assets/database/quran_bn.db` | Muhiuddin Khan (Bengali) |
| `assets/database/quran_es.db` | Muhammad Isa García (Spanish) |
| `assets/database/quran_fr.db` | Muhammad Hamidullah (French) |
| `assets/database/quran_id.db` | DEPAGIS (Indonesian) |
| `assets/database/quran_ru.db` | Elmir Kuliev (Russian) |
| `assets/database/quran_sv.db` | Knut Bernström (Swedish) |
| `assets/database/quran_tr.db` | Diyanet İşleri (Turkish) |
| `assets/database/quran_ur.db` | Fateh Muhammad Jalandhari (Urdu) |
| `assets/database/quran_zh.db` | Ma Jian (Chinese) |

## October 5 provenance investigation

Git history identifies the Saheeh International and Al-Muyassar database imports
in `edf6c4ba2881f8ad0d30012506fe4d465a537aa4`; the remaining edition imports are
recorded per asset in the JSON inventory. An app import commit is not an upstream
publisher revision. No bundled text was changed during this investigation.

The [Tanzil translation terms](https://tanzil.net/trans/), reviewed October 5,
describe non-commercial downloads, permission for other use, and a backlink
requirement for applications using more than three translations. This is a
research lead, not proof that these SQLite files came from Tanzil or that their
redistribution is permitted. The original download/conversion records and
applicable publisher permissions are still needed to complete the inventory.

The project owner identified [IslamHouse](https://islamhouse.com/en) as a source
lead on October 5. Its [Saheeh International item](https://islamhouse.com/en/books/78592/)
provides a PDF and links to QuranEnc. A separate [2020 publisher PDF](https://d1.islamhouse.com/data/en/ih_books/single2/en-translation-of-the-meanings-of-the-quran.pdf)
hosted by IslamHouse requires written publisher permission for reproduction
and distribution. That notice applies to that publication; matching it to the
bundled SQLite edition remains unresolved. Hosting and download availability
alone do not establish database redistribution permission. No permission
record or exact download/conversion chain was supplied for the fourteen files.
The homepage returned HTTP 429 during inspection; indexed item and publisher
records were used as leads, without asserting a site-wide reuse policy.
