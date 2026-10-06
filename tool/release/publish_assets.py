#!/usr/bin/env python3
"""Upload reviewed files to a private draft and verify downloaded bytes."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from validate_acceptance import verify_file


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', required=True)
    parser.add_argument('--repo', required=True)
    parser.add_argument('--tag', required=True)
    args = parser.parse_args()
    root = Path(args.directory)
    record = json.loads((root / 'release-manifest.json').read_text())
    names = [a['name'] for a in record['artifacts']] + ['SHA256SUMS', 'release-manifest.json', 'release-tools.txt']
    subprocess.run(['gh', 'release', 'upload', args.tag, '--repo', args.repo, *[str(root / name) for name in names]], check=True)
    with tempfile.TemporaryDirectory(prefix='tawaq-release-readback-') as directory:
        subprocess.run(['gh', 'release', 'download', args.tag, '--repo', args.repo, '--dir', directory], check=True)
        for asset in record['artifacts']:
            verify_file(Path(directory) / asset['name'], asset['sha256'])
        for name in ['SHA256SUMS', 'release-manifest.json', 'release-tools.txt']:
            if (Path(directory) / name).read_bytes() != (root / name).read_bytes():
                raise ValueError(f'Release metadata readback differs: {name}')


if __name__ == '__main__':
    main()
