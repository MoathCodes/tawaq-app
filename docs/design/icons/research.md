# Leaf icon research

Research date: 2026-09-30. This pass studies the user's two reference images and
selects a production workflow. It does not change installed artwork.

## What the references show

These observations come from the supplied images; their original software and
construction process are unknown.

The cactus has a rounded silhouette, generous white space, yellow-green color,
and a small expression. Its top leaf uses a darker plane to suggest a fold.
The friendliness comes from its shape and character as well as its palette.
Tawaq can inherit gentle curves and organic color without introducing a mascot.

The blue mark uses overlapping curved shapes, precise negative space and a
related range of cyan, blue and indigo. Darker overlap regions suggest volume.
The form remains simple despite the color variation.

Both images also show tilted, lifted white tiles with surrounding shadows.
That presentation contributes to perceived polish. Production review must include
a front-facing square icon and actual menu/tray sizes, alongside a presentation
mockup, so the quality of the artwork itself remains visible.

## How to construct the next leaf

Use a small set of editable Bezier shapes for the two leaves/book pages. Refine
the curves and central gap; introduce slight organic asymmetry. Give each plane
purposeful tonal variation, using gradients or clipped shading, with one consistent
light direction. Limit dimensional detail to a soft fold or edge highlight.
Preserve a clear silhouette when color and detail disappear at small sizes.

Apple's guidance supports a simple core idea, filled overlapping shapes, clear
edges and vector source layers. Its current layered icon system is Apple-specific;
Tawaq's existing cross-platform PNG/ICO delivery remains the production target.
[Apple app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons)

## Relationship to Tawaq

The current default palette is Manuscript, defined in
`lib/theme/custom_themes.dart` and selected by `lib/theme/theme_model.dart`:

- Light parchment background: `#F7F4ED`.
- Light-theme gold: `#6D4F09`.
- Dark-theme gold: `#E6A819`.
- Dark background: `#1E1C1A`.

These hex values are calculated from the repository's HSL definitions. Existing
README light/dark screenshots confirm the parchment/gold visual family; they are
reference captures, not newly captured runtime evidence.

The previous slate-blue leaf was detached from this identity. The next exploration
should compare an olive/sage leaf on warm parchment with a honey/ochre leaf on
parchment or warm charcoal. Green is an exploratory brand extension inspired by
the user's reference, not an existing global Tawaq theme token. Warmth and calm
are visual judgments to assess with the user, not universal psychological claims.

## Tools and agent control

| Tool | Useful role | Agent interface | Decision |
| --- | --- | --- | --- |
| Inkscape | Editable vector curves, layered color and shading; PNG exports | SVG files, CLI exports, named-object geometry queries, actions and shell mode | Recommended additional tool |
| Blender | Actual modeled forms, materials and lighting | Background rendering and Python automation | Reserve for a genuinely sculpted 3D direction |
| Krita | Painted texture or illustrated character work | Python API, plugins and Scripter inside the app | Less suited to this crisp vector mark |
| Apple Icon Composer | Apple-native layered icon appearances | Layer import and visual controls; requires macOS | Future Apple delivery option |

Inkscape, Blender and Krita were not found on PATH in this session. ImageMagick
is already installed. Image generation is also available for concept exploration,
though an editable vector master gives more direct control of the final geometry.
Native GUI operation would need its own runtime verification; the recommended
workflow has a documented CLI surface and does not depend on GUI automation.

