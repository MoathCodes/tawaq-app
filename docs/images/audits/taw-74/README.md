# TAW-74 visual evidence

These captures come from the disposable combined Linux checkout used to
inspect the Manuscript theme with the adjacent prayer, Hadith, and Fortress
changes. The checkout used isolated `tawaq-taw74-visual` app data, Hive,
Mushaf, recitation-cache, and log paths; no shared `/home/moath/tawaq` data
was used.

- [English light Prayer, wide desktop](prayer-en-light-wide.webp)
- [Arabic light Prayer, wide desktop](prayer-ar-light-wide.webp)
- [Arabic dark Prayer, narrow desktop](prayer-ar-dark-narrow.webp)
- [Arabic dark Fortress, selected recurrence row, desktop](fortress-ar-dark-narrow.webp)

The Linux inspection had degraded AT-SPI support, so these are screenshot
evidence only. The Fortress capture is from the final opaque recurrence-label
fix; the other three captures are the earlier combined theme/runtime matrix.
The bounded run did not reach a current English/dark route or a native
destructive/error state; those remain documented limitations in the PR.
