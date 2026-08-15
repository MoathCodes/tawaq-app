#!/usr/bin/env bash
set -euo pipefail

# Paths
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
VERSION=$(grep '^version:' "$ROOT/pubspec.yaml" | head -n1 | sed 's/version: //' | sed 's/+.*//' | tr -d '"' | tr -d "'")
BUILD_NUMBER="${BUILD_NUMBER:-1}"
PKG_NAME="tawaq"
ARCH="amd64"
DEB_NAME="${PKG_NAME}_${VERSION}-${BUILD_NUMBER}_${ARCH}.deb"

STAGING="$ROOT/dist/deb-staging"
rm -rf "$STAGING"

# Application files -> /opt/tawaq/
APP_DIR="$STAGING/opt/$PKG_NAME"
mkdir -p "$APP_DIR"
cp -r "$BUNDLE/." "$APP_DIR/"

# Desktop entry -> /usr/share/applications/
DESKTOP_DIR="$STAGING/usr/share/applications"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/$PKG_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Tawaq
GenericName=Tawaq
Comment=Prayer times, Quran, Hadith, and more
Exec=/opt/$PKG_NAME/Tawaq %U
Icon=$PKG_NAME
Terminal=false
StartupNotify=true
Categories=Utility;Education;
StartupWMClass=Tawaq
EOF

# Icons -> /usr/share/icons/hicolor/
ICON_SRC="$ROOT/linux/icons/hicolor"
for size_dir in "$ICON_SRC"/*/apps; do
  [ -d "$size_dir" ] || continue
  size_label=$(basename "$(dirname "$size_dir")")
  dest="$STAGING/usr/share/icons/hicolor/$size_label/apps"
  mkdir -p "$dest"
  cp "$size_dir"/*.png "$dest/"
done

# DEBIAN/control
mkdir -p "$STAGING/DEBIAN"
cat > "$STAGING/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: ${VERSION}-${BUILD_NUMBER}
Section: utils
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libayatana-appindicator3-1 | libappindicator3-1, libnotify4, mpv
Maintainer: Moath <moath@moathdev.me>
Description: Tawaq — Prayer times, Quran, Hadith, and Athkar
 An all-in-one Islamic desktop companion with prayer times,
 Quran reader, Hadith search, and Muslim Fortress (Hisn al-Muslim).
EOF

# Fix permissions
find "$STAGING/opt" -type f -executable -exec chmod 755 {} +
find "$STAGING/opt" -type f ! -executable -exec chmod 644 {} +
find "$STAGING/usr" -type f -exec chmod 644 {} +
chmod 755 "$APP_DIR/Tawaq"  # main executable

# Build the .deb
mkdir -p "$ROOT/dist"
dpkg-deb --build --root-owner-group "$STAGING" "$ROOT/dist/$DEB_NAME"
echo "Built: dist/$DEB_NAME"
