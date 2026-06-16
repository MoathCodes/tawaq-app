#!/usr/bin/env bash
#
# adhan_clock.sh — temporarily move the system clock to test prayer alerts
# (adhan / iqamah / OS notifications), then resync it back via NTP.
#
# Linux + systemd only (uses `timedatectl`). Needs sudo for any clock change.
#
# How it works: the app derives "now" from the OS clock (TZDateTime.now), so
# nudging the system clock to just before a prayer time lets its 1 Hz tick cross
# the target live and fire the real alert pipeline. `reset` re-enables NTP, which
# resyncs the clock from the network.
#
# WARNING: this changes your *system* clock. While it is off-sync, TLS handshakes,
# cron jobs, file timestamps and other apps see the fake time. Always run `reset`
# when you are done (or just reboot).
#
# Usage:
#   tool/adhan_clock.sh status
#   tool/adhan_clock.sh at <HH:MM> [--lead <seconds>]   # default lead 70s BEFORE
#   tool/adhan_clock.sh set "<YYYY-MM-DD HH:MM:SS>"      # absolute local time
#   tool/adhan_clock.sh reset                            # re-enable NTP & resync
#
# Examples:
#   # Maghrib is 19:34 in the app. Land 70s before it and watch the adhan fire:
#   tool/adhan_clock.sh at 19:34
#
#   # Test the 20-min catch-up: land 5 min AFTER asr (15:10) — should still fire:
#   tool/adhan_clock.sh at 15:10 --lead -300
#
#   # Test that a stale alert is dropped: land 25 min after the prayer:
#   tool/adhan_clock.sh at 15:10 --lead -1500
#
#   tool/adhan_clock.sh reset

set -euo pipefail

LEAD_SECONDS=70

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_tools() {
  command -v timedatectl >/dev/null 2>&1 || die "timedatectl not found (systemd Linux only)."
  command -v date >/dev/null 2>&1 || die "date not found."
}

show_status() {
  echo "Current system time : $(date '+%Y-%m-%d %H:%M:%S %Z')"
  local ntp
  ntp=$(timedatectl show -p NTP --value 2>/dev/null || echo "?")
  echo "NTP synchronization : ${ntp}"
  if [[ "${ntp}" == "yes" ]]; then
    echo "  (clock is in sync / will be steered by NTP)"
  else
    echo "  (clock is FREE-RUNNING — run 'reset' to resync)"
  fi
}

apply_time() {
  # $1 = "YYYY-MM-DD HH:MM:SS"
  local stamp="$1"
  echo "Disabling NTP and setting clock to: ${stamp}"
  sudo timedatectl set-ntp false
  sudo timedatectl set-time "${stamp}"
  echo
  show_status
  echo
  echo "Make sure the app is running, then watch it cross the target."
  echo "Run 'tool/adhan_clock.sh reset' when finished."
}

cmd_at() {
  [[ $# -ge 1 ]] || die "usage: at <HH:MM> [--lead <seconds>]"
  local when="$1"; shift
  local lead="${LEAD_SECONDS}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lead) lead="${2:-}"; [[ -n "${lead}" ]] || die "--lead needs a value"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ "${lead}" =~ ^-?[0-9]+$ ]] || die "--lead must be an integer number of seconds"

  local target_epoch start_epoch stamp
  target_epoch=$(date -d "${when}" +%s) || die "could not parse time '${when}'"
  start_epoch=$((target_epoch - lead))
  stamp=$(date -d "@${start_epoch}" '+%Y-%m-%d %H:%M:%S')

  echo "Target prayer time  : $(date -d "@${target_epoch}" '+%Y-%m-%d %H:%M:%S')"
  echo "Lead                : ${lead}s ($([[ ${lead} -ge 0 ]] && echo before || echo after) the target)"
  apply_time "${stamp}"
}

cmd_set() {
  [[ $# -ge 1 ]] || die "usage: set \"<YYYY-MM-DD HH:MM:SS>\""
  date -d "$1" >/dev/null 2>&1 || die "could not parse time '$1'"
  apply_time "$(date -d "$1" '+%Y-%m-%d %H:%M:%S')"
}

cmd_reset() {
  echo "Re-enabling NTP (clock will resync from the network)..."
  sudo timedatectl set-ntp true
  # Give the time daemon a moment to steer the clock before reporting.
  sleep 2
  echo
  show_status
}

main() {
  require_tools
  local cmd="${1:-status}"; shift || true
  case "${cmd}" in
    status) show_status ;;
    at)     cmd_at "$@" ;;
    set)    cmd_set "$@" ;;
    reset)  cmd_reset ;;
    -h|--help|help) sed -n '2,40p' "$0" ;;
    *) die "unknown command '${cmd}' (try: status | at | set | reset | help)" ;;
  esac
}

main "$@"
