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
