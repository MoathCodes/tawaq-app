# Desktop UI audit — 2026-10-03

Evidence reflects the local main checkout at e9293e32b489c2d5811cdf682f7e872029fa2adf plus the pre-existing uncommitted changes listed in checkout.json. No app source was changed for this audit. This branch contains captures only.

Linux / Hyprland 0.56.2; Flutter 3.47.5 debug Linux build, Impeller OpenGLES. Arabic and English; light and dark themes. Normal text scale. Tested window sizes: 800×600 (declared minimum), 1200×700, and 1342×718. A copied profile supplied existing settings, a paused recitation, and 19 downloaded files (289 MB). Live user data was preserved.

## Captures

- Recitation controls: vertical label wrapping and bottom overflow in English/dark 1342×718 and Arabic/light 800×600.
- Offline files: initial viewport versus bottom of list, where Save while listening is placed.
- Prayer entrance: normal-speed 1200×700 clip and 4× time-dilation 1342×718 clip. Calendar dates temporarily disappear/shift after the schedule snaps into place. The cropped frame strip is consecutive 10-fps frames from the slow clip, ordered left-to-right then top-to-bottom. The reset is clear under slowdown; the normal clip does not isolate the same brief calendar reset as clearly. Time dilation was restored to 1×.
- Quran: compact study layout overflows by 43–45 pixels and leaves a very small reader. Wide comparison and compact Double Page fallback included.
- Fortress: chapter list clipped to a sliver at minimum size; wide comparison and selected chapter at minimum size.
- Restored recitation timeline: paused 2:03 / 0:00 before playback; after a brief play/pause, 2:12 / 10:16 with the seek thumb updated.

## Coverage and limits

Visited prayer, Quran study and double-page modes, Quran search, recitation drawer, reciter picker, range/repeat, sleep timer, downloaded files, Hadith search/results/detail/filters, Fortress browse/detail, settings appearance/prayer/location/shortcuts, sidebar collapse/expand, and About. Relevant loading and empty search states were observed. Not every route/state received every locale/theme/size combination.

Native discovery, window geometry and screenshots worked. Native pointer input reported an unavailable production Hyprland input plugin, so actions used Flutter Driver. Physical keyboard shortcuts, hover, native tray interactions, and first-run onboarding were not audited. No claim of exhaustive defect discovery. No fixes or code tests were performed.

PNG captures were inspected. Both uploaded MP4s were inspected through extracted frames, probed, and fully decoded without errors. Video is silent, cropped to the app window from output recording. Runtime errors include the observed study tab overflow; debug overflow stripes are diagnostic overlays.
