import subprocess
import unittest
from unittest.mock import patch

from record_toolchain import STABLE_ALLOWED_CHANGES, check_working_tree, run


class RunTests(unittest.TestCase):
    def test_resolves_windows_batch_executable(self):
        executable = r'C:\flutter\bin\flutter.bat'
        with patch('record_toolchain.shutil.which', return_value=executable), \
                patch('record_toolchain.subprocess.run') as process:
            process.return_value.stdout = '{"frameworkVersion":"3.47.5"}\n'
            result = run(['flutter', '--version', '--machine'])
        self.assertEqual(result, '{"frameworkVersion":"3.47.5"}')
        self.assertEqual(process.call_args.args[0], [executable, '--version', '--machine'])
        self.assertEqual(process.call_args.kwargs['stderr'], subprocess.STDOUT)

    def test_preserves_the_leading_space_of_git_status(self):
        with patch('record_toolchain.shutil.which', return_value='/usr/bin/git'), \
                patch('record_toolchain.subprocess.run') as process:
            process.return_value.stdout = ' M pubspec.yaml\n'
            self.assertEqual(run(['git', 'status', '--porcelain']), ' M pubspec.yaml')

    def test_missing_command_has_a_clear_error(self):
        with patch('record_toolchain.shutil.which', return_value=None):
            with self.assertRaisesRegex(FileNotFoundError, 'Command not found on PATH: flutter'):
                run(['flutter', '--version'])


class WorkingTreeTests(unittest.TestCase):
    def test_stable_candidates_may_only_differ_by_the_applied_version(self):
        check_working_tree('')
        check_working_tree(' M pubspec.yaml')
        for status in [' M pubspec.yaml\n M lib/main.dart', '?? lib/new.dart', 'M  pubspec.yaml',
                       ' M pubspec.lock', ' M packages/dorar_hadith']:
            with self.assertRaises(ValueError, msg=status):
                check_working_tree(status)

    def test_stable_allowance_is_only_the_pubspec_version(self):
        self.assertEqual(STABLE_ALLOWED_CHANGES, {' M pubspec.yaml'})

    def test_betas_never_touch_the_working_tree(self):
        check_working_tree('', set())
        with self.assertRaises(ValueError):
            check_working_tree(' M pubspec.yaml', set())

    def test_the_error_names_what_differs(self):
        with self.assertRaisesRegex(ValueError, r'\?\? lib/new\.dart'):
            check_working_tree(' M pubspec.yaml\n?? lib/new.dart')


if __name__ == '__main__':
    unittest.main()
