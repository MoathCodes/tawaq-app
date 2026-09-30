# Tawaq icons

The generator has two rounds of geometric icon directions. The refined round uses
one color per mark, controlled curves, and muted surfaces:

- **qaf / porcelain** (`monogram`, default): a dark green Arabic ق on warm ivory.
- **lune / ink** (`lune`): a tapered ivory crescent on deep petrol, without a star.
- **leaf / slate** (`leaf`): two ivory curves suggesting an open book on slate blue.

The original crescent/jade, qaf/plum, and arch/clay candidates remain selectable,
for six candidates in total.
All candidates use an opaque tile with transparent corners, so their mark contrast
works on light and dark desktop surfaces without theme detection. This redesign
changes the app and tray icons, not the app's interface palette.

```bash
./tooling/icons/generate.sh --all --collection refined --install --before ../../docs/design/icons/round-one --before-label 'First round'
./tooling/icons/generate.sh --variant lune --install
./tooling/icons/generate.sh --variant leaf --install
./tooling/icons/generate.sh --all --collection original
python3 -m unittest discover -s tooling/icons -p 'test_*.py'
```

Edit palettes in `config.yaml` and geometry in `render.py`. `default` selects the
installed direction unless `--variant` overrides it. When `--collection` is given,
its first entry supplies the default instead; `--variant` still takes precedence.
`--all` exports each candidate under `out/variants/`; `--collection` limits it to
one round. The selected direction also occupies the standard output paths.
`out/preview.html` shows the SVG and actual-size tray exports;
`out/comparison.png` compares the candidates with the old icons when `--before`
is supplied. Paths passed to the CLI resolve relative to `tooling/icons/`.

Each target size is drawn independently with supersampling. At 32px and below the
original crescent's spark becomes a simpler diamond and both qaf variants' dots
become slightly larger.
The tray silhouette is enlarged. Transparent corners frame an opaque tile; there
are no font glyphs, shadows, browser captures, or theme-sensitive white-only marks.
SVG masters preserve editable curves. PNG and multi-resolution ICO exports require
only Pillow and PyYAML; no Chrome or ImageMagick is needed. The old Dart entry point
forwards to this same renderer; its former PNG-source flags have been retired.

`--install` updates Linux hicolor icons, all existing macOS app-icon PNG sizes,
the Windows ICO, the Flutter app and tray assets, and the selected source PNG/SVG.
It preserves macOS catalog metadata and unrelated files in platform directories.
The Flutter app icon also supplies About and media-session artwork; existing asset
paths stay valid, so no FlutterGen or localization regeneration is needed.

The checked-in [original comparison](../../docs/design/icons/comparison.png)
and [refined comparison](../../docs/design/icons/refined-comparison.png) show generated
assets on light and dark surfaces, including actual 16–64px menu and 16–32px tray
sizes. These are asset previews, not screenshots of native desktops. Native Windows
and macOS menu/dock rendering still needs confirmation on those operating systems.
