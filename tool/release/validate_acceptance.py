#!/usr/bin/env python3
"""Validate reviewed native evidence and the complete staged candidate set."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

PLATFORMS = {'linux-x64', 'windows-x64', 'macos-arm64', 'macos-x64'}
REQUIRED_ASSETS = [
    r'tawaq-macos-arm64\.dmg', r'tawaq-macos-x64\.dmg',
    r'tawaq-.+-macos-arm64-installer\.zip', r'tawaq-.+-macos-x64-installer\.zip',
    r'tawaq-.+-windows-x64-setup\.exe', r'tawaq-.+-linux-x64\.zip',
    r'.+\.deb', r'.+\.rpm', r'.+\.pkg\.tar\.zst',
    *[rf'toolchain-{platform}\.json' for platform in sorted(PLATFORMS)],
]


def validate(record, revision, sdk, selected_platforms, action, release_version=''):
    if set(selected_platforms.split(',')) != {'macos', 'windows', 'linux'}:
        raise ValueError('Coordinated publication requires all three platforms')
    if record.get('candidate_sha') != revision or not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('Acceptance must identify this exact candidate revision')
    if record.get('sdk') != sdk:
        raise ValueError('Acceptance SDK differs from the pinned SDK')
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?', record.get('build_name', '')):
        raise ValueError('Acceptance must identify the reviewed semantic build name')
    if not re.fullmatch(r'[1-9]\d*', str(record.get('build_number', ''))):
        raise ValueError('Acceptance must identify the reviewed build number')
    if record.get('action') != action or action not in {'release', 'patch'}:
        raise ValueError('Acceptance must cover the requested distribution action')
    if action == 'patch' and (not release_version or record.get('release_version') != release_version):
        raise ValueError('Patches require an explicit reviewed target version')
    if action == 'patch' and release_version != f"{record['build_name']}+{record['build_number']}":
        raise ValueError('Patch target differs from the reviewed build identity')
    platforms = record.get('platforms', {})
    if set(platforms) != PLATFORMS:
        raise ValueError('Linux, Windows and both macOS architectures need native acceptance')
    required_scenarios = {f'RC-{i:02}' for i in range(1, 17)}
    for name, evidence in platforms.items():
        if not evidence.get('os') or not evidence.get('evidence') or evidence.get('passed') is not True:
            raise ValueError(f'{name}: missing native OS/evidence/pass')
        scenarios = evidence.get('scenarios', {})
        if set(scenarios) != required_scenarios or any(v != 'passed' for v in scenarios.values()):
            raise ValueError(f'{name}: every required release scenario must pass')
    if record.get('distribution_policy_approved') is not True:
        raise ValueError('Signing/install policy has not been reviewed')
    assets = record.get('artifacts', [])
    names = [asset.get('name', '') for asset in assets]
    if len(set(names)) != len(names) or any(Path(name).name != name for name in names):
        raise ValueError('Artifact names must be unique basenames')
    for pattern in REQUIRED_ASSETS:
        if sum(bool(re.fullmatch(pattern, name)) for name in names) != 1:
            raise ValueError(f'Missing or ambiguous required artifact: {pattern}')
    for asset in assets:
        if not re.fullmatch(r'[0-9a-f]{64}', asset.get('sha256', '')):
            raise ValueError('Each candidate artifact needs a SHA-256 digest')
        if not asset.get('url', '').startswith('https://'):
            raise ValueError('Each reviewed candidate artifact needs an HTTPS download URL')
    return assets


def verify_file(path, digest):
    hasher = hashlib.sha256()
    with Path(path).open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(block)
    if hasher.hexdigest() != digest:
        raise ValueError(f'Candidate artifact checksum mismatch: {Path(path).name}')


def verify_toolchains(root, record):
    for platform in sorted(PLATFORMS):
        toolchain = json.loads((root / f'toolchain-{platform}.json').read_text())
        if (toolchain.get('candidate_sha') != record['candidate_sha'] or
                toolchain.get('sdk') != record['sdk'] or
                toolchain.get('platform') != platform or
                toolchain.get('build_identity') != f"{record['build_name']}+{record['build_number']}" or
                not toolchain.get('dependency_locks') or
                not toolchain.get('submodules') or
                not toolchain.get('tools', {}).get('shorebird')):
            raise ValueError(f'{platform}: candidate toolchain identity is incomplete or mismatched')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--record', required=True)
    parser.add_argument('--revision', required=True)
    parser.add_argument('--sdk', required=True)
    parser.add_argument('--platforms', required=True)
    parser.add_argument('--action', required=True)
    parser.add_argument('--release-version', default='')
    parser.add_argument('--download-to')
    parser.add_argument('--verify-directory')
    args = parser.parse_args()
    record = json.loads(Path(args.record).read_text())
    assets = validate(record, args.revision, args.sdk, args.platforms, args.action, args.release_version)
    if not args.download_to and not args.verify_directory:
        parser.error('Verify actual staged files or download the reviewed candidate')
    root = Path(args.download_to or args.verify_directory)
    root.mkdir(parents=True, exist_ok=True)
    for asset in assets:
        path = root / asset['name']
        if args.download_to:
            with urllib.request.urlopen(asset['url'], timeout=60) as response, path.open('wb') as destination:
                while block := response.read(1024 * 1024):
                    destination.write(block)
        verify_file(path, asset['sha256'])
    verify_toolchains(root, record)
    (root / 'SHA256SUMS').write_text(''.join(f"{asset['sha256']}  {asset['name']}\n" for asset in assets))
    (root / 'release-manifest.json').write_text(json.dumps(record, indent=2) + '\n')
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write(f"build_name={record['build_name']}\nbuild_number={record['build_number']}\n")
    print(f'Verified {len(assets)} artifacts for {args.revision}')


if __name__ == '__main__':
    main()
