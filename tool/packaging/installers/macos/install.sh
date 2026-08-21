#!/usr/bin/env bash
set -euo pipefail

app_name='Tawaq.app'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_app="$script_dir/$app_name"
target_root="$HOME/Applications"
uninstall=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--system] [--uninstall]

Installs Tawaq for the current user in ~/Applications.

Options:
  --system     Install in /Applications instead. macOS will request an
               administrator password if one is required.
  --uninstall  Remove the selected Tawaq installation.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) target_root='/Applications' ;;
    --uninstall) uninstall=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

target_app="$target_root/$app_name"

remove_app() {
  if [[ ! -e "$target_app" ]]; then
    printf 'Tawaq is not installed in %s.\n' "$target_root"
    return
  fi

  if [[ "$target_root" == '/Applications' ]]; then
    sudo rm -rf "$target_app"
  else
    rm -rf "$target_app"
  fi
  printf 'Removed %s.\n' "$target_app"
}

if [[ $uninstall -eq 1 ]]; then
  remove_app
  exit 0
fi

[[ -d "$source_app" ]] || {
  printf 'Tawaq.app is missing beside this installer.\n' >&2
  exit 1
}

printf 'Installing Tawaq in %s\n' "$target_root"
if [[ "$target_root" == '/Applications' ]]; then
  sudo mkdir -p "$target_root"
  sudo rm -rf "$target_app"
  sudo ditto "$source_app" "$target_app"
else
  mkdir -p "$target_root"
  rm -rf "$target_app"
  ditto "$source_app" "$target_app"
fi

printf '%s\n' 'macOS marks downloaded apps with a quarantine flag.'
printf '%s\n' 'Removing it from this Tawaq copy lets you open the beta without the extra Finder step.'
if [[ "$target_root" == '/Applications' ]]; then
  sudo xattr -dr com.apple.quarantine "$target_app" 2>/dev/null || true
else
  xattr -dr com.apple.quarantine "$target_app" 2>/dev/null || true
fi

printf 'Installed Tawaq. Open it from %s.\n' "$target_app"
