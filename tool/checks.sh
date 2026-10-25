#!/usr/bin/env bash
# Locally: fvm exec bash tool/checks.sh. CI installs the .fvmrc SDK first.
set -euo pipefail
cd "$(dirname "$0")/.."
scope="${1:-all}"
case "$scope" in
  app|packages|all) ;;
  *) echo "Usage: $0 [app|packages|all]" >&2; exit 64 ;;
esac

# Per-stage timing: printed as it goes and, in CI, added to the job summary.
timings=()
stage_label=""
stage_start=$SECONDS
end_stage() {
  [[ -n "$stage_label" ]] || return 0
  local elapsed=$((SECONDS - stage_start))
  echo "==> $stage_label took ${elapsed}s"
  timings+=("$stage_label|$elapsed")
  stage_label=""
}
stage() {
  end_stage
  stage_label="$1"
  stage_start=$SECONDS
  echo "==> $1"
}
report_timings() {
  end_stage
  [[ -n "${GITHUB_STEP_SUMMARY:-}" && ${#timings[@]} -gt 0 ]] || return 0
  {
    echo "### checks.sh $scope"
    echo
    echo "| Stage | Seconds |"
    echo "| --- | ---: |"
    for entry in "${timings[@]}"; do echo "| ${entry%|*} | ${entry##*|} |"; done
    echo
  } >> "$GITHUB_STEP_SUMMARY" 2>/dev/null || true
  return 0
}
trap report_timings EXIT
if [[ "$scope" != packages ]]; then
  stage "app codegen"
  bash tool/codegen.sh
  stage "dart analyze"
  dart analyze
  stage "flutter analyze"
  flutter analyze --no-fatal-infos
  stage "flutter test"
  flutter test
  stage "release tool tests"
  python3 -m unittest discover -s tool/release -p 'test_*.py'
fi
if [[ "$scope" != app ]]; then
  stage "dorar_hadith"
  (
    cd packages/dorar_hadith
    # Keep the pinned upstream checkout; isolate the remaining default-disk client-use fixture.
    fixture_patch="../../tool/fixtures/dorar-test-storage.patch"
    if ! git apply --reverse --check "$fixture_patch" 2>/dev/null; then
      git apply --check "$fixture_patch"
      git apply "$fixture_patch"
    fi
    dart pub get
    dart analyze lib test
    dart test
  )
  stage "dorar_hadith_flutter"
  (
    cd packages/dorar_hadith/dorar_hadith_flutter
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
  stage "mushaf_reader"
  (
    cd packages/mushaf_reader
    flutter pub get --enforce-lockfile
    dart run build_runner build
    (cd example && flutter pub get && dart run slang)
    flutter analyze --no-fatal-infos
    flutter test
  )
  stage "hisn_elmoslem"
  (
    cd packages/hisn_elmoslem
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
  stage "adhan_dart"
  (
    cd packages/adhan_dart
    dart pub get
    dart analyze lib test
    # Offline prayer tests are required. The live Aladhan comparisons need the
    # network and run in prayer-api-validation.yml instead. The filter keeps them
    # out without editing the pinned submodule; upstream should tag them (see
    # tool/release/README.md).
    dart test --name '^(?!Prayer Times API Validation validates )'
  )
  stage "desktop_tray"
  (
    cd packages/desktop_tray
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
fi
