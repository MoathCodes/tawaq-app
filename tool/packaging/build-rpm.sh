#!/usr/bin/env bash
set -euo pipefail

# Paths
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
VERSION=$(grep '^version:' "$ROOT/pubspec.yaml" | head -n1 | sed 's/version: //' | sed 's/+.*//' | tr -d '"' | tr -d "'")
BUILD_NUMBER="${BUILD_NUMBER:-1}"
PKG_NAME="tawaq"
ARCH="x86_64"
# RPM does not allow '-' in Version. A tilde is the conventional prerelease
# separator and keeps prereleases ordered before the corresponding stable build.
RPM_VERSION="${VERSION/-/\~}"
RPM_NAME="${PKG_NAME}-${RPM_VERSION}-${BUILD_NUMBER}.${ARCH}.rpm"

RPM_TOPDIR="$ROOT/dist/rpmbuild"
rm -rf "$RPM_TOPDIR"
mkdir -p "$RPM_TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS,BUILDROOT}

SPEC_FILE="$RPM_TOPDIR/SPECS/tawaq.spec"

cat > "$SPEC_FILE" <<EOF
Name:           $PKG_NAME
Version:        $RPM_VERSION
Release:        $BUILD_NUMBER
Summary:        Tawaq — Prayer times, Quran, Hadith, and Athkar
License:        MIT
URL:            https://github.com/MoathCodes/tawaq-app
AutoReqProv:    no
Requires:       gtk3, (libayatana-appindicator or libayatana-appindicator-gtk3 or libappindicator-gtk3), libnotify, mpv

%description
An all-in-one Islamic desktop companion with prayer times,
Quran reader, Hadith search, and Muslim Fortress (Hisn al-Muslim).

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/$PKG_NAME
cp -r $BUNDLE/* %{buildroot}/opt/$PKG_NAME/

mkdir -p %{buildroot}/usr/share/applications
cat > %{buildroot}/usr/share/applications/$PKG_NAME.desktop <<DESK
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
DESK

ICON_SRC="$ROOT/linux/icons/hicolor"
for size_dir in "\$ICON_SRC"/*/apps; do
  [ -d "\$size_dir" ] || continue
  size_label=\$(basename "\$(dirname "\$size_dir")")
  dest="%{buildroot}/usr/share/icons/hicolor/\$size_label/apps"
  mkdir -p "\$dest"
  cp "\$size_dir"/*.png "\$dest/"
done

%files
/opt/$PKG_NAME
/usr/share/applications/$PKG_NAME.desktop
/usr/share/icons/hicolor/*
EOF

rpmbuild --define "_topdir $RPM_TOPDIR" -bb "$SPEC_FILE"

# Copy generated RPM to dist/
mkdir -p "$ROOT/dist"
cp "$RPM_TOPDIR/RPMS/$ARCH/$RPM_NAME" "$ROOT/dist/$RPM_NAME"
echo "Built: dist/$RPM_NAME"
