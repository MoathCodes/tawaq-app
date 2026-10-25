import contextlib
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from beta_version import base_version, beta_version, check_not_backwards, main


class BetaVersionTests(unittest.TestCase):
    def test_version_comes_from_the_base_and_run_number(self):
        for pubspec in ['version: 1.0.0+1\n', 'version: 1.0.0-beta.9+1\n', 'version: 1.0.0\n']:
            self.assertEqual(beta_version(pubspec, 16), {
                'name': '1.0.0-beta.16', 'number': '16', 'identity': '1.0.0-beta.16+16'})

    def test_malformed_input_is_refused(self):
        for pubspec in ['name: x\n', 'version: 1.0\n', 'version: 1.0.0+1\nversion: 1.0.1+1\n']:
            with self.assertRaises(ValueError):
                base_version(pubspec)
        for run_number in ['0', '-1', 'latest', '']:
            with self.assertRaises(ValueError):
                beta_version('version: 1.0.0+1\n', run_number)

    def test_new_versions_pass(self):
        check_not_backwards('1.0.0-beta.16', [])
        check_not_backwards('1.0.0-beta.16', ['v1.0.0-beta.9', 'v0.9.0', 'v1.0.0-rc.1', 'nightly'])
        check_not_backwards('1.0.1-beta.2', ['v1.0.0', 'v1.0.0-beta.99'])

    def test_repeated_or_older_versions_are_refused(self):
        for published in ['v1.0.0-beta.16', 'v1.0.0-beta.17', 'v1.1.0-beta.1', 'v1.0.0', 'v2.0.0']:
            with self.assertRaises(ValueError, msg=published):
                check_not_backwards('1.0.0-beta.16', [published])

    def test_only_betas_can_be_checked(self):
        with self.assertRaises(ValueError):
            check_not_backwards('1.0.0', [])

    def test_cli_leaves_pubspec_untouched_and_exposes_outputs(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'pubspec.yaml').write_text('version: 1.0.0+1\n')
            (root / 'tags.txt').write_text('v1.0.0-beta.9\n')
            output = root / 'out'
            argv = ['beta_version.py', '--pubspec', str(root / 'pubspec.yaml'),
                    '--run-number', '16', '--published-tags', str(root / 'tags.txt')]
            with patch.object(sys, 'argv', argv), \
                    patch.dict(os.environ, {'GITHUB_OUTPUT': str(output)}), \
                    contextlib.redirect_stdout(io.StringIO()):
                main()
            self.assertEqual(output.read_text(),
                             'name=1.0.0-beta.16\nnumber=16\nidentity=1.0.0-beta.16+16\n')
            self.assertEqual((root / 'pubspec.yaml').read_text(), 'version: 1.0.0+1\n')


if __name__ == '__main__':
    unittest.main()
