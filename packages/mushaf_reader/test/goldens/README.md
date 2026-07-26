# KFQC visual goldens

Compares Flutter `MushafPage` renders to King Fahd Complex (KFQC) Hafs SVG
rasters. Glyph outlines will never match pixel-for-pixel (QCF fonts ≠ SVG
paths); the suite checks **ink density** and **downsampled layout structure**
to catch blank pages, wrong scale, and severe corruptions.

## Smoke set (CI)

Committed refs under `kfqc_refs/`:

`001`, `002`, `003`, `050`, `106`, `604`

```bash
flutter test test/goldens
```

## Regenerate SVG reference PNGs

Requires ImageMagick (`magick`) and a local research clone (gitignored):

```bash
# once
git clone https://github.com/quranpedia/quran-svg.git .research/quran-svg

# smoke pages (default)
dart run tool/rasterize_kfqc_svg.dart

# or full mushaf (local only — do not commit all 604 PNGs)
dart run tool/rasterize_kfqc_svg.dart --all
```

Do **not** use `flutter test --update-goldens` for these refs — the comparator
refuses Flutter-overwritten SVG rasters.

## Full 604-page run (local)

```bash
dart run tool/rasterize_kfqc_svg.dart --all
MUSHAF_KFQC_FULL_GOLDENS=1 flutter test test/goldens/kfqc_visual_golden_test.dart
```

Pages without a PNG under `kfqc_refs/` are **skipped** (not failed).

### Single extra page

```bash
dart run tool/rasterize_kfqc_svg.dart --pages=603
flutter test test/goldens/kfqc_visual_golden_test.dart --plain-name 'KFQC page 603'
```

Any `kfqc_refs/NNN.png` on disk is auto-registered even without `MUSHAF_KFQC_FULL_GOLDENS`.

## Geometry constants

Measured page aspect / marker insets live in
`lib/src/core/kfqc_page_geometry.dart`. Refresh numbers with:

```bash
dart run tool/analyze_kfqc_geometry.dart
```

## Thresholds

See `KfqcImageDiff` in `tolerant_golden_comparator.dart`:

- `minInkRatio` — blank / empty page
- `maxInkDelta` — ink density vs SVG
- `maxStructureMae` — downsampled content-region density MAE
