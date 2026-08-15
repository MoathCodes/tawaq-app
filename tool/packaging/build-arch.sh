#!/usr/bin/env bash
set -euo pipefail

# Paths
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
VERSION=$(grep '^version:' "$ROOT/pubspec.yaml" | head -n1 | sed 's/version: //' | sed 's/+.*//' | tr -d '"' | tr -d "'")
BUILD_NUMBER="${BUILD_NUMBER:-1}"
PKG_NAME="tawaq"
ARCH="x86_64"
# Arch reserves '-' for the pkgver/pkgrel separator.
ARCH_VERSION="${VERSION//-/.}"
PKG_FULL_NAME="${PKG_NAME}-${ARCH_VERSION}-${BUILD_NUMBER}-${ARCH}.pkg.tar.zst"

STAGING="$ROOT/dist/arch-staging"
rm -rf "$STAGING"

# Application files -> opt/tawaq/
APP_DIR="$STAGING/opt/$PKG_NAME"
mkdir -p "$APP_DIR"
cp -r "$BUNDLE/." "$APP_DIR/"

# Desktop entry -> usr/share/applications/
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

# Icons -> usr/share/icons/hicolor/
ICON_SRC="$ROOT/linux/icons/hicolor"
for size_dir in "$ICON_SRC"/*/apps; do
  [ -d "$size_dir" ] || continue
  size_label=$(basename "$(dirname "$size_dir")")
  dest="$STAGING/usr/share/icons/hicolor/$size_label/apps"
  mkdir -p "$dest"
  cp "$size_dir"/*.png "$dest/"
done

# Fix permissions
find "$STAGING/opt" -type f -executable -exec chmod 755 {} +
find "$STAGING/opt" -type f ! -executable -exec chmod 644 {} +
find "$STAGING/usr" -type f -exec chmod 644 {} +
chmod 755 "$APP_DIR/Tawaq"  # main executable

# Installed size in bytes
INSTALLED_SIZE=$(du -sb "$STAGING" | awk '{print $1}')
BUILD_DATE=$(date -u +%s)

# .PKGINFO metadata file
cat > "$STAGING/.PKGINFO" <<EOF
pkgname = $PKG_NAME
pkgver = ${ARCH_VERSION}-${BUILD_NUMBER}
pkgdesc = Tawaq — Prayer times, Quran, Hadith, and Athkar
url = https://github.com/MoathCodes/tawaq-app
builddate = $BUILD_DATE
packager = Moath <moath@moathdev.me>
size = $INSTALLED_SIZE
arch = $ARCH
license = MIT
depend = gtk3
depend = libayatana-appindicator
depend = libnotify
depend = mpv
EOF

# Build the .pkg.tar.zst package
mkdir -p "$ROOT/dist"
(
  cd "$STAGING"
  # tar with zstd compression
  tar --owner=0 --group=0 -c -f - .PKGINFO opt usr | zstd -c -z -q -19 - > "$ROOT/dist/$PKG_FULL_NAME"
)

echo "Built: dist/$PKG_FULL_NAME"
