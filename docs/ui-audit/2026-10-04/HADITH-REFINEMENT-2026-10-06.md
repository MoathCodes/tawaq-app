# Hadith results and sharing refinement — October 6

Hadith source rulings now remain fully readable in results, details and shared
images. The result overflow menu is replaced by a direct Share action. Plain
text copying includes the complete available ruling and attribution.

The share card puts the Arabic excerpt first, its full source ruling directly
below, then compact attribution and a small app signature. Height follows
content; ruling text wraps without truncation. The dialog keeps Copy text,
Save image and Copy image at its footer. Missing metadata and upstream dash
placeholders have no image options or copied fields; missing narrator data is
also omitted from result semantics.

This is a local refinement under the
[surface direction contract](../../../.impeccable/surfaces/tion-widgets-share-hadith-share-card-dart-c2f80a14.md).
It inherits Tawaq's Manuscript palette, IBM Plex Sans Arabic, Forui controls,
semantic destructive colors, existing spacing and radii. Those choices serve
[PRODUCT.md](../../../PRODUCT.md)'s calm, trustworthy Arabic/English desktop
experience. No global design system document or sidecar was created or rewritten,
and this pass does not repair pre-existing global design drift.

Warning emphasis recognizes explicit negative descriptors supplied by the
source, including weak, fabrication and chain wording. Chain warnings use a
softer destructive tint. This presentation policy checks both the short and
expanded source fields; it never independently authenticates a Hadith or
rewrites religious text. Unknown wording and qualifications without a recognized
negative descriptor retain neutral styling and their full source text. Explicit
negations such as “ليس بضعيف” do not become warnings. Negative rulings cannot be
deselected from images, including by a caller constructing the card directly.
Warning ink mixes the theme's destructive color toward its foreground only
until it reaches a 4.5:1 contrast ratio on the tinted background.

The Node wrapper was inspected at commit
`28f2b3bd1fdaad7dd9e41ac1b42e5afce19a3a1f` (May 3, 2026).
Its [source parser](https://github.com/AhmedElTabarani/dorar-hadith-api/blob/28f2b3bd1fdaad7dd9e41ac1b42e5afce19a3a1f/utils/parseHadithInfo.js)
and [result mapper](https://github.com/AhmedElTabarani/dorar-hadith-api/blob/28f2b3bd1fdaad7dd9e41ac1b42e5afce19a3a1f/services/common/hadithMapper.service.js)
return textual `grade` and `explainGrade`, with no per-result `degreeID`.
The separate [`/data/degree` route](https://github.com/AhmedElTabarani/dorar-hadith-api/blob/28f2b3bd1fdaad7dd9e41ac1b42e5afce19a3a1f/routes/data.routes.js)
loads catalog data through the [data service](https://github.com/AhmedElTabarani/dorar-hadith-api/blob/28f2b3bd1fdaad7dd9e41ac1b42e5afce19a3a1f/services/data.service.js).
That filter catalog is not evidence of an individual result's authenticity.

Selecting available explanation or chain details loads their content. Loading,
an error or an empty response blocks image actions and drag capture. A failure
names the affected section beside Retry above the footer; Retry reloads failed
sections, and deselecting them also restores image actions. Copy text remains
independent of optional image content. Export capture retains its existing
busy state and failure handling.

The affected consumers are result cards, embedded result cards, the detail
pane, metadata rows, result semantics, share options, share rendering and plain
text copying. Regression coverage targets warning recognition and negation,
both source fields, mandatory negative rulings, missing narrator data, complete
copy output, wrapping, contrast, direct-card constraints and optional-content
loading, failure, empty response and recovery. Arabic/English localization was
regenerated with `fvm flutter gen-l10n`. No package source, schema or persisted
field changed in this refinement.

The confirmed Linux review contains **88 PNG captures across 16 combinations**
of Arabic/English, Manuscript light/dark, compact/wide and normal/extra-large
text, plus four contact sheets. It includes result, share preview and complete
card views, with explicitly synthetic optional-failure and recovery cases.
The religious source fixture comes from the user's screenshot. Flutter reports
no errors and the native process exits zero. A fresh independent review found
the clipped explanation, optional-failure recovery and contrast fixes resolved
and accepted the candidate at the requested scope.

Native review uses mounted callbacks and render buffers with isolated XDG/Hive
data. It does not certify OS input, AT-SPI, actual downloads, clipboard delivery
or live network behavior, and establishes no performance or independent
authenticity claim. The captured candidate predates only the final missing-narrator
semantic exclusion, explicit `كذب` descriptor and brace formatting. The harness
disables semantics, and its captured `كذاب` source wording does not match the new
standalone descriptor, so the captured visual record is unaffected.

Candidate hashes, captures and final automated check results belong in
[hadith-refinement-verification.json](hadith-refinement-verification.json).
Final checks pass on the current source: **1,223 app tests**, **17 focused
Hadith tests**, analysis with **zero errors and zero warnings** (439 informational
diagnostics), and the ordinary Linux debug build from `lib/main.dart`. The
bundle is restored to that ordinary entry point. No commit, push, PR or release
was performed.

The later [Hadith card cleanup](HADITH-CARD-CLEANUP-2026-10-06.md) supersedes
result/detail decorative selection and numbered-heading behavior. Its separate
verification record describes that candidate; the evidence above remains the
historical share refinement record.
