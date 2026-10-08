#!/usr/bin/env bash
# Locally: fvm exec bash tool/checks.sh. CI installs the .fvmrc SDK first.
set -euo pipefail
cd "$(dirname "$0")/.."
scope="${1:-all}"
case "$scope" in
  app|packages|all) ;;
  *) echo "Usage: $0 [app|packages|all]" >&2; exit 64 ;;
esac
if [[ "$scope" != packages ]]; then
  bash tool/codegen.sh
  dart analyze
  flutter analyze --no-fatal-infos
  flutter test
  python3 -m unittest discover -s tool/release -p 'test_*.py'
fi
if [[ "$scope" != app ]]; then
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
  (
    cd packages/dorar_hadith/dorar_hadith_flutter
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
  (
    cd packages/mushaf_reader
    flutter pub get --enforce-lockfile
    dart run build_runner build
    (cd example && flutter pub get && dart run slang)
    flutter analyze --no-fatal-infos
    flutter test
  )
  (
    cd packages/hisn_elmoslem
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
  (
    cd packages/adhan_dart
    dart pub get
    dart analyze lib test
    dart test
  )
  (
    cd packages/desktop_tray
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
  )
fi
