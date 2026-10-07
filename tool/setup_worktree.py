#!/usr/bin/env python3
"""Reuse generated sources between identical worktrees, never build state."""
import hashlib
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent


def run(*args, cwd=ROOT):
    subprocess.run(args, cwd=cwd, check=True)


def output(path):
    return path.name.endswith(('.g.dart', '.freezed.dart', '.gr.dart'))


def fingerprint():
    # Include working contents (not just HEAD), new inputs and pinned submodules.
    tracked = subprocess.check_output(
        ['git', 'ls-files', '--recurse-submodules', '-z'], cwd=ROOT
    ).split(b'\0')
    new = subprocess.check_output(
        ['git', 'ls-files', '--others', '--exclude-standard', '-z'], cwd=ROOT
    ).split(b'\0')
    # ls-files --recurse-submodules includes tracked files only. Include new
    # source files in initialized submodules as well.
    submodules = subprocess.check_output(
        ['git', 'submodule', 'foreach', '--quiet', '--recursive',
         'printf "%s\\0" "$displaypath"'], cwd=ROOT
    ).split(b'\0')
    for name in submodules:
        if name:
            checkout = ROOT / os.fsdecode(name)
            prefix = name + b'/'
            new.extend(prefix + name for name in subprocess.check_output(
                ['git', 'ls-files', '--others', '--exclude-standard', '-z'], cwd=checkout
            ).split(b'\0') if name)
    digest = hashlib.sha256()
    digest.update(subprocess.check_output(['flutter', '--version', '--machine']))
    for name in sorted(set(tracked + new) - {b''}):
        path = ROOT / os.fsdecode(name)
        if not path.is_file():
            continue
        digest.update(name + b'\0')
        with path.open('rb') as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b''):
                digest.update(chunk)
    return digest.hexdigest()


def main():
    started = time.monotonic()
    common = subprocess.check_output(
        ['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'], cwd=ROOT
    ).decode().strip()
    run('git', 'submodule', 'sync', '--recursive')
    modules = subprocess.check_output(
        ['git', 'config', '--file', '.gitmodules', '--get-regexp',
         r'^submodule\..*\.path$'], cwd=ROOT
    ).decode().splitlines()
    for entry in modules:
        setting, path = entry.split(maxsplit=1)
        reference = Path(common) / 'modules' / setting[len('submodule.'):-len('.path')]
        options = ['--reference', str(reference), '--dissociate'] if reference.is_dir() else []
        # Borrow existing objects during clone, then copy them locally so Git
        # garbage collection in the primary checkout cannot break this worktree.
        run('git', 'submodule', 'update', '--init', '--recursive', '--depth', '1',
            *options, '--', path)
    cache = Path(common) / 'tawaq-codegen-cache'
    cache.mkdir(exist_ok=True)
    key = fingerprint()
    archive = cache / (key + '.tar')
    if archive.exists():
        print('==> restore matching generated sources', flush=True)
        with tarfile.open(archive) as bundle:
            bundle.extractall(ROOT, filter='data')
        run('flutter', 'pub', 'get', '--enforce-lockfile', cwd=ROOT / 'packages/mushaf_reader')
        run('flutter', 'pub', 'get', '--enforce-lockfile')
    else:
        print('==> no matching cache; generate sources', flush=True)
        run('bash', 'tool/codegen.sh')
        # Cache only ignored source outputs. Never copy absolute-path package
        # configs, builder state, native build outputs, or submodule sources.
        ignored = subprocess.check_output(
            ['git', 'ls-files', '--others', '--ignored', '--exclude-standard', '-z'], cwd=ROOT
        ).split(b'\0')
        with tempfile.NamedTemporaryFile(dir=cache, delete=False) as temporary:
            temporary_path = Path(temporary.name)
        try:
            with tarfile.open(temporary_path, 'w') as bundle:
                for name in ignored:
                    if name:
                        path = Path(os.fsdecode(name))
                        if output(path) and '.dart_tool' not in path.parts and 'build' not in path.parts:
                            bundle.add(ROOT / path, arcname=str(path), recursive=False)
            if fingerprint() == key:
                temporary_path.replace(archive)
            else:
                print('==> inputs changed during generation; cache not saved', flush=True)
        finally:
            temporary_path.unlink(missing_ok=True)
    print(f'==> worktree setup completed in {time.monotonic() - started:.1f}s')


if __name__ == '__main__':
    main()
