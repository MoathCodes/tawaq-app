#!/usr/bin/env bash
# Run the pinned Flutter SDK with compiler scratch files on the home filesystem.
set -euo pipefail
tawaq_tmp_dir="${TAWAQ_FLUTTER_TMPDIR:-${XDG_CACHE_HOME:-$HOME/.cache}/tawaq/flutter-tmp}"
mkdir -p -- "$tawaq_tmp_dir"
export TMPDIR="$tawaq_tmp_dir"
exec fvm flutter "$@"
