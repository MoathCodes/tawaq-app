#!/usr/bin/env python3
"""Write and verify the manifest that ties a saved beta installer to its build."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re

from validate_acceptance import verify_file

MANIFEST_NAME = 'beta-manifest.json'
INSTALLERS = {'windows-x64': 'tawaq-{name}-windows-x64-setup.exe'}
CHECK_BASES = {'reused', 'waited', 'own', 'skipped'}
SHA = re.compile(r'[0-9a-f]{40}')
DIGEST = re.compile(r'[0-9a-f]{64}')
VERSION = re.compile(r'(\d+\.\d+\.\d+-beta\.([1-9]\d*))')


def sha256(path):
    hasher = hashlib.sha256()
    with Path(path).open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(block)
    return hasher.hexdigest()


def installer_name(platform, version_name):
    return INSTALLERS[platform].format(name=version_name)


def build_manifest(*, repo, run_id, run_attempt, commit, version, platform,
                   installer, toolchain, checks_basis, checks_run_id):
    installer = Path(installer)
    return {
        'schema': 1,
        'repository': repo,
        'build_run': {'id': str(run_id), 'attempt': str(run_attempt)},
        'commit': commit,
        'version': version,
        'platform': platform,
        'toolchain': toolchain,
        'files': [{'name': installer.name, 'sha256': sha256(installer),
                   'size': installer.stat().st_size}],
        'checks': {'basis': checks_basis, 'run_id': str(checks_run_id or '')},
    }


def validate_manifest(manifest, repo, run_id=None):
    """Structural checks. Raises ValueError with a message meant for the operator."""
    if manifest.get('schema') != 1:
        raise ValueError('Unsupported beta manifest schema')
    if manifest.get('repository') != repo:
        raise ValueError('This build belongs to another repository')
    if run_id is not None and manifest.get('build_run', {}).get('id') != str(run_id):
        raise ValueError('The manifest belongs to a different build run')
    if not SHA.fullmatch(manifest.get('commit', '')):
        raise ValueError('The manifest has no exact commit')
    version = manifest.get('version', {})
    match = VERSION.fullmatch(version.get('name', ''))
    if not match or version.get('number') != match[2] or \
            version.get('identity') != f"{version['name']}+{match[2]}":
        raise ValueError('The manifest version is not a well-formed beta version')
    platform = manifest.get('platform')
    if platform not in INSTALLERS:
        raise ValueError(f'Unsupported beta platform: {platform}')
    toolchain = manifest.get('toolchain', {})
    if (toolchain.get('candidate_sha') != manifest['commit'] or
            toolchain.get('platform') != platform or
            toolchain.get('build_identity') != version['identity'] or
            not toolchain.get('sdk') or not toolchain.get('dependency_locks')):
        raise ValueError('The recorded toolchain does not match the built commit and version')
    files = manifest.get('files', [])
    if [f.get('name') for f in files] != [installer_name(platform, version['name'])]:
        raise ValueError('The manifest must list exactly the installer for this version')
    for entry in files:
        if not DIGEST.fullmatch(entry.get('sha256', '')) or not isinstance(entry.get('size'), int):
            raise ValueError(f"{entry.get('name')}: missing checksum or size")
    if manifest.get('checks', {}).get('basis') not in CHECK_BASES:
        raise ValueError('The manifest does not say which checks the build relied on')


def verify_directory(directory, manifest):
    """Every listed file must match; nothing unlisted may be there."""
    directory = Path(directory)
    expected = {entry['name'] for entry in manifest['files']} | {MANIFEST_NAME}
    present = {path.name for path in directory.iterdir()}
    if present != expected:
        raise ValueError('The saved build has missing or unexpected files: '
                         f'{sorted(present ^ expected)}')
    for entry in manifest['files']:
        path = directory / entry['name']
        if path.stat().st_size != entry['size']:
            raise ValueError(f"Saved file changed size: {entry['name']}")
        verify_file(path, entry['sha256'])


def write_outputs(manifest):
    if os.environ.get('GITHUB_OUTPUT'):
        checks = manifest['checks']
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write(f"version={manifest['version']['name']}\n"
                         f"commit={manifest['commit']}\n"
                         f"platform={manifest['platform']}\n"
                         f"installer={manifest['files'][0]['name']}\n"
                         f"checks_basis={checks['basis']}\n"
                         f"checks_run_id={checks['run_id']}\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    write = commands.add_parser('write')
    write.add_argument('--repo', required=True)
    write.add_argument('--run-id', required=True)
    write.add_argument('--run-attempt', required=True)
    write.add_argument('--commit', required=True)
    write.add_argument('--version-name', required=True)
    write.add_argument('--version-number', required=True)
    write.add_argument('--platform', required=True)
    write.add_argument('--toolchain', required=True)
    write.add_argument('--checks-basis', required=True, choices=sorted(CHECK_BASES))
    write.add_argument('--checks-run-id', default='')
    write.add_argument('--directory', required=True, help='Folder holding the installer.')
    verify = commands.add_parser('verify')
    verify.add_argument('--repo', required=True)
    verify.add_argument('--run-id', required=True)
    verify.add_argument('--directory', required=True)
    args = parser.parse_args()

    directory = Path(args.directory)
    if args.command == 'write':
        installer = directory / installer_name(args.platform, args.version_name)
        manifest = build_manifest(
            repo=args.repo, run_id=args.run_id, run_attempt=args.run_attempt,
            commit=args.commit, platform=args.platform, installer=installer,
            version={'name': args.version_name, 'number': args.version_number,
                     'identity': f'{args.version_name}+{args.version_number}'},
            toolchain=json.loads(Path(args.toolchain).read_text()),
            checks_basis=args.checks_basis, checks_run_id=args.checks_run_id)
        validate_manifest(manifest, args.repo, args.run_id)
        (directory / MANIFEST_NAME).write_text(json.dumps(manifest, indent=2) + '\n')
        print(f"Recorded {installer.name} sha256={manifest['files'][0]['sha256']}")
        return

    manifest = json.loads((directory / MANIFEST_NAME).read_text())
    validate_manifest(manifest, args.repo, args.run_id)
    verify_directory(directory, manifest)
    write_outputs(manifest)
    print(f"Verified {manifest['files'][0]['name']} from build run {args.run_id}")


if __name__ == '__main__':
    main()
