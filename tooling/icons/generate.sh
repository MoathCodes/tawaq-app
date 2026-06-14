#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! python3 -c "import PIL, yaml" 2>/dev/null; then
  python3 -m pip install --user -r requirements.txt
fi

python3 render.py "$@"
