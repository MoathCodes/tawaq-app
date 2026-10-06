# Fortress and Hadith UI follow-up — October 6

Fortress has space beside the resize handle and compact, labeled catalog tabs.
Expanded thikr previews show the complete text, distinct virtue and sourced
benefits. Share is a separate footer action, so sharing does not expand or
collapse the preview. The share card puts the text and virtue first, followed
by compact attribution.

Hadith Share, Copy text and bookmarks sit inside the result footer. Share and
Copy use the same placement in wide and compact details; embedded comparison
cards use the same component. These actions are independent of selecting the
card. Copy preserves the complete text, hukm and available attribution.
The selected card keeps its flat fill and uniform one-pixel border.

Opening an alternate Hadith now opens that record through the existing
specific-list controller. Previously its key could be selected while absent
from the visible list, leaving the selected-record provider empty. The original
search snapshot is retained for returning to results. No separate selected-object
state or persisted schema was introduced.

The first Impeccable inspection caught a Forui inherited one-line title limit
on expanded thikr text. An explicit unlimited text-style boundary removes it;
a regression checks the rendered paragraph rather than just the Text property.
The first inspection also found an introductory record whose virtue exactly
duplicates its source field. Browse and sharing omit that duplicate using
`hasDistinctVirtue`; both raw fields remain intact. Focus reading and the full
study/source view retain their existing behavior. References embedded in sourced
benefit text remain intact.

Fortress sharing now has one owner for optional commentary loading. A failed or
missing selected detail blocks image export and offers Retry or deselection.
An error on a deselected detail does not block sharing. Capture disables options
and duplicate exports; closing during loading does not update disposed state.
The localized recovery message was generated with `fvm flutter gen-l10n`.
No other generator inputs or local package sources changed in this follow-up.

The implementation preserves the incumbent Manuscript identity, IBM Plex Arabic
and Forui controls. Impeccable layout, polish and craft guidance informed the
bounded inspection and one confirmation round. Resolved Forui 0.27.3 source was
checked for tile text defaults, grouped rows, tabs, buttons and resize behavior.
The split container's physical coordinates explain the RTL padding correction;
the shared split implementation itself was not changed by this follow-up.

The confirmation contains 168 native Linux captures: 80 Fortress and 88 Hadith.
Arabic/English, Manuscript light/dark, 800×600 and 1200×860, normal and extra-large
text are represented. All captures decoded, all nine contact sheets were
inspected, and four complete views were checked for expanded text, share-card
hierarchy and action placement. Flutter error lists and the native error log
are empty. All 581 recorded source hashes still match the confirmed candidate.
The ten affected Fortress golden compositions were refreshed and inspected.

The native harness invokes mounted app callbacks/controllers and captures Flutter
render buffers with isolated XDG/Hive data. It does not certify native OS input,
AT-SPI, real clipboard/image drag/save integration, or every release state.
The Hadith visual record is transcribed from the user's screenshot without
independent authentication; optional recovery records are explicitly synthetic.
The alternate-selection and clipboard behaviors are covered by widget tests.
Windows/macOS runners, content permissions and the broader release acceptance
requirements recorded in the launch status remain pending.

Final results are recorded in
[fortress-hadith-followup-verification.json](fortress-hadith-followup-verification.json).
Focused tests pass **126 tests**; analysis has **zero errors and zero warnings**
(442 informational diagnostics). Both the review build and normal `lib/main.dart`
Linux debug build pass. The full app suite passes **1,234 tests**.
No commit, push, PR or release was performed.

Representative confirmation evidence:

- [Expanded Arabic thikr](evidence/ui-followup/fortress-ar-dark-1200-normal-expanded.png)
- [Thikr share card](evidence/ui-followup/fortress-ar-dark-1200-normal-share-card.png)
- [Wide Hadith result and details](evidence/ui-followup/hadith-ar-dark-1200-normal-result.png)
- [Compact Hadith footer at extra-large text](evidence/ui-followup/hadith-ar-dark-800-xl-result.png)
- [First confirmation contact sheet](evidence/ui-followup/contact-01.png)
- [Updated Fortress goldens](evidence/ui-followup/goldens-contact.png)
