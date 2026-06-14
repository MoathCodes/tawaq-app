#!/usr/bin/env bash
# Precompile surah header SVGs to .svg.vec for runtime loading via flutter_svg.
# Re-run after editing sources in tool/svg/.
set -euo pipefail

cd "$(dirname "$0")/.."

compile() {
  local input=$1
  local output=$2
  dart run vector_graphics_compiler \
    -i "$input" \
    -o "$output" \
    --no-optimize-masks \
    --no-optimize-clips \
    --no-optimize-overdraw
}

mkdir -p assets/images

compile tool/svg/surah-header.svg assets/images/surah-header.svg.vec
compile tool/svg/surah-header-dark.svg assets/images/surah-header-dark.svg.vec

echo "Compiled surah header assets to assets/images/*.svg.vec"
