import copy
import json
from pathlib import Path
import tempfile
import unittest

from beta_manifest import (MANIFEST_NAME, build_manifest, installer_name, validate_manifest,
                           verify_directory)

REPO = 'owner/app'
SHA = 'a' * 40
NAME = '1.0.0-beta.16'


def toolchain(**overrides):
    record = {'candidate_sha': SHA, 'platform': 'windows-x64', 'build_identity': f'{NAME}+16',
              'sdk': '3.47.5', 'dependency_locks': {'pubspec.lock': 'b' * 64}, 'tools': {}}
    record.update(overrides)
    return record


def make(folder, basis='own', **kwargs):
    folder = Path(folder)
    installer = folder / installer_name('windows-x64', NAME)
    installer.write_bytes(b'installer bytes')
    manifest = build_manifest(
        repo=REPO, run_id=77, run_attempt=1, commit=SHA, platform='windows-x64',
        installer=installer, version={'name': NAME, 'number': '16', 'identity': f'{NAME}+16'},
        toolchain=kwargs.get('toolchain', toolchain()), checks_basis=basis, checks_run_id=77)
    (folder / MANIFEST_NAME).write_text(json.dumps(manifest))
    return manifest


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)

    def test_a_complete_build_validates_and_verifies(self):
        manifest = make(self.folder.name)
        validate_manifest(manifest, REPO, 77)
        verify_directory(self.folder.name, manifest)
        self.assertEqual(manifest['files'][0]['name'], 'tawaq-1.0.0-beta.16-windows-x64-setup.exe')

    def test_other_repositories_and_runs_are_refused(self):
        manifest = make(self.folder.name)
        with self.assertRaises(ValueError):
            validate_manifest(manifest, 'other/app', 77)
        with self.assertRaises(ValueError):
            validate_manifest(manifest, REPO, 78)

    def test_malformed_identity_is_refused(self):
        manifest = make(self.folder.name)
        changes = [lambda m: m.update(schema=2),
                   lambda m: m.update(commit='main'),
                   lambda m: m['version'].update(name='1.0.0'),
                   lambda m: m['version'].update(name='1.0.0-beta.0'),
                   lambda m: m['version'].update(number='15'),
                   lambda m: m['version'].update(identity='1.0.0-beta.16+15'),
                   lambda m: m.update(platform='linux-x64'),
                   lambda m: m['toolchain'].update(candidate_sha='c' * 40),
                   lambda m: m['toolchain'].update(build_identity='1.0.0+1'),
                   lambda m: m['toolchain'].update(dependency_locks={}),
                   lambda m: m['files'][0].update(name='tawaq-other-setup.exe'),
                   lambda m: m['files'][0].update(sha256='short'),
                   lambda m: m['files'].append(copy.deepcopy(m['files'][0])),
                   lambda m: m['checks'].update(basis='trust-me')]
        for change in changes:
            broken = copy.deepcopy(manifest)
            change(broken)
            with self.assertRaises(ValueError):
                validate_manifest(broken, REPO, 77)

    def test_tampered_missing_and_extra_files_fail(self):
        manifest = make(self.folder.name)
        folder = Path(self.folder.name)
        installer = folder / manifest['files'][0]['name']
        installer.write_bytes(b'installer bytez')
        with self.assertRaisesRegex(ValueError, 'checksum'):
            verify_directory(folder, manifest)
        installer.write_bytes(b'installer bytes but longer')
        with self.assertRaisesRegex(ValueError, 'size'):
            verify_directory(folder, manifest)
        installer.write_bytes(b'installer bytes')
        (folder / 'extra.exe').write_bytes(b'x')
        with self.assertRaisesRegex(ValueError, 'unexpected'):
            verify_directory(folder, manifest)
        (folder / 'extra.exe').unlink()
        installer.unlink()
        with self.assertRaisesRegex(ValueError, 'missing'):
            verify_directory(folder, manifest)


if __name__ == '__main__':
    unittest.main()
