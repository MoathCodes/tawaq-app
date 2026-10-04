#!/usr/bin/env bash
set -euo pipefail
package_dir="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
g++ -std=c++14 -Wall -Wextra -Werror \
  "$package_dir/linux/status_notifier_item.cc" \
  "$package_dir/linux/test/status_notifier_host.cc" \
  $(pkg-config --cflags --libs gtk+-3.0 dbusmenu-gtk3-0.4) \
  -o "$test_dir/tray-host"
GIO_USE_VFS=local dbus-run-session -- python3 "$package_dir/linux/test/status_notifier_test.py" \
  "$test_dir/tray-host" "${1:?Pass an absolute tray icon path}"
