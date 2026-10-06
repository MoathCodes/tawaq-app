import copy
import hashlib
import json
import tempfile
import subprocess
from record_toolchain import read_build_identity
from pathlib import Path
import unittest
from validate_acceptance import validate, verify_file, verify_toolchains, PLATFORMS

SHA = 'a' * 40


def fixture():
    names = ['tawaq-macos-arm64.dmg', 'tawaq-macos-x64.dmg',
             'tawaq-1-macos-arm64-installer.zip', 'tawaq-1-macos-x64-installer.zip',
             'tawaq-1-windows-x64-setup.exe', 'tawaq-1-linux-x64.zip',
             'tawaq.deb', 'tawaq.rpm', 'tawaq.pkg.tar.zst',
             *[f'toolchain-{platform}.json' for platform in sorted(PLATFORMS)]]
    return {'candidate_sha': SHA, 'sdk': '3.47.5', 'action': 'release',
            'build_name': '1.0.0', 'build_number': '42',
            'distribution_policy_approved': True,
            'platforms': {name: {'os': 'fixture OS', 'evidence': 'fixture evidence', 'passed': True,
                                'scenarios': {f'RC-{i:02}': 'passed' for i in range(1, 17)}} for name in PLATFORMS},
            'artifacts': [{'name': name, 'sha256': 'b' * 64, 'url': 'https://example.invalid/' + name} for name in names]}


class GateTests(unittest.TestCase):
    def check(self, record, platforms='linux,windows,macos', action='release', version=''):
        return validate(record, SHA, '3.47.5', platforms, action, version)

    def test_complete_reviewed_candidate(self):
        self.assertEqual(len(self.check(fixture())), 13)

    def test_incomplete_failed_mismatched_candidates(self):
        changes = [lambda r: r['artifacts'].pop(),
                   lambda r: r['platforms']['linux-x64']['scenarios'].pop('RC-16'),
                   lambda r: r['platforms'].pop('windows-x64'),
                   lambda r: r['platforms']['linux-x64'].update(passed=False),
                   lambda r: r['platforms']['macos-arm64']['scenarios'].update({'RC-08': 'failed'}),
                   lambda r: r.update(candidate_sha='c' * 40),
                   lambda r: r.update(distribution_policy_approved=False),
                   lambda r: r.update(build_name=''),
                   lambda r: r.update(build_number='0')]
        for change in changes:
            record = copy.deepcopy(fixture())
            change(record)
            with self.assertRaises(ValueError):
                self.check(record)
        with self.assertRaises(ValueError):
            self.check(fixture(), platforms='linux')

    def test_patch_requires_named_reviewed_version(self):
        record = fixture()
        record.update(action='patch', release_version='1.0.0+42')
        with self.assertRaises(ValueError):
            self.check(record, action='patch')
        self.check(record, action='patch', version='1.0.0+42')

    def test_toolchain_identity_is_checked_against_reviewed_build(self):
        record = fixture()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for platform in PLATFORMS:
                (root / f'toolchain-{platform}.json').write_text(json.dumps({
                    'candidate_sha': SHA, 'sdk': '3.47.5', 'platform': platform,
                    'build_identity': '1.0.0+42', 'dependency_locks': {'pubspec.lock': 'b' * 64},
                    'submodules': 'fixture exact revisions', 'tools': {'shorebird': 'fixture CLI'},
                }))
            verify_toolchains(root, record)
            path = root / 'toolchain-windows-x64.json'
            original = json.loads(path.read_text())
            for field, wrong in [('sdk', 'other'), ('candidate_sha', 'c' * 40),
                                 ('build_identity', '1.0.0+43'), ('tools', {})]:
                changed = dict(original)
                changed[field] = wrong
                path.write_text(json.dumps(changed))
                with self.assertRaises(ValueError):
                    verify_toolchains(root, record)
                path.write_text(json.dumps(original))

    def test_candidate_build_number_is_recorded_and_accepted(self):
        script = Path(__file__).resolve().parents[1] / 'set_pubspec_version.dart'
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'pubspec.yaml').write_text('name: fixture\nversion: 1.0.0+1\n')
            subprocess.run(['dart', str(script), '--build-number', '42', '--build-name', ''], cwd=root, check=True, capture_output=True)
            self.assertEqual(read_build_identity(root), '1.0.0+42')
            for platform in PLATFORMS:
                (root / f'toolchain-{platform}.json').write_text(json.dumps({
                    'candidate_sha': SHA, 'sdk': '3.47.5', 'platform': platform,
                    'build_identity': read_build_identity(root), 'dependency_locks': {'pubspec.lock': 'b' * 64},
                    'submodules': 'fixture exact revisions', 'tools': {'shorebird': 'fixture CLI'},
                }))
            verify_toolchains(root, fixture())
            subprocess.run(['dart', str(script), '--build-number', '43', '--build-name', '2.0.0'], cwd=root, check=True, capture_output=True)
            self.assertEqual(read_build_identity(root), '2.0.0+43')

    def test_missing_and_changed_files_fail(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'candidate.zip'
            with self.assertRaises(FileNotFoundError):
                verify_file(path, 'b' * 64)
            path.write_bytes(b'candidate')
            verify_file(path, hashlib.sha256(b'candidate').hexdigest())
            with self.assertRaises(ValueError):
                verify_file(path, 'b' * 64)


if __name__ == '__main__':
    unittest.main()
