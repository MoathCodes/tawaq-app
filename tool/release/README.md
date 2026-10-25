# Desktop releases

Stable releases and Shorebird patches use the coordinated pipeline below. Test
betas use the faster path in [Beta installers](#beta-installers); the two never
share a gate, a tag filter or a permission.

# Coordinated desktop release

Run `fvm exec bash tool/checks.sh all` before building a candidate. The workflow
uses that same script. Run the desktop workflow with `action=build` first: it
builds and packages artifacts without publishing a Shorebird release or patch.
Single-platform builds are for investigation; publication requires Linux x64,
Windows x64, and macOS arm64/x64 together.

Each candidate includes `toolchain-<platform>.json`. It records the resolved
Flutter/Dart versions, Shorebird and packaging tool versions, dependency-lock
hashes, submodule revisions, source commit and package build identity. Recording
fails if Flutter differs from `.fvmrc` or source/generation differs from the
commit, except the workflow's deliberate `pubspec.yaml` version update.
Review these actual versions rather than assuming mutable setup actions or
package managers installed the same tools as a previous build.

Complete RC-01 through RC-16 from the launch specification on each architecture.
Record the OS, evidence links, signing/install policy and each scenario's result.
A Linux screenshot does not establish Windows/macOS acceptance. Confirm the
`coordinated-desktop-release` GitHub environment has required human reviewers;
the repository workflow cannot configure or prove that account setting.

The native acceptance JSON must contain:

- `candidate_sha`: exact 40-character commit; `sdk`: pinned Flutter version.
- `build_name` and `build_number`: the version actually tested in the artifacts.
- `action`: `release` or `patch`; patches also require the exact reviewed
  `release_version`, including build number. A moving `latest` target is refused.
- `distribution_policy_approved: true`: after real signing/install review.
- `platforms`: `linux-x64`, `windows-x64`, `macos-arm64`, `macos-x64`, each with
  `os`, `evidence`, `passed: true` and all 16 `scenarios` set to `passed`.
- `artifacts`: unique filenames, HTTPS staging URLs and SHA-256 hashes for the
  nine installer/archive outputs and four toolchain records.

See `test_validate_acceptance.py` for the structural fixture. Its placeholder
URLs and pass values are test data, never native acceptance evidence. The
validator downloads and hashes the actual files and checks their toolchain
identity. Supply the reviewed record to the manual release or patch workflow.
A tag push without a reviewed record fails closed.

GitHub publishing creates a private draft, uploads the exact reviewed files,
downloads them again, and verifies both artifact and metadata bytes before
making the release public. An existing release or partial draft is refused.
No candidate binary is substituted with a later rebuild during GitHub upload.
Shorebird commands also wait for checks and native acceptance, but publication
across Shorebird platforms and GitHub is not atomic.

## Partial publication

Do not announce a release until all services and every public download have
been checked. Keep the reviewed manifest and workflow logs. On failure:

1. Stop the workflow's remaining side effects. Identify which Shorebird
   platforms/releases/patches actually succeeded and whether GitHub is still a
   draft. Do not blindly rerun a partially successful distribution action.
2. Leave an incomplete GitHub draft private. If GitHub became public, withdraw
   public visibility before announcement while preserving the manifest/logs.
3. Review the applicable Shorebird withdrawal/rollback controls and installed
   client impact for the exact release or patch. Obtain the separate product
   authorization before changing a live release; a repository script does not
   authorize rollback of user installations.
4. Either complete the missing outputs from the same reviewed revision/build,
   or withdraw the partial publication. Rebuilds require new checksums and native
   review. Record that decision, then independently verify all download bytes
   and installed version displays before announcing.

The current macOS packaging remains ad-hoc signed. Its beta quarantine-removal
instructions are not proof of public signing/notarization readiness. Windows
signing and clean-machine installer behavior also remain native release gates.

## Beta installers

A beta is one installer built from one commit, saved for 30 days, and published
later without being rebuilt. Merging a PR runs only the Quality checks: no
installer, version, tag or release.

**Build:** Actions → Build desktop → Run workflow on the branch or tag to build →
`action: beta`. The workflow builds the tip of that ref (Windows only for now).

- Version is fixed before the build: the `pubspec.yaml` base without any
  prerelease or build suffix, plus `-beta.<run number>` and `+<run number>`
  (`1.0.0-beta.16+16`). It is passed to `flutter build`, never written to
  `pubspec.yaml`, so the working tree stays clean and a retry keeps the same
  version. The build fails if a published or draft release already has that
  version or a newer one.
- Plain Flutter only: no Shorebird install, login or secrets. A beta cannot be
  Shorebird-patched.
- Checks (`beta_checks`): `auto` reuses a passed Quality run **push** on `main` for
  exactly this commit, waits for one that is still running, or runs the same
  checks in parallel with the build. Pull request runs never count: they tested a
  merge with `main`, not this commit. `skip` marks the build unchecked.
- The run is green only if the build and its checks are green.
- `beta-manifest.json` is saved beside the installer: commit, version, platform,
  toolchain (SDK, tool versions, lockfile hashes, submodule revisions), file
  SHA-256 and sizes, and which checks were relied on.

**Publish:** Actions → Publish beta → give the exact build run ID (the number in
the run URL). It refuses a run that is not a successful manual Build desktop run
of this repository, an expired or missing saved build, changed files, an
unchecked build or failed/pending checks, an existing release or draft with the
same tag, and a version at or below one already published. Then it uploads to a
private draft, downloads it again to compare bytes, and only then makes it a
prerelease (never "latest"). It runs no tests and no compiler.

- `mode: rehearse` (the default) does everything except making the release
  public, then deletes the private draft. Rehearse once before the first public
  beta; use `publish` for the real one.
- Published files: the installer, `SHA256SUMS-windows-x64` and
  `beta-manifest.json`. The checksum file is deliberately not `SHA256SUMS`:
  `website/public/install.sh` takes the first release with that name and the
  matching macOS or Linux archive, so a Windows-only beta must not match.
- A failed upload or readback deletes its own draft so the retry is not blocked.
- An expired build says so; run Build desktop again and publish the new run.

Windows needs real-machine acceptance separately from "it compiled": fresh
install, launch, version shown, and upgrade keeping saved data.

## Live prayer API validation

`packages/adhan_dart/test/api_validation_test.dart` compares against the live
Aladhan API. `tool/checks.sh` excludes its four network tests by name so offline
prayer tests stay required, and `prayer-api-validation.yml` runs them weekly with
timeouts. An Aladhan outage fails the "Aladhan API is reachable" step, not a
prayer check.

The submodule was not edited. Upstream, tag those tests (`@Tags(['live'])` with a
`dart_test.yaml` entry) so both sides can use `--exclude-tags live` and
`--tags live`; then bump the pinned revision and drop the name filter.

## Timing

Each step's duration is in the Actions UI. `python3 tool/release/run_timings.py
--repo OWNER/REPO --run-id ID` prints every job and step as a table for
before/after comparisons, `checks.sh` adds a per-stage table to the job summary,
and the setup action reports whether the Flutter SDK and pub caches hit.
