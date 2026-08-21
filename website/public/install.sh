#!/usr/bin/env bash
set -euo pipefail

repo='MoathCodes/tawaq-app'
api="https://api.github.com/repos/$repo/releases"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

fail() {
  printf 'Tawaq install failed: %s\n' "$1" >&2
  exit 1
}

asset_url() {
  local expression="$1"
  printf '%s' "$release_json" | grep -oE 'https://[^"[:space:]]+' | grep -E "$expression" | head -n 1
}

checksum() {
  local file="$1"
  local expected actual
  expected="$(curl -fsSL "$checksums_url" | awk -v file="$file" '$2 == file { print $1; exit }')"
  [[ -n "$expected" ]] || fail "No checksum was published for $file."
  if command -v shasum >/dev/null; then
    actual="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
  else
    actual="$(sha256sum "$archive_path" | awk '{print $1}')"
  fi
  [[ "$expected" == "$actual" ]] || fail 'The downloaded archive did not match its published checksum.'
}

release_json="$(curl -fsSL "$api?per_page=20")" || fail 'Could not reach the Tawaq release service.'
checksums_url="$(asset_url '/SHA256SUMS$')"
[[ -n "$checksums_url" ]] || fail 'The latest Tawaq release has no SHA256SUMS file.'

case "$(uname -s):$(uname -m)" in
  Darwin:arm64) asset_expression='/tawaq-[^/]*-macos-arm64-installer\.zip$' ;;
  Darwin:x86_64) asset_expression='/tawaq-[^/]*-macos-x64-installer\.zip$' ;;
  Linux:x86_64) asset_expression='/tawaq-[^/]*-linux-x64\.zip$' ;;
  *) fail "Unsupported platform: $(uname -s) $(uname -m)" ;;
esac

download_url="$(asset_url "$asset_expression")"
[[ -n "$download_url" ]] || fail 'No matching Tawaq installer archive was found in the latest beta release.'
archive_name="${download_url##*/}"
archive_path="$temporary_dir/$archive_name"

printf 'Downloading %s\n' "$archive_name"
curl -fL --retry 3 --retry-delay 1 "$download_url" -o "$archive_path" || fail 'Could not download the installer archive.'
checksum "$archive_name"
printf 'Verified the release checksum.\n'

extract_dir="$temporary_dir/extracted"
mkdir -p "$extract_dir"
if [[ "$(uname -s)" == 'Darwin' ]]; then
  ditto -x -k "$archive_path" "$extract_dir"
else
  command -v unzip >/dev/null || fail 'Install unzip, then run this command again.'
  unzip -q "$archive_path" -d "$extract_dir"
fi

installer="$(find "$extract_dir" -type f -name install.sh -print -quit)"
[[ -n "$installer" ]] || fail 'The installer archive has no install.sh file.'
chmod +x "$installer"
exec "$installer" "$@"
