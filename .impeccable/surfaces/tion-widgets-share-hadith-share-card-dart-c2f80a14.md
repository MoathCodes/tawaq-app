---
version: 1
slug: "tion-widgets-share-hadith-share-card-dart-c2f80a14"
primary_target: "lib/feature/hadith/presentation/widgets/share/hadith_share_card.dart"
related_targets: ["lib/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart","lib/feature/hadith/presentation/widgets/results/hadith_result_card.dart"]
---

# Hadith sharing refinement
Scope: local redesign within the existing Tawaq visual system. Read and Operate. Source content, package data, schemas, and unrelated screens remain their owners' responsibility.

## Direction contract
THESIS: A readable excerpt with its source ruling beside the content, followed by compact attribution. Large empty areas and separated oversized metadata labels do not serve this task.
OWN-WORLD: Inherit Tawaq's Manuscript palette, IBM Plex Sans Arabic, Forui controls, semantic destructive colors, existing radii and spacing. No app identity replacement.
STORY: Open Share from a result or detail. Check a truthful preview, choose available attribution, then copy text or save/copy an image. Negative source warnings always remain attached.
FIRST VIEWPORT: Excerpt at the top of the preview, full source judgment directly below, compact attribution and subtle app signature at the end. Options next to or below the preview; three visible actions at the footer.
FORM: Precisely specified local extension, code-led; no concept tournament or seed applies. Content determines card height, full source wording wraps, missing placeholders have no controls.
FINISH: Native callback captures, regression tests, source-policy review, fresh independent visual review and scoped documentation. OS input and accessibility are outside this harness's proof.
