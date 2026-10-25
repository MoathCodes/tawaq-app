import json
from pathlib import Path
import re
import shutil
import tempfile
import unittest

from beta_manifest import MANIFEST_NAME
from publish_beta import (CHECKSUMS_PREFIX, OWN_CHECK_JOBS, check_release_free, find_artifact,
                          publish, require_run_id, validate_build_run, verify_checks)
from test_beta_manifest import NAME, REPO, SHA, make

URL = 'https://github.com/owner/app/actions/runs/77'


def build_run(**overrides):
    record = {'id': 77, 'path': '.github/workflows/build-desktop.yml', 'event': 'workflow_dispatch',
              'head_branch': 'main', 'status': 'completed', 'conclusion': 'success', 'head_sha': SHA,
              'repository': {'full_name': REPO}, 'head_repository': {'full_name': REPO},
              'html_url': URL}
    record.update(overrides)
    return record


def quality_run(**overrides):
    record = {'id': 55, 'path': '.github/workflows/quality.yml', 'event': 'push',
              'head_branch': 'main', 'head_sha': SHA, 'status': 'completed',
              'conclusion': 'success', 'repository': {'full_name': REPO},
              'head_repository': {'full_name': REPO}}
    record.update(overrides)
    return record


class BuildRunTests(unittest.TestCase):
    def test_only_a_numeric_run_id_is_accepted(self):
        self.assertEqual(require_run_id('40225575735'), '40225575735')
        for value in ['latest', '', '12 34', '../1', '1.5', '١٢٣']:
            with self.assertRaises(ValueError, msg=value):
                require_run_id(value)

    def test_a_successful_manual_build_in_this_repo_is_accepted(self):
        validate_build_run(build_run(), REPO, '77')
        validate_build_run(build_run(path='.github/workflows/build-desktop.yml@refs/heads/main'), REPO, '77')

    def test_only_main_and_release_branches_are_trusted(self):
        for branch in ['main', 'release/1.0.0-beta.9', 'release/2.x']:
            validate_build_run(build_run(head_branch=branch), REPO, '77')
        for branch in ['feature/faster', 'ci/faster-desktop-betas', 'release', 'release/', 'mainline',
                       'v1.0.0', 'refs/heads/main', 'main ', '', None]:
            with self.assertRaisesRegex(ValueError, 'main or release', msg=branch):
                validate_build_run(build_run(head_branch=branch), REPO, '77')

    def test_pull_request_fork_failed_pending_and_foreign_builds_are_refused(self):
        for change in [{'event': 'pull_request'}, {'event': 'push'},
                       {'head_repository': {'full_name': 'fork/app'}},
                       {'repository': {'full_name': 'other/app'}},
                       {'conclusion': 'failure'}, {'conclusion': 'cancelled'},
                       {'status': 'in_progress', 'conclusion': None},
                       {'path': '.github/workflows/quality.yml'}, {'id': 78}]:
            with self.assertRaises(ValueError, msg=change):
                validate_build_run(build_run(**change), REPO, '77')

    def test_artifact_must_exist_and_not_be_expired(self):
        self.assertEqual(find_artifact([{'name': 'tawaq-beta-windows-x64', 'expired': False}])['name'],
                         'tawaq-beta-windows-x64')
        with self.assertRaisesRegex(ValueError, 'no single saved beta'):
            find_artifact([{'name': 'tawaq-windows', 'expired': False}])
        with self.assertRaisesRegex(ValueError, 'expired on 2026-11-24.*again'):
            find_artifact([{'name': 'tawaq-beta-windows-x64', 'expired': True,
                            'expires_at': '2026-11-24'}])


class ChecksTests(unittest.TestCase):
    def manifest(self, basis, run_id):
        return {'repository': REPO, 'commit': SHA, 'checks': {'basis': basis, 'run_id': str(run_id)}}

    def jobs(self, *failed):
        return [{'name': name, 'conclusion': 'failure' if name in failed else 'success'}
                for name in OWN_CHECK_JOBS]

    def test_unchecked_builds_are_refused(self):
        with self.assertRaisesRegex(ValueError, 'unchecked'):
            verify_checks(self.manifest('skipped', ''), build_run(), self.jobs(), None)

    def test_reused_and_waited_checks_must_be_green_for_this_commit(self):
        for basis in ['reused', 'waited']:
            verify_checks(self.manifest(basis, 55), build_run(), [], quality_run())
        for change in [{'conclusion': 'failure'}, {'status': 'in_progress', 'conclusion': None},
                       {'head_sha': 'b' * 40}, {'event': 'pull_request'}, {'id': 56}]:
            with self.assertRaises(ValueError, msg=change):
                verify_checks(self.manifest('reused', 55), build_run(), [], quality_run(**change))

    def test_own_checks_need_both_jobs_green_in_this_run(self):
        verify_checks(self.manifest('own', 77), build_run(), self.jobs(), None)
        with self.assertRaises(ValueError):
            verify_checks(self.manifest('own', 77), build_run(), self.jobs('Beta checks: App analyze and test'), None)
        with self.assertRaises(ValueError):
            verify_checks(self.manifest('own', 77), build_run(), self.jobs()[:1], None)
        with self.assertRaises(ValueError):
            verify_checks(self.manifest('own', 12), build_run(), self.jobs(), None)

    def test_the_run_and_manifest_must_agree_on_the_commit(self):
        with self.assertRaisesRegex(ValueError, 'disagree'):
            verify_checks(self.manifest('own', 77), build_run(head_sha='b' * 40), self.jobs(), None)


