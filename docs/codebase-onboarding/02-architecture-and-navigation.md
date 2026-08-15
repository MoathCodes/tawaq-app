# Architecture and navigation

## Boundaries

The intended dependency direction is `app -> core and feature`; `feature presentation -> its domain/data and core`; `feature domain -> core` but never its own data or presentation; and `core -> core` only.

Feature-to-feature imports are forbidden aside from a shrinking legacy allow-list. [`test/architecture/dependency_boundaries_test.dart`](../../test/architecture/dependency_boundaries_test.dart) rejects new violations and requires repaired exceptions to be removed.

| Area | Owns |
| --- | --- |
| `app/` | process composition: startup, router, shell, desktop behavior |
| `core/` | reusable infrastructure that does not know a feature |
| `feature/<name>/data/` | APIs, storage, asset databases, external mappings |
| `feature/<name>/domain/` | business concepts and pure rules |
| `feature/<name>/presentation/` | providers, controllers, screens, widgets, UI models |

Layers are optional. Do not add pass-through repositories or empty folders just for symmetry.

## Startup

[`main.dart`](../../lib/main.dart) initializes Flutter bindings, single-instance handling, Mushaf Reader, file logging, and timezone data, then starts Riverpod.

`AppBootstrap` waits for Hive and, on desktop, shell services. It also waits for onboarding and prayer settings hydration before rendering the router. This prevents a returning user from briefly being redirected to onboarding during a cold/hot start.

`TawaqApp` supplies the Material bridge, Forui theme, localization, router, common scroll behavior, toaster, auto-location observer, and prayer alert host.

## Routes and shell

[`route_provider.dart`](../../lib/app/routing/route_provider.dart) is the route catalog and uses generated typed `go_router` routes.

| Route | Purpose |
| --- | --- |
| `/onboarding` | standalone first-run flow outside the shell |
| `/prayer`, `/quran`, `/hadith`, `/muslim_fortress` | main product destinations |
| `/settings` | settings; the URL owns the live tab |
| `/about` | direct-navigation fallback; shell action opens a dialog |

The main routes are inside `AppShellRoute`, which wraps them in [`PageShell`](../../lib/app/shell/page_shell.dart). It switches from sidebar to bottom navigation below 640px. The sidebar defaults collapsed below 1024px and persists user preference.

Use typed route instances such as `QuranRoute(page: page).replace(context)`. Quran's active page and Settings' active tab live in the URL; persisted values are restore checkpoints only.

## How to trace behavior

Follow this sequence: route, screen, widget, provider/controller, domain rule or repository, then storage/API. State returns in the reverse direction. Start with the route's `build` method; it reveals the live screen entry point much faster than a repository-wide text search.
