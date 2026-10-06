# Final reported fixes — October 6

The player now closes its shell overlay before routing to the Quran. Timed
playback opens its current ayah, including the timeline fallback; untimed
playback opens the surah start. It no longer pops the destination route.
Regression tests exercise the button callback, overlay ordering, destination
retention, and both playback navigation modes.

Quran ayah actions are in a compact header popover, so the selected ayah does
not take vertical space from reading. The popover sizes to its contents.
Left/Right and Space turn pages, including full double-page spreads; Up/Down
move selection. One route owner handles those keys even when a button or
read-only prose has focus. Editable fields, portal scopes, dialogs and the
recitation drawer keep their own keys. Late ayah loads cannot overwrite a newer
page or selection. Root focus fallback remains usable after desktop traversal.

Fortress previews keep sourced **الفضل** visible in their collapsed state;
optional **الفائدة** remains distinct. Shared Quran passages use Uthmanic Hafs
rather than the application font. Repetition count is included by default and
can be toggled, including a count of one. Raw source content is unchanged.

Device-location unavailability opens manual coordinates and the map by default.
Explicit expansion/collapse choices survive rebuilds. The verbose Linux login
note is removed. Adhan and iqamah share the schedule footer when space permits
and wrap on narrow layouts. Prayer time badges say الوقت. About omits the
bundled-database summary row while retaining the provenance inventory in the
repository; all navigable link rows use the same external-link affordance.

## Verification and scope

Impeccable refinement preserved the incumbent Manuscript/Forui system. The
bounded review caught an oversized ayah popover, which was repaired and
confirmed at 1200×860 normal dark and 800×600 extra-large light, in Arabic and
English. The eight confirmation captures have an empty Flutter error log.

The [evidence directory](evidence/final-fixes/) contains 26 accepted route/share
compositions, seven native key observations, one explicitly named before image,
source hashes and run records. Captures exercise actual Linux app routes with
isolated storage and unavailable-location fixtures. The initial English compact
captures did not reach the requested dimensions and are excluded from accepted
images. Initial appearance captures still showed the route-selected location
pane; confirmation uses the appearance route and supersedes those captures.

Native keyboard delivery used the installed Hyprland compositor's exact-window
`send_shortcut` route after Cua reported that its production Hyprland input
plugin was unavailable. The observed pages were 50 → 51 → 50 → 51 for
Left/Right/Space, then selection 303 → 304 → 303 for Down/Down/Up. The extra Tab
observations exposed root-focus fallback and are recorded as a defect, not a
passing traversal result. Its fix has a widget regression. Native screen-reader,
complete Tab traversal, audio/device and installer acceptance are not certified.

Focused regression checks, refreshed Fortress goldens, full app analysis,
full app tests, package checks, generation, Linux debug builds and release-gate
Python tests are recorded in the adjacent final verification record. Analysis
has no errors or warnings; informational lints remain. Candidate builds now
apply their build number to pubspec before recording toolchain identity, with a
regression checking the recorded identity through acceptance validation.

Windows/macOS machines remain unavailable. Verified redistribution terms for the
14 bundled databases, broader native release acceptance, and the unproven RSS
objective remain release gates. The Dorar 0.6 document is a future migration plan;
this work keeps the pinned dependency.