class ReleaseNameTests(unittest.TestCase):
    def test_duplicates_including_drafts_are_refused(self):
        check_release_free(f'v{NAME}', NAME, ['v1.0.0-beta.9'])
        with self.assertRaisesRegex(ValueError, 'never overwritten'):
            check_release_free(f'v{NAME}', NAME, [f'v{NAME}'])

    def test_older_versions_are_refused_at_publish_time_too(self):
        with self.assertRaisesRegex(ValueError, 'backwards'):
            check_release_free(f'v{NAME}', NAME, ['v1.0.0-beta.20'])


class FakeGh:
    """Just enough of `gh release` to follow what publish does to a release."""

    def __init__(self, corrupt=None):
        self.calls, self.assets, self.state, self.corrupt = [], {}, None, corrupt

    def __call__(self, *args):
        self.calls.append(args)
        action = args[1]
        if action == 'create':
            self.state = {'draft': True, 'prerelease': '--prerelease' in args}
            self.create_args = args
        elif action == 'upload':
            for path in args[args.index('--repo') + 2:]:
                self.assets[Path(path).name] = Path(path).read_bytes()
        elif action == 'download':
            target = Path(args[args.index('--dir') + 1])
            for name, data in self.assets.items():
                (target / name).write_bytes(data + (b'!' if name == self.corrupt else b''))
        elif action == 'edit':
            self.state.update(draft=False, prerelease='--prerelease' in args)
        elif action == 'delete':
            self.state = None
        elif action == 'view':
            return json.dumps({'url': 'https://example.invalid/release', 'isDraft': self.state['draft'],
                               'isPrerelease': self.state['prerelease']})
        return ''


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.directory = Path(self.folder.name) / 'beta-input'
        self.directory.mkdir()
        self.manifest = make(self.directory)

    def test_publishes_a_verified_prerelease_that_is_not_latest(self):
        gh = FakeGh()
        result = publish(self.manifest, self.directory, REPO, URL, gh=gh)
        self.assertEqual(result['isDraft'], False)
        self.assertEqual(result['isPrerelease'], True)
        verbs = [call[1] for call in gh.calls]
        self.assertEqual(verbs, ['create', 'upload', 'download', 'edit', 'view'])
        self.assertIn('--draft', gh.create_args)
        self.assertIn('--prerelease', gh.create_args)
        self.assertIn('--latest=false', gh.calls[3])
        self.assertEqual(gh.create_args[2], f'v{NAME}')
        self.assertEqual(gh.create_args[gh.create_args.index('--target') + 1], SHA)

    def test_uploads_exactly_the_built_bytes(self):
        gh = FakeGh()
        publish(self.manifest, self.directory, REPO, URL, gh=gh)
        self.assertEqual(set(gh.assets), {f'tawaq-{NAME}-windows-x64-setup.exe',
                                          f'{CHECKSUMS_PREFIX}windows-x64', MANIFEST_NAME})
        self.assertEqual(gh.assets[f'tawaq-{NAME}-windows-x64-setup.exe'], b'installer bytes')
        self.assertEqual(gh.assets[f'{CHECKSUMS_PREFIX}windows-x64'].decode(),
                         f"{self.manifest['files'][0]['sha256']}  tawaq-{NAME}-windows-x64-setup.exe\n")

    def test_a_windows_only_beta_cannot_be_picked_up_by_the_one_line_installer(self):
        # website/public/install.sh takes the first matching file in the release list.
        patterns = [r'/SHA256SUMS$', r'/tawaq-[^/]*-macos-arm64-installer\.zip$',
                    r'/tawaq-[^/]*-macos-x64-installer\.zip$', r'/tawaq-[^/]*-linux-x64\.zip$']
        gh = FakeGh()
        publish(self.manifest, self.directory, REPO, URL, gh=gh)
        for name in gh.assets:
            for pattern in patterns:
                self.assertIsNone(re.search(pattern, f'https://x/releases/download/v1/{name}'), name)

    def test_rehearsal_verifies_then_deletes_the_private_draft(self):
        gh = FakeGh()
        self.assertIsNone(publish(self.manifest, self.directory, REPO, URL, rehearse=True, gh=gh))
        self.assertEqual([call[1] for call in gh.calls], ['create', 'upload', 'download', 'delete'])
        self.assertIsNone(gh.state)

    def test_a_readback_mismatch_never_goes_public_and_removes_the_draft(self):
        for corrupt in [f'tawaq-{NAME}-windows-x64-setup.exe', MANIFEST_NAME,
                        f'{CHECKSUMS_PREFIX}windows-x64']:
            gh = FakeGh(corrupt=corrupt)
            with self.assertRaises(ValueError, msg=corrupt):
                publish(self.manifest, self.directory, REPO, URL, gh=gh)
            self.assertNotIn('edit', [call[1] for call in gh.calls])
            self.assertIsNone(gh.state)

    def test_release_notes_do_not_claim_shorebird_patches(self):
        gh = FakeGh()
        publish(self.manifest, self.directory, REPO, URL, gh=gh)
        notes = (self.directory.parent / 'release-notes.md').read_text()
        self.assertIn('cannot receive Shorebird patches', notes)
        self.assertIn(self.manifest['files'][0]['sha256'], notes)


if __name__ == '__main__':
    unittest.main()
