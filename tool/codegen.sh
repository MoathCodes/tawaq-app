#!/usr/bin/env bash
# Generate code for path packages first, then the app.
#
# Root .gitignore ignores *.g.dart / *.freezed.dart, so vendored packages
# like mushaf_reader ship without generated sources. dorar_hadith commits
# its outputs in the submodule, but regenerating keeps drift/freezed in sync.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

run_pkg() {
  local dir="$1"
  echo "==> codegen ${dir}"
  (
    cd "${dir}"
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
  )
}

run_pkg packages/mushaf_reader
run_pkg packages/dorar_hadith

echo "==> codegen (app)"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
