"""Regression checks for the shipped export and installation contract."""
import tempfile
import unittest
from pathlib import Path

import yaml
from PIL import Image

from render import (TOOL_ROOT, WINDOWS_ICO_SIZES, export, install_assets,
                    render_icon)


class IconExportsTest(unittest.TestCase):
    def setUp(self):
        self.config = yaml.safe_load((TOOL_ROOT / 'config.yaml').read_text())

    def test_every_design_is_visible_and_inset_at_tray_sizes(self):
        for design, palette in self.config['designs'].items():
            for size in (16, 18, 22, 24, 32, 64, 1024):
                with self.subTest(design=design, size=size):
                    image = render_icon(design, palette, size, tray=size < 64)
                    self.assertEqual(image.size, (size, size))
                    self.assertEqual(image.mode, 'RGBA')
                    self.assertEqual(image.getpixel((0, 0))[3], 0)
                    self.assertEqual(image.getpixel((size//2, size//2))[3], 255)
                    # Count actual mark pixels, including dark-on-light candidates.
                    foreground = tuple(int(palette['foreground'][i:i+2], 16) for i in (1, 3, 5))
                    coverage = sum(count for count, pixel in image.getcolors(size*size)
                                   if pixel[3] > 240 and sum((pixel[i]-foreground[i])**2
                                   for i in range(3)) < 60**2)
                    self.assertGreater(coverage, size*size*0.08)


    def test_ico_contains_all_custom_rendered_sizes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            design = self.config['default']
            palette = self.config['designs'][design]
            export(design, palette, root)
            with Image.open(root / 'windows/app_icon.ico') as ico:
                self.assertEqual(ico.ico.sizes(), {(s, s) for s in WINDOWS_ICO_SIZES})
                for size in WINDOWS_ICO_SIZES:
                    self.assertEqual(ico.ico.getimage((size, size)).tobytes(),
                                     render_icon(design, palette, size).tobytes())

    def test_install_updates_flutter_and_platforms_preserving_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / 'repo'
            root = Path(tmp) / 'out'
            design = self.config['default']
            export(design, self.config['designs'][design], root)
            metadata = repo / 'macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'
            metadata.parent.mkdir(parents=True)
            metadata.write_text('preserve me')
            sentinel = repo / 'linux/icons/hicolor/custom.txt'
            sentinel.parent.mkdir(parents=True)
            sentinel.write_text('preserve me too')
            install_assets(repo, root)
            self.assertEqual(metadata.read_text(), 'preserve me')
            self.assertEqual(sentinel.read_text(), 'preserve me too')
            for source, target in {
                'master/app_icon.png': 'assets/images/app_icon.png',
                'tray/tray_icon.png': 'assets/images/tray_icon.png',
                'windows/app_icon.ico': 'windows/runner/resources/app_icon.ico',
                'linux/hicolor/16x16/apps/tawaq.png': 'linux/icons/hicolor/16x16/apps/tawaq.png',
                'master/app_icon.svg': 'tooling/icons/source/app_icon.svg',
            }.items():
                self.assertEqual((root / source).read_bytes(), (repo / target).read_bytes())

    def test_palette_foreground_and_accent_exceed_three_to_one(self):
        def luminance(color):
            values = [int(color[i:i+2], 16)/255 for i in (1, 3, 5)]
            values = [v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4 for v in values]
            return sum(a*b for a, b in zip(values, (0.2126, 0.7152, 0.0722)))
        for design, palette in self.config['designs'].items():
            for role in ('foreground', 'accent'):
                if role not in palette:
                    continue
                light, dark = sorted([luminance(palette[role]), luminance(palette['background'])], reverse=True)
                contrast = (light+0.05)/(dark+0.05)
                self.assertGreater(contrast, 3, (design, role, contrast))
                print(f'{design} {role}: {contrast:.2f}:1')


if __name__ == '__main__':
    unittest.main()
