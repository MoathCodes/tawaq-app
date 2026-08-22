#!/usr/bin/env bash
set -euo pipefail

app_name='tawaq'
display_name='Tawaq'
binary_name='Tawaq'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bundle_dir="$script_dir/app"
icon_dir="$script_dir/icons/hicolor"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
install_root="$HOME/.local/opt/$app_name"
desktop_dir="$data_home/applications"
desktop_file="$desktop_dir/$app_name.desktop"
icon_root="$data_home/icons/hicolor"
uninstall=0
skip_dependencies=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--uninstall] [--skip-dependencies]

Installs Tawaq for the current user. The app itself never needs sudo.

Options:
  --uninstall           Remove Tawaq, its launcher, and its installed icons.
  --skip-dependencies   Do not check for missing system libraries.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall) uninstall=1 ;;
    --skip-dependencies) skip_dependencies=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

remove_installation() {
  rm -rf "$install_root"
  rm -f "$desktop_file"
  find "$icon_root" -path '*/apps/tawaq.png' -delete 2>/dev/null || true
  update-desktop-database "$desktop_dir" 2>/dev/null || true
  printf 'Removed %s.\n' "$display_name"
}

detect_package_manager() {
  if command -v apt-get >/dev/null; then
    printf 'apt\n'
  elif command -v dnf >/dev/null; then
    printf 'dnf\n'
  elif command -v pacman >/dev/null; then
    printf 'pacman\n'
  elif command -v zypper >/dev/null; then
    printf 'zypper\n'
  else
    printf 'unknown\n'
  fi
}

missing_libraries() {
  local elf
  while IFS= read -r -d '' elf; do
    ldd "$elf" 2>/dev/null | awk '/=> not found/ { print $1 }'
  done < <(find "$bundle_dir" -type f \( -name "$binary_name" -o -name '*.so' \) -print0)
}

package_for_library() {
  local manager="$1"
  local library="$2"
  case "$library" in
    libgtk-3.so.0)
      case "$manager" in apt) printf 'libgtk-3-0\n' ;; *) printf 'gtk3\n' ;; esac ;;
    libayatana-appindicator3.so.1)
      case "$manager" in
        apt) printf 'libayatana-appindicator3-1\n' ;;
        dnf) printf 'libayatana-appindicator-gtk3\n' ;;
        pacman) printf 'libayatana-appindicator\n' ;;
        zypper) printf 'libayatana-appindicator3-1\n' ;;
      esac ;;
    libappindicator3.so.1)
      case "$manager" in
        apt) printf 'libappindicator3-1\n' ;;
        dnf) printf 'libappindicator-gtk3\n' ;;
        pacman) printf 'libappindicator-gtk3\n' ;;
        zypper) printf 'libappindicator3-1\n' ;;
      esac ;;
    libnotify.so.4)
      case "$manager" in apt) printf 'libnotify4\n' ;; *) printf 'libnotify\n' ;; esac ;;
    *) return 1 ;;
  esac
}

install_packages() {
  local manager="$1"
  shift
  case "$manager" in
    apt) sudo apt-get update -qq && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --needed --noconfirm "$@" ;;
    zypper) sudo zypper --non-interactive install "$@" ;;
  esac
}

ensure_dependencies() {
  local manager library package reply
  local -a packages=() unknown=()
  manager="$(detect_package_manager)"

  while IFS= read -r library; do
    [[ -n "$library" ]] || continue
    if package="$(package_for_library "$manager" "$library")"; then
      [[ " ${packages[*]} " == *" $package "* ]] || packages+=("$package")
    else
      [[ " ${unknown[*]} " == *" $library "* ]] || unknown+=("$library")
    fi
  done < <(missing_libraries | sort -u)

  if [[ ${#unknown[@]} -gt 0 ]]; then
    printf 'Tawaq is missing libraries without a safe package mapping: %s\n' "${unknown[*]}" >&2
    printf 'Install them through your distribution, then run this installer again.\n' >&2
    exit 1
  fi

  if [[ ${#packages[@]} -eq 0 ]]; then
    printf 'Runtime libraries are already available.\n'
    return
  fi

  if [[ "$manager" == 'unknown' ]]; then
    printf 'Missing runtime libraries: %s\n' "$(missing_libraries | sort -u | tr '\n' ' ')" >&2
    printf 'Tawaq could not detect a supported package manager.\n' >&2
    exit 1
  fi

  printf 'Tawaq needs these packages to load: %s\n' "${packages[*]}"
  read -r -p 'Install them now? [Y/n] ' reply < /dev/tty || reply='n'
  if [[ "$reply" =~ ^[Nn]$ ]]; then
    printf 'No packages were installed.\n' >&2
    exit 1
  fi
  command -v sudo >/dev/null || { printf 'sudo is required to install missing libraries.\n' >&2; exit 1; }
  install_packages "$manager" "${packages[@]}"
}

install_icons() {
  local icon size destination
  while IFS= read -r -d '' icon; do
    size="$(basename "$(dirname "$(dirname "$icon")")")"
    destination="$icon_root/$size/apps"
    mkdir -p "$destination"
    cp "$icon" "$destination/$app_name.png"
  done < <(find "$icon_dir" -path '*/apps/*.png' -print0)
}

if [[ $uninstall -eq 1 ]]; then
  remove_installation
  exit 0
fi

[[ -x "$bundle_dir/$binary_name" ]] || { printf 'The Tawaq bundle is missing.\n' >&2; exit 1; }
[[ -d "$icon_dir" ]] || { printf 'The Tawaq icons are missing.\n' >&2; exit 1; }

if [[ $skip_dependencies -eq 0 ]]; then
  ensure_dependencies
fi

mkdir -p "$(dirname "$install_root")"
temporary_root="$(mktemp -d "$(dirname "$install_root")/.${app_name}.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT
cp -R "$bundle_dir/." "$temporary_root/"
rm -rf "$install_root"
mv "$temporary_root" "$install_root"
trap - EXIT

install_icons
mkdir -p "$desktop_dir"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=$display_name
Comment=Prayer times, Quran, Hadith, and more
Exec=$install_root/$binary_name %U
Path=$install_root
Icon=$app_name
Terminal=false
Categories=Utility;Education;
StartupWMClass=Tawaq
EOF
update-desktop-database "$desktop_dir" 2>/dev/null || true
printf 'Installed %s. Launch it from your application menu.\n' "$display_name"
