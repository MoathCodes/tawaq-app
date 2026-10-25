#!/usr/bin/env python3
"""Decide whether a beta build can rely on the Quality workflow for its commit.

Only a push run on main counts: it tested exactly that commit. A pull_request
run tested a merge of the branch with main, which is a different tree, and a
different commit never borrows another commit's result.
"""
import argparse
import os
import sys
import time

from github_api import gh_json

QUALITY_PATH = '.github/workflows/quality.yml'
PENDING = {'queued', 'in_progress', 'waiting', 'pending', 'requested'}


def is_quality_run_for(run, repo, commit):
    return (run.get('path', '').split('@')[0] == QUALITY_PATH and
            run.get('event') == 'push' and
            run.get('head_branch') == 'main' and
            run.get('head_sha') == commit and
            (run.get('repository') or {}).get('full_name') == repo and
            (run.get('head_repository') or {}).get('full_name') == repo)


def find_checks(runs, repo, commit):
    """Return (mode, run id): reuse a pass, wait for a pending run, or run our own."""
    candidates = [run for run in runs if is_quality_run_for(run, repo, commit)]
    passed = [run for run in candidates
              if run.get('status') == 'completed' and run.get('conclusion') == 'success']
    if passed:
        return 'reuse', max(run['id'] for run in passed)
    pending = [run for run in candidates if run.get('status') in PENDING]
    if pending:
        return 'wait', max(run['id'] for run in pending)
    # Missing, failed or cancelled: this build runs its own checks.
    return 'run', None


def verify_passed(run, repo, commit):
    """Raise unless run is a completed, successful Quality run of exactly commit."""
    if not is_quality_run_for(run, repo, commit):
        raise ValueError(f"Run {run.get('id')} is not a Quality push run of {commit} in {repo}")
    if run.get('status') != 'completed':
        raise ValueError(f"Quality run {run['id']} has not finished ({run.get('status')})")
    if run.get('conclusion') != 'success':
        raise ValueError(f"Quality run {run['id']} did not pass ({run.get('conclusion')})")


def write_outputs(**values):
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.writelines(f'{key}={value}\n' for key, value in values.items())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    find = commands.add_parser('find')
    find.add_argument('--checks', choices=['auto', 'skip'], default='auto')
    wait = commands.add_parser('wait')
    wait.add_argument('--run-id', required=True)
    wait.add_argument('--timeout-minutes', type=int, default=45)
    for command in (find, wait):
        command.add_argument('--repo', required=True)
        command.add_argument('--commit', required=True)
    args = parser.parse_args()

    if args.command == 'find':
        if args.checks == 'skip':
            mode, run_id = 'skip', None
        else:
            runs = gh_json(f'repos/{args.repo}/actions/workflows/quality.yml/runs'
                           f'?event=push&head_sha={args.commit}&per_page=100')['workflow_runs']
            mode, run_id = find_checks(runs, args.repo, args.commit)
        print(f'Checks for {args.commit}: {mode}' + (f' (run {run_id})' if run_id else ''))
        write_outputs(mode=mode, run_id=run_id or '')
        return

    deadline = time.monotonic() + args.timeout_minutes * 60
    while True:
        run = gh_json(f'repos/{args.repo}/actions/runs/{args.run_id}')
        if run.get('status') == 'completed':
            verify_passed(run, args.repo, args.commit)
            print(f'Quality run {args.run_id} passed for {args.commit}')
            return
        if time.monotonic() > deadline:
            sys.exit(f'Quality run {args.run_id} was still {run.get("status")} after '
                     f'{args.timeout_minutes} minutes')
        time.sleep(30)


if __name__ == '__main__':
    main()
