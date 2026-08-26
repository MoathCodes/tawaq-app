# Tawaq

Tawaq is a local-first Islamic companion built around trustworthy religious content, accurate time-sensitive behavior, and a fast, polished experience in Arabic and English.

## What Tawaq protects

### 1. Correctness earns trust

Religious text, prayer calculations, Arabic handling, and calendar behavior are product foundations. Preserve sourced religious text unless the task explicitly changes a display transformation. Keep source content separate from display and search normalization. Verify prayer and calendar changes in the configured timezone at relevant day boundaries.

Never invent a religious claim, translation, correction, or fallback. When repository data and an upstream authority disagree, present the evidence instead of silently choosing.

### 2. Performance and UX are product work

Tawaq exists because many alternatives accumulate features without finishing their accuracy, performance, or interaction quality. A feature that technically renders but feels slow, confusing, inconsistent, or unfinished is not done.

Performance claims require runtime evidence from the affected flow. Source inspection can identify a likely hot path, but it cannot prove an improvement.

### 3. Simple means coherent

Prefer a small sound model over both patchwork and architectural ceremony. State and business rules should have a clear owner. An abstraction earns its place by mapping, validating, caching, persisting, or coordinating real behavior.

### 4. Persisted state is durable product data

Preserve compatible decoding, hydration ordering, and required flush boundaries. Destructive schema or migration changes require explicit approval.

## A note from Moath

I like ambitious ideas, simple systems, and software that feels obvious. Do not preserve a weak foundation because the requested diff can be made small. Do not replace sound code with machinery that merely looks architecturally impressive.

Understand the real constraint, then choose the smallest complete design. Use a local fix when the existing model remains sound. Rewrite the affected subsystem when another patch would duplicate state, preserve contradictory rules, or add one more workaround. Measure twice, cut once. YAGNI still applies, and scope creep is not craftsmanship.

These instructions are strong defaults for navigating Tawaq. The developer can override them. Religious correctness and user-data integrity are hard guardrails; tested architecture contracts change together with their enforcing tests.

## How to get Tawaq wrong

1. **Feature slop.** Adding behavior without finishing its accuracy, integration, reachable states, and interaction details. A happy path is not a finished feature.
2. **False simplicity.** Choosing the smallest diff when it leaves conflicting owners, duplicated rules, or another workaround on a bad foundation.
3. **Untraced fan-out.** Changing a shared source, provider, model, or widget without accounting for the consumers and derived behavior that depend on it.

## Work from evidence

- Start at the owner of the behavior. Read the affected source, its nearest tests, and the configuration or script that controls it before editing.
- For dependency behavior, inspect `pubspec.yaml`, `pubspec.lock`, and the resolved source. Read path dependencies from their local checkout and submodules from their checked-out revision before using matching maintainer documentation.
- Trace the fan-out according to the thing being changed. Every affected consumer should be updated, shown compatible, or named as intentionally unaffected. This includes derived providers and app or desktop services when they consume the same state.
- Derive applicable loading, empty, error, disabled, and recovery states from the owning provider or controller. Finish the states the flow can reach. A checklist is not a reason to invent state machinery.
- For shared UI, inspect representative consumers across the layouts, locales, themes, and input modes the change can affect. Screen-local UI normally stops at that screen.
- Preserve unrelated work already in the tree. Check `git status` and the relevant diff before and after the task.

## Architecture

Runtime composition starts at `lib/main.dart`. `lib/app/` owns routing, shell, onboarding composition, and desktop integration. `lib/core/` contains feature-neutral infrastructure. Feature behavior lives under `lib/feature/<name>/`; add only the data, domain, or presentation layers that perform useful work. In-repository dependencies live under `packages/`.

`test/architecture/dependency_boundaries_test.dart` is the import contract. Read it before moving code or adding a cross-layer or cross-feature dependency. Its exception list is a shrinking record of existing violations, not permission for new ones. Remove an exception when its violation is repaired.

Reach for these contracts only when their branch applies:

- **Live prayer, calendar, or alert behavior:** start with `lib/core/utils/app_clock_provider.dart`, `lib/feature/prayer/presentation/provider/prayer_day.dart`, and the domain rules in `lib/feature/prayer/domain/`. Override the shared clock in time-dependent tests.
- **Quran recitation or shared audio:** read `test/architecture/recitation_session_boundary_test.dart`, `lib/feature/quran/domain/recitation/recitation_session.dart`, and `lib/core/audio/`. `RecitationSession` owns logical playback state; framework and native integrations are adapters.
- **Persisted settings or onboarding completion:** read `lib/core/storage/settings_storage.dart`, `test/feature/settings/settings_storage_gate_test.dart`, and `test/feature/onboarding/onboarding_finish_flush_order_test.dart`. `persist(...).future` waits for hydration; durable kill-boundary writes use the established flush path.
- **Arabic search or parsed display text:** use `normalizeArabicForSearch` from `lib/core/text/arabic_search_normalize.dart` symmetrically on queries and candidates. `ArabicTextNormalizer` in `lib/core/text/arabic_text_normalizer.dart` is for display typography. Keep aligned package-local search copies in sync when folding rules change.
- **Recitation, sharing, or distribution terminology:** read `CONTEXT.md` before changing those contracts.

## Generated code and commands

The project SDK is pinned by `.fvmrc`; run Flutter and Dart commands through FVM. Initialize submodules after cloning with `git submodule update --init --recursive`.

- Full or fresh-clone generation: `fvm exec bash tool/codegen.sh`
- Root-only generator inputs: `fvm dart run build_runner build`
- ARB localization changes: `fvm flutter gen-l10n`

Change generator inputs rather than generated Dart files. Include tracked localization, FlutterGen, and Hive metadata outputs when regeneration changes them.

Root analysis excludes `packages/**`. A changed local package needs its own analyzer and tests from that package directory, in addition to relevant app checks.

## Finishing work

Run the narrowest test that proves the behavior while iterating. Add regression coverage for fixes and new domain behavior. Use runtime inspection for UI-critical changes and comparable before-and-after measurements for performance work, scoped to the affected flow.

Run full app analysis and tests when a change affects shared core or app composition, crosses features, changes persistence, prayer or calendar rules, recitation or shared audio, code generation, a local package boundary, or release-bound behavior:

```bash
fvm flutter analyze --no-fatal-infos
fvm flutter test
```

Before handing off, inspect the final diff. Report the behavior changed, fan-out considered, generation performed, checks run, and any limitation. The task is complete when the requested behavior, every affected consumer, reachable states, tests, and generated outputs agree without feature slop.
