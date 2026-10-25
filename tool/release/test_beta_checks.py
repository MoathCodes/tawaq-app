import unittest

from beta_checks import find_checks, verify_passed

REPO = 'owner/app'
SHA = 'a' * 40


def run(id, **overrides):
    record = {'id': id, 'path': '.github/workflows/quality.yml', 'event': 'push',
              'head_branch': 'main', 'head_sha': SHA, 'status': 'completed',
              'conclusion': 'success', 'repository': {'full_name': REPO},
              'head_repository': {'full_name': REPO}}
    record.update(overrides)
    return record


class FindChecksTests(unittest.TestCase):
    def find(self, *runs, commit=SHA):
        return find_checks(list(runs), REPO, commit)

    def test_a_passed_run_for_the_same_commit_is_reused(self):
        self.assertEqual(self.find(run(1)), ('reuse', 1))
        self.assertEqual(self.find(run(1), run(5), run(3, conclusion='failure')), ('reuse', 5))

    def test_a_running_run_is_waited_for(self):
        self.assertEqual(self.find(run(2, status='in_progress', conclusion=None)), ('wait', 2))
        self.assertEqual(self.find(run(2, status='queued', conclusion=None)), ('wait', 2))

    def test_a_pass_beats_a_pending_rerun(self):
        self.assertEqual(self.find(run(2, status='in_progress', conclusion=None), run(1)), ('reuse', 1))

    def test_missing_failed_or_cancelled_checks_run_alongside_the_build(self):
        self.assertEqual(self.find(), ('run', None))
        for conclusion in ['failure', 'cancelled', 'timed_out', 'skipped']:
            self.assertEqual(self.find(run(1, conclusion=conclusion)), ('run', None))

    def test_another_commit_never_lends_its_result(self):
        self.assertEqual(self.find(run(1, head_sha='b' * 40)), ('run', None))
        self.assertEqual(self.find(run(1), commit='c' * 40), ('run', None))

    def test_pull_request_forks_and_other_workflows_do_not_count(self):
        for change in [{'event': 'pull_request'}, {'event': 'workflow_dispatch'},
                       {'head_branch': 'feature'},
                       {'path': '.github/workflows/build-desktop.yml'},
                       {'repository': {'full_name': 'someone/app'}},
                       {'head_repository': {'full_name': 'fork/app'}}]:
            self.assertEqual(self.find(run(1, **change)), ('run', None), change)

    def test_workflow_ref_suffix_in_path_is_ignored(self):
        self.assertEqual(self.find(run(1, path='.github/workflows/quality.yml@refs/heads/main')),
                         ('reuse', 1))


class VerifyPassedTests(unittest.TestCase):
    def test_accepts_a_passed_run(self):
        verify_passed(run(1), REPO, SHA)

    def test_rejects_everything_else(self):
        for change in [{'conclusion': 'failure'}, {'status': 'in_progress', 'conclusion': None},
                       {'head_sha': 'b' * 40}, {'event': 'pull_request'}]:
            with self.assertRaises(ValueError, msg=change):
                verify_passed(run(1, **change), REPO, SHA)


if __name__ == '__main__':
    unittest.main()
