TAW-93 Linux evidence

The before recording uses clean main 6b248c40, whose bootstrap splash enables SemanticsDebugger. The route/theme flow produced the accessibility update assertions preserved in before-runtime.txt. The after recording removes only that diagnostic overlay, cold restarts, keeps semantics enabled, and repeats Settings, Quran, Hadith, Fortress and Prayer transitions without application runtime assertions.

Both captures use the same eDP-1 monitor at 1920×1080. The before app viewport is 1920×1080; the after app viewport is 1896×1030 inside the recorded desktop. Before playback is accelerated 2×. Captions distinguish visible UI from runtime-log evidence; these assertions do not display an error page.

This is an observed Linux improvement, not proof of a Flutter engine root cause or every possible semantics failure. The widget regression separately checks that normal startup has no diagnostic overlay and accessibility remains available when bootstrap switches to its error shell. Restoring the old flag makes that regression fail.

Validation: Flutter 3.47.1 Linux debug build; 1,055 app tests passed; analysis has no errors or warnings and 185 existing informational lints. Native screen-reader speech was not exercised. App interactions used a disposable copied profile; real user settings and the original dirty checkout were preserved.
