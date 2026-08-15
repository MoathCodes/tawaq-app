# Tawaq codebase onboarding

This guide is a practical map of Tawaq: what owns each concern, where to start reading, and the rules that keep the app coherent. It assumes Flutter familiarity but no prior knowledge of this repository.

## Suggested reading order

1. [Start here](01-start-here.md) — project map and setup.
2. [Architecture and navigation](02-architecture-and-navigation.md) — startup, routes, shell, and boundaries.
3. [State and storage](03-state-and-storage.md) — Riverpod, persistence, time, and databases.
4. [UI, layout, and localization](04-ui-layout-and-localization.md) — Forui, responsiveness, accessibility, and RTL.
5. [Feature guides](05-feature-guides.md) — end-to-end flows for each product area.
6. [Platform and daily workflow](06-platform-and-workflow.md) — desktop systems, generators, tests, and pitfalls.

## The one-minute mental model

```text
main.dart
  -> ProviderScope
  -> AppBootstrap (Hive + desktop readiness + hydrated route-gate state)
  -> TawaqApp (theme + localization + router)
  -> GoRouter
      -> OnboardingScreen
      -> PageShell -> feature screen
```

`app/` composes the application, `core/` is feature-neutral reusable infrastructure, and `feature/*` owns product behavior. Layers inside a feature are pragmatic: add data, domain, or presentation separation only when it owns meaningful behavior.

## Fast orientation exercise

Read these files in order and follow their imports:

- [`lib/main.dart`](../../lib/main.dart)
- [`lib/app/routing/route_provider.dart`](../../lib/app/routing/route_provider.dart)
- [`lib/app/shell/page_shell.dart`](../../lib/app/shell/page_shell.dart)
- [`lib/core/bootstrap/app_init_providers.dart`](../../lib/core/bootstrap/app_init_providers.dart)
- [`lib/feature/prayer/presentation/provider/prayer_day.dart`](../../lib/feature/prayer/presentation/provider/prayer_day.dart)

Then use [Feature guides](05-feature-guides.md) to trace a feature from its screen inward.

## Source of truth

This documentation is an onboarding layer. The source code and [`AGENTS.md`](../../AGENTS.md) are authoritative; update this guide whenever system ownership or flow changes.
