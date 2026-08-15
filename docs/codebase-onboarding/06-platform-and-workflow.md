# Platform systems and daily workflow

## Desktop ownership

Desktop orchestration belongs in `lib/app/desktop`; reusable platform helpers live in `lib/core/desktop`. `desktopShellInitProvider` initializes MPV audio support, local notifications, launch-at-login support, and `window_manager` only on desktop.

`DesktopShell` provides the custom title bar, tray/window synchronization, global shortcuts, close/minimize lifecycle, and single-instance behavior. Desktop preferences belong in the desktop settings notifier. Flush durable settings at process-kill boundaries when writes must complete first.

Prayer alert composition lives under `app/desktop/alerts`. `AdhanAlertHost` is installed above routed content; scheduler and dispatcher turn prayer-day data plus alert settings into notification and sound actions. `core/audio` owns shared players, leasing/arbitration, tracks, and playback state, so features should not create unrelated players.

Use `isDesktopPlatform` from `core/utils/platform.dart` instead of scattered platform checks. Test pure policy/scheduling separately from platform channels by overriding providers.

## Commands

Always use FVM:

```bash
fvm flutter analyze
fvm flutter test
fvm flutter gen-l10n
fvm dart run build_runner build
```

For a fresh clone, a change to `packages/mushaf_reader` generated models, or a full regeneration:

```bash
fvm exec bash tool/codegen.sh
```

The script regenerates `mushaf_reader` before the root package.

## Generator map

| Change | Required generation |
| --- | --- |
| Riverpod annotations, Freezed/JSON models, typed routes | root build runner |
| Hive adapter declarations | root build runner; review tracked adapter output |
| Assets or fonts | root build runner / FlutterGen |
| ARB localization | `fvm flutter gen-l10n` |
| Mushaf Reader generated models | `fvm exec bash tool/codegen.sh` |

Root provider/freezed generated files are ignored. FlutterGen, localization outputs, and Hive adapter metadata are tracked, so inspect them before committing.

## Safe change checklist

1. Locate the owning feature or core module first.
2. Trace the screen → provider → domain/data flow and reuse its existing pattern.
3. Preserve architectural boundaries; run the architecture test when import direction is involved.
4. Reuse shared sources of truth instead of duplicating state.
5. Regenerate after annotation, route, Hive, assets, or localization changes.
6. Check English and Arabic plus narrow and wide layouts for UI work.
7. Run focused tests, then `fvm flutter analyze` and the relevant broader test suite.

## Common traps

| Temptation | Prefer |
| --- | --- |
| Widget timers or `DateTime.now()` loops | `appClockProvider` / `prayerDayProvider` |
| Prayer calculation in UI | prayer-day derived providers |
| Feature helper in `core` | keep it with its owning feature |
| Pass-through repository | only add a layer with behavior |
| Custom button-row segmented control | themed `FTabs` |
| Raw Arabic `contains` search | normalize query and candidate |
| Global storage for all screen UI | feature-owned screen/session settings |

## A productive investigation habit

For an unfamiliar system, find the provider declaration and its focused tests. The provider reveals ownership, lifecycle, and dependencies; tests tend to expose the intended edge cases. Treat source code as the final contract and update this guide when that contract changes.
