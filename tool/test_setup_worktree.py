"""Regression coverage for cache invalidation across worktrees."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import tarfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('setup_worktree', Path(__file__).with_name('setup_worktree.py'))
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class FingerprintTest(unittest.TestCase):
    def test_cache_hit_restores_sources_without_running_generators(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            common = root / '.git'
            cache = common / 'tawaq-codegen-cache'
            cache.mkdir(parents=True)
            generated = root / 'lib' / 'model.g.dart'
            generated.parent.mkdir()
            generated.write_text('generated source')
            with tarfile.open(cache / 'matching.tar', 'w') as bundle:
                bundle.add(generated, arcname='lib/model.g.dart')
            generated.unlink()

            def command(args, **kwargs):
                if args[1] == 'rev-parse':
                    return str(common).encode()
                return b''

            with patch.object(setup, 'ROOT', root), \
                    patch.object(setup, 'fingerprint', return_value='matching'), \
                    patch.object(setup.subprocess, 'check_output', command), \
                    patch.object(setup, 'run') as run:
                setup.main()
                self.assertEqual(generated.read_text(), 'generated source')
                self.assertFalse(any(call.args[0] == 'bash' for call in run.call_args_list))
                self.assertEqual(sum(call.args[:3] == ('flutter', 'pub', 'get')
                                     for call in run.call_args_list), 2)

    def test_working_inputs_and_sdk_invalidate_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(['git', 'init', '-q', directory], check=True)
            source = root / 'input.dart'
            source.write_text('original')
            subprocess.run(['git', 'add', '.'], cwd=root, check=True)
            actual = subprocess.check_output
            sdk = b'sdk-one'

            def command(args, **kwargs):
                return sdk if args[0] == 'flutter' else actual(args, **kwargs)

            with patch.object(setup, 'ROOT', root), patch.object(setup.subprocess, 'check_output', command):
                initial = setup.fingerprint()
                source.write_text('edited')
                self.assertNotEqual(initial, setup.fingerprint())
                source.write_text('original')
                self.assertEqual(initial, setup.fingerprint())
                new = root / 'new.dart'
                new.write_text('new input')
                self.assertNotEqual(initial, setup.fingerprint())
                new.unlink()
                source.unlink()
                self.assertNotEqual(initial, setup.fingerprint())
                source.write_text('original')
                sdk = b'sdk-two'
                self.assertNotEqual(initial, setup.fingerprint())


if __name__ == '__main__':
    unittest.main()
