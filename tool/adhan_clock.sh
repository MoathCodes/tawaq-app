#!/usr/bin/env bash
#
# Temporarily set the system clock to test prayer alerts, then reset via NTP.
# Linux + systemd only. Needs sudo.
#
# Usage:
#   tool/adhan_clock.sh set 8:20 PM
#   tool/adhan_clock.sh set 20:20
#   tool/adhan_clock.sh reset
#
# WARNING: changes your system clock. Run reset when done.

set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_tools() {
  command -v timedatectl >/dev/null 2>&1 || die "timedatectl not found (systemd Linux only)."
  command -v date >/dev/null 2>&1 || die "date not found."
}

cmd_set() {
  [[ $# -ge 1 ]] || die "usage: set <time>   e.g. set 8:20 PM"
  local input="$*"
  date -d "${input}" >/dev/null 2>&1 || die "could not parse time: ${input}"
  local stamp
  stamp=$(date -d "${input}" '+%Y-%m-%d %H:%M:%S')
  sudo timedatectl set-ntp false
  sudo timedatectl set-time "${stamp}"
  printf 'clock set to %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
}

cmd_reset() {
  sudo timedatectl set-ntp true

  # set-ntp only enables the daemon; it won't jump a large manual offset on its
  # own. chrony also won't step until it trusts a source, and right after a
  # restart it has no measurements — so a bare `makestep` is a no-op. Force a
  # burst of polls first, then step.
  if command -v chronyc >/dev/null 2>&1 && systemctl is-active --quiet chronyd; then
    sudo chronyc burst 4/4 >/dev/null 2>&1 || true
    sleep 8
    sudo chronyc makestep >/dev/null 2>&1 || true
  elif systemctl is-active --quiet systemd-timesyncd; then
    sudo systemctl restart systemd-timesyncd
  fi

  # Wait (up to ~20s) for the clock to actually report synchronized.
  local i
  for i in $(seq 1 20); do
    [[ "$(timedatectl show -p NTPSynchronized --value)" == "yes" ]] && break
    sleep 1
  done

  local now
  now="$(date '+%Y-%m-%d %H:%M:%S %Z')"
  if [[ "$(timedatectl show -p NTPSynchronized --value)" == "yes" ]]; then
    printf 'clock reset (NTP synced): %s\n' "${now}"
  elif [[ "$(timedatectl show -p NTP --value)" == "yes" ]]; then
    # The clock has been stepped and NTP is on; the 'synchronized' flag just
    # lags (chrony needs sustained samples, esp. with one time source). Not a
    # failure — the time above is already correct.
    printf 'clock reset (NTP on; sync flag may take ~1 min to flip): %s\n' "${now}"
  else
    printf 'reset failed: NTP is not active: %s\n' "${now}" >&2
    printf 'try: sudo timedatectl set-ntp true\n' >&2
  fi
}

main() {
  require_tools
  local cmd="${1:-}"; shift || true
  case "${cmd}" in
    set)   cmd_set "$@" ;;
    reset) cmd_reset ;;
    *)
      die "usage: $(basename "$0") set <time> | reset"
      ;;
  esac
}

main "$@"
