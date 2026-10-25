#!/usr/bin/env python3
"""Publish one exact, already-built beta installer as a GitHub prerelease.

Nothing is rebuilt or retested here. The build run, its saved files and the
checks it relied on are verified first. The files go to a private draft, are
downloaded again and compared byte for byte, and only then does the draft
become a public prerelease.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from beta_checks import verify_passed
from beta_manifest import MANIFEST_NAME, validate_manifest, verify_directory
from beta_version import check_not_backwards
from github_api import gh_json
from validate_acceptance import verify_file

# Branches whose Build desktop workflow file is trusted to describe a beta. A
# feature branch can carry its own edited workflow, so its builds are not.
ALLOWED_BRANCH = re.compile(r'main|release/[^\s/][^\s]*')
BUILD_WORKFLOW = '.github/workflows/build-desktop.yml'
OWN_CHECK_JOBS = {'Beta checks: App analyze and test', 'Beta checks: Local package quality'}
# Not SHA256SUMS: the one-line installer (website/public/install.sh) takes the
# first release that has a file named exactly that, and a Windows-only beta has
# no macOS or Linux archive for it to match.
CHECKSUMS_PREFIX = 'SHA256SUMS-'


def require_run_id(value):
    if not value.isascii() or not value.isdigit():
        raise ValueError('The build run ID must be the number from the run URL, '
                         f'not "{value}". "latest" is never accepted.')
    return value


def artifact_name(platform):
    return f'tawaq-beta-{platform}'


def validate_build_run(run, repo, run_id):
    if str(run.get('id')) != str(run_id):
        raise ValueError(f'GitHub returned run {run.get("id")}, not {run_id}')
    if (run.get('repository') or {}).get('full_name') != repo or \
            (run.get('head_repository') or {}).get('full_name') != repo:
        raise ValueError('Only builds from this repository can be published')
    if run.get('path', '').split('@')[0] != BUILD_WORKFLOW:
        raise ValueError('This run is not a Build desktop run')
    if not ALLOWED_BRANCH.fullmatch(run.get('head_branch') or ''):
        raise ValueError(f"Betas can only be published from builds of main or release/* "
                         f"branches, not {run.get('head_branch')!r}")
    if run.get('event') != 'workflow_dispatch':
        raise ValueError(f"Only manually started builds can be published, not {run.get('event')}")
    if run.get('status') != 'completed':
        raise ValueError(f"The build has not finished ({run.get('status')})")
    if run.get('conclusion') != 'success':
        raise ValueError(f"The build did not succeed ({run.get('conclusion')})")


def find_artifact(artifacts):
    """The saved installer for a run, or an operator-readable reason it is gone."""
    matches = [a for a in artifacts if a.get('name', '').startswith('tawaq-beta-')]
    if len(matches) != 1:
        raise ValueError('This run has no single saved beta installer. Was it a beta build?')
    if matches[0].get('expired'):
        raise ValueError(f"The saved build expired on {matches[0].get('expires_at')}. "
                         'Run Build desktop with action=beta again and publish the new run.')
    return matches[0]


def verify_checks(manifest, run, jobs, quality_run):
    """Raise unless the checks the build relied on are green for exactly its commit."""
    basis, checks_run = manifest['checks']['basis'], manifest['checks']['run_id']
    if basis == 'skipped':
        raise ValueError('This build skipped checks, so it is unchecked and cannot be published. '
                         'Build it again with checks.')
    if run.get('head_sha') != manifest['commit']:
        raise ValueError('The build run and the manifest disagree about the commit')
    if basis == 'own':
        if checks_run != str(run['id']):
            raise ValueError('The build claims its own checks but names another run')
        passed = {job['name'] for job in jobs if job.get('conclusion') == 'success'}
        if not OWN_CHECK_JOBS <= passed:
            raise ValueError('The build did not pass its own checks')
        return
    verify_passed(quality_run, manifest['repository'], manifest['commit'])
    if str(quality_run['id']) != checks_run:
        raise ValueError('The checks run differs from the one the manifest names')


def release_tags(releases):
    return [release['tag_name'] for release in releases]


def check_release_free(tag, version, existing_tags):
    if tag in existing_tags:
        raise ValueError(f'{tag} already exists as a release or draft. Published versions '
                         'are never overwritten; inspect or delete it deliberately.')
    check_not_backwards(version, existing_tags)


def checksums_text(manifest):
    return ''.join(f"{f['sha256']}  {f['name']}\n" for f in manifest['files'])


def release_notes(manifest, run_url):
    version, entry = manifest['version']['name'], manifest['files'][0]
    return (f"Windows beta {version} from commit {manifest['commit'][:12]}.\n\n"
            'Unsigned test build: Windows SmartScreen may warn on first launch. '
            'It is not a stable release and cannot receive Shorebird patches.\n\n'
            f"- File: `{entry['name']}`\n- SHA-256: `{entry['sha256']}`\n"
            f"- Checks: {manifest['checks']['basis']}\n- Build: {run_url}\n")


def run_gh(*args):
    return subprocess.run(['gh', *args], check=True, stdout=subprocess.PIPE, text=True).stdout


def publish(manifest, directory, repo, run_url, *, rehearse=False, gh=run_gh):
    tag = f"v{manifest['version']['name']}"
    directory = Path(directory)
    platform = manifest['platform']
    checksums = directory.parent / f'{CHECKSUMS_PREFIX}{platform}'
    checksums.write_text(checksums_text(manifest))
    notes = directory.parent / 'release-notes.md'
    notes.write_text(release_notes(manifest, run_url))
    files = [directory / manifest['files'][0]['name'], checksums, directory / MANIFEST_NAME]

    gh('release', 'create', tag, '--repo', repo, '--target', manifest['commit'], '--draft',
       '--prerelease', '--title', f"Tawaq {manifest['version']['name']} (Windows beta)",
       '--notes-file', str(notes))
    try:
        gh('release', 'upload', tag, '--repo', repo, *map(str, files))
        with tempfile.TemporaryDirectory(prefix='tawaq-beta-readback-') as folder:
            gh('release', 'download', tag, '--repo', repo, '--dir', folder)
            readback = Path(folder)
            verify_file(readback / manifest['files'][0]['name'], manifest['files'][0]['sha256'])
            for sent in files[1:]:
                if (readback / sent.name).read_bytes() != sent.read_bytes():
                    raise ValueError(f'Release readback differs: {sent.name}')
            if {p.name for p in readback.iterdir()} != {f.name for f in files}:
                raise ValueError('The draft holds unexpected files')
        if rehearse:
            gh('release', 'delete', tag, '--repo', repo, '--yes')
            return None
        gh('release', 'edit', tag, '--repo', repo, '--draft=false', '--prerelease',
           '--latest=false')
    except BaseException:
        # The draft is private and ours; leaving it would block the retry.
        try:
            gh('release', 'delete', tag, '--repo', repo, '--yes')
        except Exception as error:
            print(f'Could not delete the private draft {tag}: {error}', file=sys.stderr)
        raise
    return json.loads(gh('release', 'view', tag, '--repo', repo, '--json', 'url,isDraft,isPrerelease'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    inspect = commands.add_parser('inspect', help='Validate the build run; print its artifact.')
    publish_command = commands.add_parser('publish')
    for command in (inspect, publish_command):
        command.add_argument('--repo', required=True)
        command.add_argument('--run-id', required=True)
    publish_command.add_argument('--directory', required=True)
    publish_command.add_argument('--rehearse', action='store_true',
                                 help='Verify everything on a private draft, then delete it.')
    args = parser.parse_args()
    require_run_id(args.run_id)

    run = gh_json(f'repos/{args.repo}/actions/runs/{args.run_id}')
    validate_build_run(run, args.repo, args.run_id)
    artifact = find_artifact(
        gh_json(f'repos/{args.repo}/actions/runs/{args.run_id}/artifacts')['artifacts'])
    if args.command == 'inspect':
        print(f"Found {artifact['name']} on run {args.run_id}")
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
                output.write(f"artifact={artifact['name']}\n")
        return

    directory = Path(args.directory)
    manifest = json.loads((directory / MANIFEST_NAME).read_text())
    validate_manifest(manifest, args.repo, args.run_id)
    if artifact_name(manifest['platform']) != artifact['name']:
        raise ValueError('The saved artifact does not match the manifest platform')
    verify_directory(directory, manifest)
    quality_run = None
    if manifest['checks']['basis'] in ('reused', 'waited'):
        quality_run = gh_json(f"repos/{args.repo}/actions/runs/{manifest['checks']['run_id']}")
    jobs = gh_json(f'repos/{args.repo}/actions/runs/{args.run_id}/jobs?per_page=100')['jobs']
    verify_checks(manifest, run, jobs, quality_run)
    releases = [item for page in gh_json(f'repos/{args.repo}/releases?per_page=100', paginate=True)
                for item in page]
    check_release_free(f"v{manifest['version']['name']}", manifest['version']['name'],
                       release_tags(releases))
    result = publish(manifest, directory, args.repo, run['html_url'], rehearse=args.rehearse)
    if result is None:
        print('Rehearsal passed: the private draft matched byte for byte and was deleted.')
    else:
        print(f"Published {result['url']}")
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
                summary.write(f"Published [{manifest['version']['name']}]({result['url']})\n")


if __name__ == '__main__':
    main()
