# Faster desktop betas

**Date:** 2026-10-25 · **Status:** proposed, not built yet

## The problem

Sharing a Windows beta takes too long. Every beta re-runs all checks, recompiles, and waits on platforms nobody asked for.

## What we want

- **Merging a PR** runs the normal checks. Nothing else. No installer, no version bump, no release.
- **Making a beta** is a manual button in GitHub Actions. Pick a commit and a platform (Windows by default). It builds and saves the installer for 30 days. Nothing is published yet.
- **Sharing a beta** is a second manual button. Pick the build, and it publishes that exact installer as a GitHub prerelease. No rebuild, no re-test. Your friend gets a normal download link.
- **Stable releases** stay exactly as they are today.

## Why it's slow today

| Where | Time lost |
| --- | --- |
| Check job ([run 40223436629](https://github.com/MoathCodes/tawaq-app/actions/runs/40223436629)) | ~10.5 min |
| Windows setup before compiling ([run 40221774493](https://github.com/MoathCodes/tawaq-app/actions/runs/40221774493)) | ~9 min, including 2 min 17 s just for Shorebird |
| Desktop workflow runs checks one after another, then waits before compiling | adds up both |

Other notes:

- `quality.yml` already runs checks in parallel. The desktop workflow doesn't.
- Live Aladhan API tests time out locally when offline. Offline prayer tests pass. It's a network problem, not a prayer-math bug.
- The fix that builds Windows with plain Flutter (no Shorebird) is on `release/1.0.0-beta.9` (commit `7b777ab1`), not `main`. Bring it over; don't write it twice.

## The plan

### 0. Quick wins (do first, independent of the rest)

- Cache pub package downloads, keyed on OS, pinned SDK, and lockfiles. Keep Flutter SDK caching and check it actually hits. An empty cache must still work.
- Move live Aladhan API tests out of required checks into their own scheduled job with network timeouts. An outage should show as an outage, not a failing prayer check. Keep the offline prayer and calendar tests required. Never loosen prayer assertions to make CI green. If this changes tests inside a submodule, that needs an upstream change and a pinned revision bump.

### 1. Make beta builds manual only

- The desktop workflow owns beta builds. Manual trigger only, with platform choice.
- `quality.yml` keeps running on PRs and pushes to `main`. It never makes an installer.
- Make sure publishing a beta can't accidentally start a full stable release.
- Keep PR check names the same, or update branch protection with the change.

### 2. Don't re-run checks that already passed

- If checks already passed **for that exact commit**, skip them and build.
- If they're still running, start building and wait for them to finish.
- If there are none, run them alongside the build (not before it).
- A different commit can never reuse another commit's results.
- If you skip checks on purpose, the build is marked **unchecked**, and the normal publish button refuses it.
- Ordinary betas use plain Flutter. No Shorebird install or login. A plain-Flutter beta can't be Shorebird-patched, and shouldn't claim it can.

### 3. Give every build a fixed version up front

- Version = base from `pubspec.yaml` + the workflow run number, e.g. `1.0.0-beta.16+16`.
- Check this never goes backwards compared to already-published builds.
- A retry keeps the same version. A published version is never overwritten.
- No "bump version" commits just to share a build.
- Each build saves a small record (a manifest): commit, version, platform, SDK, lockfile hashes, file checksums, and which check run it relied on.

### 4. Add the publish button

- Input: one exact build run ID. Never "latest".
- It checks that the build is from this repo, succeeded, passed checks, hasn't expired, and its files match their checksums.
- It uploads to a private draft first, re-downloads to confirm the files match, then makes it public.
- It refuses duplicates, mismatched files, or a tag that doesn't match the built version.
- Only this job gets permission to write releases.
- If the saved build expired (after 30 days), it tells you to build again.

### 5. Cache build outputs (later, only if measured)

- Don't cache `.dart_tool` or generated code until timing shows it's worth it. It's the easiest way to get stale builds.
- If you do, first list everything that should invalidate it: generator versions, sources, config, assets, localization files. Keep clean-build comparisons.

### 6. Measure it

- Time each step (checkout, setup, generate, test, compile, package, publish) over three runs, before and after.
- Goals to check, not promises:
  - Publishing a saved installer takes under 2 minutes.
  - Building a beta is faster than today.
  - Publishing runs zero tests or compiles.

## Done when

- [ ] Merging a PR makes no installer, version, tag, or release.
- [ ] A manual Windows build reuses passed checks for the same commit, and runs missing ones in parallel.
- [ ] A published installer is byte-for-byte the one that was built.
- [ ] Failed, pending, or skipped checks block publishing.
- [ ] A new commit can't borrow an old commit's green checks.
- [ ] PR builds and other repos' builds can't be published as betas.
- [ ] Expired or tampered files fail with a clear message.
- [ ] Two publishes of the same version can't overwrite each other.
- [ ] Stable releases and Shorebird patches work as before.
- [ ] A beta builds without Shorebird credentials.
- [ ] The installer is tested on real Windows: fresh install, launch, version shown, upgrade keeps saved data. Recorded separately from "it compiled".

## Files that change

- `.github/workflows/quality.yml`, `.github/workflows/build-desktop.yml`, new publish workflow
- `tool/checks.sh`, `tool/codegen.sh`, `tool/set_pubspec_version.dart`
- `tool/release/record_toolchain.py`, `tool/release/publish_assets.py`, release validators, `tool/release/README.md`
- `test/tool/release_workflow_test.dart` and the Python release-tool tests
- README download links: don't show links for platforms a Windows-only beta doesn't include.

## Order

1. Quick wins: package caching and moving the live API tests.
2. Manual builds and check reuse.
3. Publish button.
4. Build-output caching, only if measurements justify it.

Try the publish flow on a private draft before the first public beta.

**Not doing:** self-hosted runners, skipping tests, a custom release service, or an in-app updater rewrite.
