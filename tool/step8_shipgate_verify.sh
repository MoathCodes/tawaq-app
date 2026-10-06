#!/usr/bin/env bash
# Compatibility entry point. Preserve every failed stage without repeating it.
set -euo pipefail
exec bash "$(dirname "$0")/checks.sh" all
