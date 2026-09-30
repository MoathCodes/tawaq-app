# Tawaq icons

The generator exports editable icon candidates and desktop assets.
**Turning ta / sage (`folio_ribbon`) is the selected and installed default.**
Its custom ت keeps Folio's sage palette, parchment surface and folded depth.
The latest refinement softens the left cap and right tip, with a continuous fold
seam and restrained shading planes. The `arabic` collection contains:

- **Folded ta** (`folio_ta`): Folio's planes joined into a ت body with two dots.
- **Turning ta** (`folio_ribbon`): an open curved ت bowl with a turning-page terminal.
- **Tawaq** (`folio_name`): the full name تَوَّاق, outlined from the app's bundled
  Zain Bold font, with a companion folded ت for small icons and trays.

Folded ta and Tawaq remain alternatives. The previous `studio` collection remains
available:

- **Taw / olive** (`taw`): an Arabic-initial-inspired sweep with two dots.
- **Pull / honey** (`pull`): a continuous returning loop inspired by the waw in
  Tawaq's name, using the app's warm gold family.
- **Folio / sage** (`folio`): asymmetric folded manuscript planes.

All three use warm parchment, directional gradients and a small number of shaded
planes. The source artwork is in `artwork/*.svg`, with named surface, mark and
detail groups. Taw and Pull remain available as alternatives.

Six earlier candidates remain selectable: crescent/jade, qaf/plum, arch/clay,
qaf/porcelain (`monogram`), lune/ink and leaf/slate.

```bash
# Review the selected refinement against the previous Turning ta.
./tooling/icons/generate.sh --variant folio_ribbon --out out/turning-refined --before ../../docs/design/icons/turning-before --before-label 'Turning ta / previous'
# Review the Arabic collection against its Folio foundation.
./tooling/icons/generate.sh --all --collection arabic --out out/arabic --before ../../docs/design/icons/folio-foundation --before-label 'Folio / foundation'
# Export the earlier studio round.
./tooling/icons/generate.sh --all --collection studio --out out/studio --before ../../docs/design/icons/before
# Regenerate the selected default across desktop and Flutter assets.
./tooling/icons/generate.sh --install
# Rebuild and reinstall the Linux app with the pinned Flutter SDK.
fvm exec flutter-install .
# Install an alternative.
./tooling/icons/generate.sh --variant pull --install
./tooling/icons/generate.sh --variant taw --install
./tooling/icons/generate.sh --variant folio --install
# Export the two earlier rounds.
./tooling/icons/generate.sh --all --collection original
./tooling/icons/generate.sh --all --collection refined
python3 -m unittest discover -s tooling/icons -p 'test_*.py'
```

## Artwork and exports

Studio and Arabic colors and geometry belong to the SVG masters; the corresponding
`config.yaml` colors mirror the compact background and main mark for contrast
validation. Keep those values aligned with the SVG's `data-small-fill` colors when
changing the palette. Edit an artwork SVG in Inkscape or as SVG source.
The renderer uses Inkscape's CLI, with source
bytes as part of the in-memory cache key, so artwork edits invalidate cached images.
Pillow and PyYAML handle legacy geometry, contact sheets and multi-resolution ICOs.
Both artwork collections require `inkscape` on PATH; missing Inkscape produces an
explicit error. The full-name master contains paths, so production exports need
no fonts. It was authored with Inkscape's object-to-path conversion using a temporary
Fontconfig configuration pointing at the repository's bundled Zain Bold font;
its existing OFL license remains in `assets/fonts/`. No browser screenshots are used.

Masters with `large-mark` and `compact-mark` groups show the large mark at 64px
and above for app icons; smaller app icons and every tray use the companion compact
mark. For the full-name candidate this deliberately changes from تَوَّاق to ت.
At 32px and below, the renderer removes the SVG's `detail` groups and applies each
shape's `data-small-fill` color. This keeps the silhouette legible as dimensional
shading disappears. Tray rendering enlarges the named `mark` group slightly.
Transparent corners frame an opaque parchment tile. Earlier variants retain their
own size-specific dot and star adjustments.

`default` in `config.yaml` selects the exported direction unless `--variant`
overrides it; installation happens only with `--install`. When `--collection` is
given, its first entry supplies the default
instead; `--variant` still takes precedence. `--all` exports candidates under
`out/variants/`; `--collection` limits it to one round. The selected direction also
occupies standard output paths. CLI paths resolve relative to `tooling/icons/`.

The output contains editable SVG, macOS and Linux PNGs, a seven-frame Windows ICO,
tray PNGs including 16, 18, 22, 24 and 32px, and a 1024px website icon at
`website/images/app-icon.png`. `preview.html` displays masters and
actual-size tray icons. `comparison.png` includes the supplied `--before` baseline.
The legacy Dart entry point forwards to the same renderer.

`--install` copies the selected icon to Linux hicolor, existing macOS app-icon
PNG sizes, the Windows ICO, Flutter app/tray assets, and source PNG/SVG. It preserves
macOS catalog metadata and unrelated platform files. About and media-session artwork
use the Flutter app icon. Asset paths remain stable, so FlutterGen and localization
regeneration are unnecessary.

When their `public/` directories exist, `--install` also syncs the website icon to
`website/sakinah/public/images/app-icon.png` and
`website/concepts/public/images/app-icon.png`. Both sites already use that path
for their header and browser metadata. Missing website checkouts are skipped;
the generator does not create an incomplete site. These are separate, ignored
repositories, so committing app assets does not commit or publish website changes.

The root `.flutter-install.conf` sets the Linux application name to Tawaq, its
application ID to `tawaq`, and its launcher icon to the generated 512px Linux PNG.
Run `fvm exec flutter-install .` after regenerating assets to rebuild and reinstall
the local Linux app through the pinned SDK.

## Evidence

The latest [Turning ta comparison](../../docs/design/icons/turning-refined-comparison.png)
shows the previous Turning ta, the refined default and reference Folio at launcher,
menu and tray sizes on light/dark surfaces. The prior-round
[Arabic comparison](../../docs/design/icons/arabic-comparison.png) compares the
three Arabic directions with their Folio foundation. The
[studio comparison](../../docs/design/icons/studio-comparison.png)
shows the original wordmark and new artwork at launcher, menu and tray sizes on
light/dark surfaces. [Initial](../../docs/design/icons/comparison.png) and
[refined](../../docs/design/icons/refined-comparison.png) comparisons preserve the
previous rounds. [Research](../../docs/design/icons/research.md) records the
reference analysis and tool choice.

These are exported-asset previews, not native desktop screenshots. Native dock,
taskbar and tray scaling and icon-cache refresh remain unverified.
