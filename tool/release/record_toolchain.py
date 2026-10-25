#!/usr/bin/env python3
"""Record the actual candidate source, dependencies, SDK and packaging tools."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess

# Stable candidates rewrite the pubspec.yaml version before building. Nothing
# else may differ from the reviewed commit.
STABLE_ALLOWED_CHANGES = {' M pubspec.yaml'}


def run(command):
    executable = shutil.which(command[0])
    if executable is None:
        raise FileNotFoundError(f'Command not found on PATH: {command[0]}')
    # rstrip only: git status --porcelain starts with a meaningful space.
    return subprocess.run([executable, *command[1:]], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True).stdout.rstrip()


def read_build_identity(root):
    return next(line.split(':', 1)[1].strip()
                for line in (root / 'pubspec.yaml').read_text().splitlines()
                if line.startswith('version:'))


def check_working_tree(status, allowed=STABLE_ALLOWED_CHANGES):
    unexpected = [line for line in status.splitlines() if line not in allowed]
    if unexpected:
        raise ValueError('Candidate source/generation differs from the reviewed commit: '
                         + '; '.join(unexpected))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--platform', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--tool', action='append', default=[])
    parser.add_argument('--require-clean', action='store_true',
                        help='Beta builds pass the version on the command line and '
                             'leave the working tree untouched; allow no changes.')
    parser.add_argument('--build-identity',
                        help='Version that was built. Defaults to the pubspec.yaml version.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    os.chdir(root)
    sdk = json.loads(run(['flutter', '--version', '--machine']))
    pinned = json.loads((root / '.fvmrc').read_text())['flutter']
    if sdk['frameworkVersion'] != pinned:
        raise ValueError('Resolved Flutter differs from the pinned SDK')
    tools = {'dart': run(['dart', '--version'])}
    for definition in args.tool:
        name, command = definition.split('=', 1)
        if not name or name in tools:
            raise ValueError('Tool names must be unique')
        tools[name] = run(shlex.split(command))
        if not tools[name]:
            raise ValueError(f'{name} did not report its version')
    locks = {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
             for path in [root / 'pubspec.lock', *sorted((root / 'packages').glob('**/pubspec.lock'))]
             if path.is_file()}
    version = args.build_identity or read_build_identity(root)
    status = run(['git', 'status', '--porcelain'])
    check_working_tree(status, set() if args.require_clean else STABLE_ALLOWED_CHANGES)
    record = {'candidate_sha': run(['git', 'rev-parse', 'HEAD']),
              'platform': args.platform, 'build_identity': version,
              'sdk': pinned, 'flutter': sdk, 'tools': tools,
              'dependency_locks': locks,
              'submodules': run(['git', 'submodule', 'status', '--recursive']),
              'working_tree': status}
    target = Path(args.output)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(record, indent=2) + '\n')


if __name__ == '__main__':
    main()