Inkscape supports automatic exports, exporting named objects, geometry queries,
actions and shell mode. The locally installed version's `--help` and
`--action-list` will be checked before use, because the wiki includes historical
options. [Inkscape CLI documentation](https://wiki.inkscape.org/wiki/Using_the_Command_Line)

Blender supports background rendering and Python execution.
[Blender command-line documentation](https://docs.blender.org/manual/en/dev/advanced/command_line/)
Krita provides a Python API and an in-app scripting console.
[Krita scripting documentation](https://docs.krita.org/en/user_manual/python_scripting/introduction_to_python_scripting.html)
Icon Composer works with artwork layers and Apple appearance modes and currently
requires macOS Tahoe 26.4 or later.
[Icon Composer](https://developer.apple.com/icon-composer/)

## Production workflow

Author layered SVG masters in Inkscape. Make the existing generator consume the
artwork and own deterministic size exports, ICO assembly and installation. Keep
a simplified small-size/tray version of the same leaf silhouette. Test new color
planes on both light and dark panels at 16, 18, 22, 24 and 32 pixels.

The current Pillow renderer supports solid fills only. It could be extended with
masks and gradients, but a real vector source makes composition, curve refinement
and shading easier to inspect and revise. Installing a tool does not itself resolve
the design: the work is in the palette, silhouette, light and optical balance.

Inkscape is available in Arch's official Extra repository, suitable for this
Omarchy host. Suggested user installation: `sudo pacman -S inkscape`.
[Arch package](https://archlinux.org/packages/extra/x86_64/inkscape/)

## Follow-up: open direction and installed tool

The user clarified that the leaf was only the strongest earlier candidate and
may be replaced; originality matters because leaf marks are common in this area.
Inkscape 1.4.4 is now installed and its local export flags have been verified.
The studio round explores an initial-inspired olive sweep, a waw-inspired honey
loop, and an asymmetric sage folio. Native SVG masters own the artwork; the
existing script handles rendering, compact variants and platform packaging.

## Follow-up: Arabic identity within Folio

The user selected Folio for its depth, palette and fit with the app, then found
similar generic marks elsewhere. The next round preserves that material character
while exploring a custom ت or the full name تَوَّاق. This is a new direction for
the mark, not a change to the app's interface palette or a claim of uniqueness.

The `arabic` collection contains three editable SVG masters: Folded ta
(`folio_ta`) joins Folio's planes into a letter body; Turning ta (`folio_ribbon`)
opens the bowl and adds a turning-page terminal; Tawaq (`folio_name`) uses the
full name. The review favored Turning ta's silhouette, but these remain review
candidates and the installed default remains Folio.

The full name was shaped using the repository's bundled Zain Bold font and
converted to paths with Inkscape's object-to-path action. A temporary Fontconfig
configuration exposed the repository fonts during authoring. The existing OFL
license stays with the bundled font; the resulting SVG requires no runtime font
installation. The exact spelling is retained in the SVG's accessible description.

The full-name master shows its outlined lettering at 64px and above for app
icons. Smaller app icons and every tray use a companion folded ت, keeping the
initial recognizable where the name would become too small. The renderer switches
named `large-mark` and `compact-mark` groups, then removes `detail` groups and
uses `data-small-fill` colors at 32px and below. Other artwork keeps its existing
size behavior.

The [Arabic comparison](arabic-comparison.png) uses the selected Folio foundation
as its baseline. Earlier comparisons remain available to preserve the design
history. These generated previews support visual review; native desktop scaling
and tray behavior still require runtime verification.

## Follow-up: selected Turning ta refinement

The user selected Turning ta and asked to soften its pointed left cap and refine
the fold toward Folio's finish. The revised master rounds the left cap, softens
the raised right tip and carries a continuous fold seam to the base. Restrained
shading planes are clipped to the silhouette. The sage palette, parchment surface
and two-dot ت identity remain consistent across the app and tray exports.

At this stage, Turning ta (`folio_ribbon`) became the selected and installed default and the
first entry in the `arabic` collection. The other Arabic concepts and reference
Folio remain available. Small exports keep the same silhouette and use the
existing detail removal and compact fills at 32px and below.

The [refinement comparison](turning-refined-comparison.png) shows previous Turning
ta, revised Turning ta and reference Folio at launcher, menu and tray sizes on
light/dark surfaces. The [Arabic comparison](arabic-comparison.png) records the
prior exploration. These remain exported-asset previews; native desktop scaling
and tray behavior are not verified by these images.

## Follow-up: selected amber palette

The user selected a warm manuscript-inspired recolor of the approved Turning ت.
Amber (`folio_amber`) is now the installed default. The silhouette and refined
fold remain unchanged; honey highlights, ochre planes and deep brown folds give
the mark warmth while retaining separation on parchment. The compact brown fill
(`#80591F`) has a 5.68:1 contrast ratio against its background (`#F7F4ED`).

The [amber comparison](amber-comparison.png) preserves the sage baseline beside
the new exports. Sage remains selectable as `folio_ribbon`. The same generator
exports app, menu, tray and website assets, including simplified small-size fills.
The Linux app was rebuilt and reinstalled; installed app, tray and launcher pixels
match the exports. macOS and Windows native rendering remain unverified.
