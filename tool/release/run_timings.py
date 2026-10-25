#!/usr/bin/env python3
"""Print how long each step of a workflow run took, for before/after comparisons."""
import argparse
from datetime import datetime

from github_api import gh_json


def seconds(started, completed):
    if not started or not completed:
        return None
    parse = lambda value: datetime.fromisoformat(value.replace('Z', '+00:00'))
    return int((parse(completed) - parse(started)).total_seconds())


def timing_rows(jobs):
    rows = []
    for job in jobs:
        rows.append((job['name'], '(job)', seconds(job.get('started_at'), job.get('completed_at'))))
        rows.extend((job['name'], step['name'], seconds(step.get('started_at'), step.get('completed_at')))
                    for step in job.get('steps', []))
    return rows


def markdown(rows):
    lines = ['| Job | Step | Seconds |', '| --- | --- | ---: |']
    lines.extend(f"| {job} | {step} | {'-' if value is None else value} |" for job, step, value in rows)
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True)
    parser.add_argument('--run-id', required=True)
    args = parser.parse_args()
    jobs = gh_json(f'repos/{args.repo}/actions/runs/{args.run_id}/jobs?per_page=100')['jobs']
    print(markdown(timing_rows(jobs)))


if __name__ == '__main__':
    main()
