#!/usr/bin/env python3
"""Record the actual candidate source, dependencies, SDK and packaging tools."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess


def run(command):
    return subprocess.run(command, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, text=True).stdout.strip()


def read_build_identity(root):
    return next(line.split(':', 1)[1].strip()
                for line in (root / 'pubspec.yaml').read_text().splitlines()
                if line.startswith('version:'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--platform', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--tool', action='append', default=[])
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
    version = read_build_identity(root)
    status = run(['git', 'status', '--porcelain'])
    if any(line != ' M pubspec.yaml' for line in status.splitlines()):
        raise ValueError('Candidate source/generation differs from the reviewed commit')
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
