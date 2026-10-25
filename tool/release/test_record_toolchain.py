import subprocess
import unittest
from unittest.mock import patch

from record_toolchain import run


class RunTest(unittest.TestCase):
    def test_resolves_windows_batch_executable(self):
        executable = r'C:\flutter\bin\flutter.bat'
        with patch('record_toolchain.shutil.which', return_value=executable), \
                patch('record_toolchain.subprocess.run') as process:
            process.return_value.stdout = '{"frameworkVersion":"3.47.5"}\n'
            result = run(['flutter', '--version', '--machine'])
        self.assertEqual(result, '{"frameworkVersion":"3.47.5"}')
        self.assertEqual(process.call_args.args[0],
                         [executable, '--version', '--machine'])
        self.assertEqual(process.call_args.kwargs['stderr'], subprocess.STDOUT)

    def test_preserves_git_status_leading_space(self):
        with patch('record_toolchain.shutil.which', return_value='/usr/bin/git'), \
                patch('record_toolchain.subprocess.run') as process:
            process.return_value.stdout = ' M pubspec.yaml\n'
            self.assertEqual(run(['git', 'status', '--porcelain']),
                             ' M pubspec.yaml')

    def test_missing_command_has_clear_error(self):
        with patch('record_toolchain.shutil.which', return_value=None):
            with self.assertRaisesRegex(FileNotFoundError,
                                        'Command not found on PATH: flutter'):
                run(['flutter', '--version'])


if __name__ == '__main__':
    unittest.main()
