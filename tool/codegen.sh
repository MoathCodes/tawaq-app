#!/usr/bin/env bash
# Generate code for path packages first, then the app.
#
# Root .gitignore ignores *.g.dart / *.freezed.dart, so vendored packages ship
# without generated sources and must be built before the app can compile.
# dorar_hadith is skipped: it is a submodule that commits its own outputs.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

echo "==> codegen packages/mushaf_reader"
(
  cd packages/mushaf_reader
  flutter pub get
  dart run build_runner build
)

echo "==> codegen (app)"
flutter pub get
dart run build_runner build
