#!/usr/bin/env python3
"""Sample only an exact owned Linux executable; do not substitute PSS for RSS."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import time
import subprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--executable', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    executable = Path(args.executable).resolve()
    deadline = time.monotonic() + 15
    process = None
    while time.monotonic() < deadline:
        matches = []
        for entry in Path('/proc').iterdir():
            if not entry.name.isdigit():
                continue
            try:
                if (entry / 'exe').resolve(strict=True) == executable:
                    matches.append(entry)
            except (OSError, RuntimeError):
                pass
        if len(matches) > 1:
            raise RuntimeError('Ambiguous benchmark process')
        if matches:
            process = matches[0]
            break
        time.sleep(.05)
    if process is None:
        raise RuntimeError('The exact benchmark executable did not start')
    started = (process / 'stat').read_text().split()[21]
    geometry = {}
    sample = 0
    with Path(args.output).open('w') as output:
        while True:
            try:
                if (process / 'exe').resolve(strict=True) != executable or (process / 'stat').read_text().split()[21] != started:
                    break
                if sample % 5 == 0:
                    try:
                        clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']))
                        monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
                        owned = next(c for c in clients if c['pid'] == int(process.name))
                        monitor = next(m for m in monitors if m['id'] == owned['monitor'])
                        geometry = {'at': owned['at'], 'size': owned['size'],
                                    'monitor': monitor['name'], 'refresh_hz': monitor['refreshRate'],
                                    'workspace': owned['workspace']['name'],
                                    'visible_workspace': owned['workspace']['id'] == monitor['activeWorkspace']['id'],
                                    'hidden': owned['hidden']}
                    except (OSError, StopIteration, KeyError, subprocess.CalledProcessError):
                        geometry = {'unavailable': True}
                sample += 1
                fields = {}
                for name in ['status', 'smaps_rollup']:
                    for line in (process / name).read_text().splitlines():
                        key, _, value = line.partition(':')
                        if key in {'VmRSS', 'VmHWM', 'Rss', 'Pss', 'Swap'}:
                            fields[key + '_KiB'] = int(value.split()[0])
                output.write(json.dumps({'at': datetime.now(timezone.utc).isoformat(), 'pid': int(process.name), 'native_window': geometry, **fields}) + '\n')
                output.flush()
            except (OSError, ValueError):
                break
            time.sleep(.2)


if __name__ == '__main__':
    main()
