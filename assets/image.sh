#!/usr/bin/env bash
set -euo pipefail

# CONFIG
SRC_DIR="images"
PREFERRED_BACKUP="images_backup"
FALLBACK_BACKUP="images_backup_20250913232536"
QUALITY=80      # 50..70 recommended; adjust if artifacts visible
TARGET_SIZE=600 # final square size: TARGET_SIZExTARGET_SIZE
CWEBP_OPTS=(-m 6 -pass 10 -af -sns 30 -sharpness 0 -metadata none -mt)

# Prepare backup: prefer existing backups, otherwise create a new one and copy originals
if [ -d "$PREFERRED_BACKUP" ]; then
  BACKUP_DIR="$PREFERRED_BACKUP"
  echo "Using existing backup directory: $BACKUP_DIR"
elif [ -d "$FALLBACK_BACKUP" ]; then
  BACKUP_DIR="$FALLBACK_BACKUP"
  echo "Using existing fallback backup directory: $BACKUP_DIR"
else
  BACKUP_DIR="${SRC_DIR}_backup_$(date +%Y%m%d%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  cp "$SRC_DIR"/*.webp "$BACKUP_DIR"/ || true
  echo "Created new backup at $BACKUP_DIR"
fi

echo "Processing images in: $SRC_DIR"
echo "Backups are stored in: $BACKUP_DIR"
echo "Quality=$QUALITY, TARGET_SIZE=${TARGET_SIZE}x${TARGET_SIZE}"
echo

# helpers to get dimensions reliably
get_dims_webpinfo() {
  webpinfo "$1" 2>/dev/null | awk -F: '/Width:/ {w=$2} /Height:/ {h=$2} END {gsub(/^[ \t]+|[ \t]+$/, "", w); gsub(/^[ \t]+|[ \t]+$/, "", h); if (w==""||h=="") exit 1; print w, h}'
}

get_dims_identify() {
  identify -format "%w %h" "$1" 2>/dev/null || return 1
}

# check required tools
if ! command -v cwebp >/dev/null 2>&1; then
  echo "Error: cwebp not found. Install libwebp (cwebp)."
  exit 1
fi
if ! command -v convert >/dev/null 2>&1; then
  echo "Error: ImageMagick 'convert' not found. Install with: sudo apt install imagemagick"
  exit 1
fi

USE_WEBPINFO=0
if command -v webpinfo >/dev/null 2>&1; then
  USE_WEBPINFO=1
fi
if [ "$USE_WEBPINFO" -eq 0 ]; then
  echo "Note: webpinfo not found; falling back to ImageMagick identify for dimensions."
fi

for f in "$SRC_DIR"/*.webp; do
  [ -f "$f" ] || continue
  echo "Processing: $f"

  # get current dimensions
  if [ "$USE_WEBPINFO" -eq 1 ]; then
    if ! dims=$(get_dims_webpinfo "$f"); then
      echo "  webpinfo failed; trying identify..."
      dims=$(get_dims_identify "$f" 2>/dev/null) || dims=""
    fi
  else
    dims=$(get_dims_identify "$f" 2>/dev/null) || dims=""
  fi

  if [ -z "$dims" ]; then
    echo "  ERROR: Could not read dimensions for $f. Skipping."
    continue
  fi

  cur_w=$(echo "$dims" | awk '{print $1}')
  cur_h=$(echo "$dims" | awk '{print $2}')
  echo "  Current dims: ${cur_w}x${cur_h}"

  # compute square crop size (min dimension) and crop offsets (center)
  crop_size=$(( cur_w < cur_h ? cur_w : cur_h ))
  if [ "$crop_size" -le 0 ]; then
    echo "  ERROR: invalid crop size ($crop_size). Skipping."
    continue
  fi
  offset_x=$(( (cur_w - crop_size) / 2 ))
  offset_y=$(( (cur_h - crop_size) / 2 ))
  echo "  Cropping to square ${crop_size}x${crop_size} at offset ${offset_x},${offset_y}"

  tmp_png="${f%.webp}.crop.png"
  tmp_webp="${f%.webp}.tmp.webp"

  # Crop then resize to TARGET_SIZE (only downscale if crop_size > TARGET_SIZE)
  if [ "$crop_size" -gt "$TARGET_SIZE" ]; then
    # crop then resize down to TARGET_SIZE
    if ! convert "$f" -crop "${crop_size}x${crop_size}+${offset_x}+${offset_y}" +repage -resize "${TARGET_SIZE}x${TARGET_SIZE}" "$tmp_png"; then
      echo "  ERROR: convert failed during crop+resize. Skipping."
      rm -f "$tmp_png"
      continue
    fi
  else
    # crop only, do not upscale
    if ! convert "$f" -crop "${crop_size}x${crop_size}+${offset_x}+${offset_y}" +repage "$tmp_png"; then
      echo "  ERROR: convert failed during crop. Skipping."
      rm -f "$tmp_png"
      continue
    fi
  fi

  # Encode PNG -> WebP
  if ! cwebp -q "$QUALITY" "${CWEBP_OPTS[@]}" "$tmp_png" -o "$tmp_webp" >/dev/null 2>&1; then
    echo "  ERROR: cwebp failed. Cleaning tmp files and skipping."
    rm -f "$tmp_png" "$tmp_webp"
    continue
  fi

  if [ -f "$tmp_webp" ]; then
    new_size=$(stat -c%s "$tmp_webp" 2>/dev/null || echo "0")
    new_dims=$(identify -format "%w x %h" "$tmp_webp" 2>/dev/null || echo "unknown")
    echo "  Encoded -> ${new_size} bytes, dims: ${new_dims}"
    mv -f "$tmp_webp" "$f"
    echo "  Replaced original with ${TARGET_SIZE}x${TARGET_SIZE} (or smaller if original was smaller)."
  else
    echo "  ERROR: expected tmp webp not produced for $f"
  fi

  rm -f "$tmp_png"
  echo
done

echo "Done. Originals were backed up to: $BACKUP_DIR"
