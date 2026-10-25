#!/usr/bin/env python3
"""Fix a beta's version before it is built, and refuse versions that go backwards.

Name = the pubspec.yaml base (without any prerelease or build suffix) plus
-beta.<run number>. The build number is the same run number. Nothing is written
to pubspec.yaml: the version is passed to the build on the command line.
"""
import argparse
import os
from pathlib import Path
import re

BASE = re.compile(r'^version:\s*(\d+)\.(\d+)\.(\d+)(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?\s*$', re.M)
TAG = re.compile(r'^v(\d+)\.(\d+)\.(\d+)(?:-beta\.(\d+))?$')


def base_version(pubspec_text):
    matches = BASE.findall(pubspec_text)
    if len(matches) != 1:
        raise ValueError('Expected exactly one semantic version in pubspec.yaml')
    return tuple(int(part) for part in matches[0])


def beta_version(pubspec_text, run_number):
    if not re.fullmatch(r'[1-9]\d*', str(run_number)):
        raise ValueError('The workflow run number must be a positive integer')
    major, minor, patch = base_version(pubspec_text)
    number = int(run_number)
    return {'name': f'{major}.{minor}.{patch}-beta.{number}', 'number': str(number),
            'identity': f'{major}.{minor}.{patch}-beta.{number}+{number}'}


def check_not_backwards(name, published_tags):
    """Refuse a version at or below anything already published, drafts included."""
    match = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)-beta\.(\d+)', name)
    if not match:
        raise ValueError(f'Not a beta version: {name}')
    core, number = tuple(int(match[i]) for i in (1, 2, 3)), int(match[4])
    for tag in published_tags:
        found = TAG.match(tag.strip())
        if not found:
            continue
        other = tuple(int(found[i]) for i in (1, 2, 3))
        if found[4] is None:
            # A stable release of this core outranks every beta of it.
            if other >= core:
                raise ValueError(f'{name} would go backwards: {tag.strip()} is already published')
        elif other > core or (other == core and int(found[4]) >= number):
            raise ValueError(f'{name} would go backwards or repeat: {tag.strip()} is already published')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pubspec', default='pubspec.yaml')
    parser.add_argument('--run-number', required=True)
    parser.add_argument('--published-tags', required=True,
                        help='File with one published or draft release tag per line.')
    args = parser.parse_args()
    version = beta_version(Path(args.pubspec).read_text(), args.run_number)
    tags = Path(args.published_tags).read_text().splitlines()
    check_not_backwards(version['name'], tags)
    print(f"Beta version {version['identity']}")
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write(f"name={version['name']}\nnumber={version['number']}\n"
                         f"identity={version['identity']}\n")


if __name__ == '__main__':
    main()
