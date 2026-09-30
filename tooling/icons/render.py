#!/usr/bin/env python3
"""Render size-aware geometric Tawaq icons. No browser, fonts or ImageMagick.

./generate.sh --all --install --before ../../docs/design/icons/before
"""
from __future__ import annotations

import argparse
import html
import shutil
from pathlib import Path

import yaml
from PIL import Image, ImageDraw, ImageFont

MACOS_SIZES = [16, 32, 64, 128, 256, 512, 1024]
WINDOWS_ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
LINUX_SIZES = [16, 32, 48, 64, 128, 256, 512]
TRAY_SIZES = [16, 18, 22, 24, 32, 36, 48, 64]
TOOL_ROOT = Path(__file__).resolve().parent

# Paths use a 100-unit grid. Cubic curves stay editable in the SVG exports.
CRESCENT = 'M 61 24 C 40 19 22 34 22 52 C 22 72 39 82 59 78 C 74 74 82 61 79 46 C 73 59 57 64 45 55 C 32 45 40 27 61 24 Z'
QAF = 'M 27 45 C 22 73 42 85 63 77 C 78 71 83 57 78 44 C 74 30 54 29 48 42 C 41 57 54 66 68 60 C 65 69 47 74 36 65 C 30 60 32 53 33 47 Z'
LUNE = 'M 68 24 C 51 17 31 26 25 44 C 18 66 33 83 54 81 C 71 80 84 66 81 48 C 76 61 64 68 51 66 C 36 64 29 52 34 40 C 38 29 52 23 68 24 Z'
MONOGRAM = 'M 25 48 C 22 68 35 80 52 79 C 70 78 80 65 77 48 C 75 35 66 29 57 32 C 46 35 44 46 50 54 C 54 60 63 62 70 57 C 66 67 60 72 51 72 C 39 72 31 63 33 50 Z'
LEAF_LEFT = 'M 48 77 C 34 73 26 61 26 45 L 26 25 C 40 28 48 41 48 57 Z'
LEAF_RIGHT = 'M 53 77 L 53 57 C 53 41 61 28 75 25 L 75 45 C 75 61 67 73 53 77 Z'
ARCH = 'M 26 75 L 26 44 C 26 10 74 10 74 44 L 74 75 L 62 75 L 62 44 C 62 26 38 26 38 44 L 38 75 Z'


def mark(design: str, small: bool) -> list[tuple[str, object, str]]:
    """Return path/circle primitives and semantic palette roles."""
    if design == 'lune':
        return [('path', LUNE, 'foreground')]
    if design == 'monogram':
        return [('path', MONOGRAM, 'foreground'),
                ('circle', (61.5, 45.5, 6.5), 'background'),
                ('circle', (54, 23, 3.8 if small else 3.5), 'foreground'),
                ('circle', (68, 23, 3.8 if small else 3.5), 'foreground')]
    if design == 'leaf':
        return [('path', LEAF_LEFT, 'foreground'), ('path', LEAF_RIGHT, 'foreground')]
    if design == 'crescent':
        # A larger, simpler diamond replaces the star's fine shoulders below 32px.
        spark = ('M 70 19 L 78 29 L 70 39 L 62 29 Z' if small else
                 'M 70 18 L 73 25 L 81 29 L 73 33 L 70 41 L 67 33 L 59 29 L 67 25 Z')
        return [('path', CRESCENT, 'foreground'), ('path', spark, 'accent')]
    if design == 'qaf':
        return [('path', QAF, 'foreground'), ('circle', (63, 47, 7), 'background'),
                ('circle', (55, 23, 4.5 if small else 4), 'accent'),
                ('circle', (71, 23, 4.5 if small else 4), 'accent')]
    if design == 'arch':
        return [('path', ARCH, 'foreground'),
                ('path', 'M 46 75 L 46 54 C 46 49 54 49 54 54 L 54 75 Z', 'accent')]
    raise ValueError(f'Unknown design: {design}')


def path_points(data: str) -> list[tuple[float, float]]:
    tokens = iter(data.split())
    points: list[tuple[float, float]] = []
    for command in tokens:
        if command in ('M', 'L'):
            points.append((float(next(tokens)), float(next(tokens))))
        elif command == 'C':
            start = points[-1]
            a, b, end = [(float(next(tokens)), float(next(tokens))) for _ in range(3)]
            for step in range(1, 65):
                t = step / 64
                u = 1 - t
                points.append(tuple(u**3 * start[i] + 3*u*u*t*a[i] +
                                    3*u*t*t*b[i] + t**3*end[i] for i in (0, 1)))
        elif command != 'Z':
            raise ValueError(f'Unsupported path command: {command}')
    return points


def render_icon(design: str, palette: dict, size: int, *, tray: bool = False) -> Image.Image:
    # Draw from geometry at each target size, rather than shrinking a 1024px bitmap.
    scale = 4 if size >= 256 else 8
    side = size * scale
    image = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    inset = max(scale, round(side * (0.035 if not tray else 0.045)))
    draw.rounded_rectangle((inset, inset, side-1-inset, side-1-inset),
                           radius=round(side * 0.22), fill=palette['background'])
    # Slightly enlarge the mark in the tray; preserve a safe margin around its tips.
    growth = 1.08 if tray else 1.0
    def xy(point):
        return tuple((50 + (value - 50) * growth) * side / 100 for value in point)
    for kind, geometry, role in mark(design, size <= 32):
        if kind == 'path':
            draw.polygon([xy(p) for p in path_points(geometry)], fill=palette[role])
        else:
            x, y, r = geometry
            draw.ellipse((*xy((x-r, y-r)), *xy((x+r, y+r))), fill=palette[role])
    return image.resize((size, size), Image.Resampling.LANCZOS)


def svg(design: str, palette: dict) -> str:
    shapes = ['<rect x="3.5" y="3.5" width="93" height="93" rx="22" fill="'+palette['background']+'"/>']
    for kind, geometry, role in mark(design, False):
        color = palette[role]
        if kind == 'path':
            shapes.append(f'<path d="{geometry}" fill="{color}"/>')
        else:
            x, y, r = geometry
            shapes.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>')
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">\n'+'\n'.join(shapes)+'\n</svg>\n'


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def export(design: str, palette: dict, root: Path) -> None:
    master = root / 'master'
    save_png(render_icon(design, palette, 1024), master / 'app_icon.png')
    (master / 'app_icon.svg').write_text(svg(design, palette), encoding='utf-8')
    for size in MACOS_SIZES:
        save_png(render_icon(design, palette, size), root / 'macos/AppIcon.appiconset' / f'app_icon_{size}.png')
    frames = []
    for size in WINDOWS_ICO_SIZES:
        frame = render_icon(design, palette, size)
        save_png(frame, root / 'windows' / f'app_icon_{size}.png')
        frames.append(frame)
    frames[-1].save(root / 'windows/app_icon.ico', format='ICO',
                    sizes=[(s, s) for s in WINDOWS_ICO_SIZES], append_images=frames[:-1])
    for size in LINUX_SIZES:
        save_png(render_icon(design, palette, size), root / 'linux/hicolor' / f'{size}x{size}/apps/tawaq.png')
    for size in TRAY_SIZES:
        save_png(render_icon(design, palette, size, tray=True), root / 'tray' / f'tray_icon_{size}.png')
    save_png(render_icon(design, palette, 32, tray=True), root / 'tray/tray_icon.png')


def install_assets(repo: Path, root: Path) -> None:
    # Copy only owned files. Never remove a platform's icon directory or metadata.
    targets = {
        'macos/AppIcon.appiconset': 'macos/Runner/Assets.xcassets/AppIcon.appiconset',
        'linux/hicolor': 'linux/icons/hicolor',
    }
    for source, destination in targets.items():
        for file in (root / source).rglob('*.png'):
            target = repo / destination / file.relative_to(root / source)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file, target)
    for source, destination in {
        'windows/app_icon.ico': 'windows/runner/resources/app_icon.ico',
        'master/app_icon.png': 'assets/images/app_icon.png',
        'tray/tray_icon.png': 'assets/images/tray_icon.png',
    }.items():
        target = repo / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / source, target)
    source = repo / 'tooling/icons/source'
    source.mkdir(parents=True, exist_ok=True)
    for name in ('app_icon.png', 'app_icon.svg'):
        shutil.copy2(root / 'master' / name, source / name)


def font(size: int) -> ImageFont.FreeTypeFont:
    # Pillow's bundled font avoids dependence on host font discovery.
    return ImageFont.load_default(size=size)


def comparison(root: Path, designs: dict, before: Path | None, before_label: str = 'Old') -> None:
    columns = [(before_label, None)] if before else []
    columns += [(palette['name'], key) for key, palette in designs.items()]
    width = 300 * len(columns) + 64
    sheet = Image.new('RGB', (width, 960), '#F4F2ED')
    draw = ImageDraw.Draw(sheet)
    draw.text((32, 22), 'Tawaq / icon directions', font=font(30), fill='#182D30')
    draw.text((32, 64), 'Same identity at launcher, menu and tray sizes', font=font(17), fill='#42585A')
    for col, (name, key) in enumerate(columns):
        x = 32 + col * 300
        draw.text((x, 110), name, font=font(22), fill='#182D30')
        old_app = Image.open(before / 'app_icon.png').convert('RGBA') if key is None else None
        old_tray = Image.open(before / 'tray_icon.png').convert('RGBA') if key is None else None
        def icon(size, tray=False):
            if key:
                return render_icon(key, designs[key], size, tray=tray)
            source = old_tray if tray else old_app
            if size == 16 and not tray and (before / 'app_icon_16.png').exists():
                return Image.open(before / 'app_icon_16.png').convert('RGBA')
            return source.resize((size, size), Image.Resampling.LANCZOS)
        for y, bg in [(155, '#FFFFFF'), (375, '#20272B')]:
            draw.rounded_rectangle((x, y, x+268, y+200), radius=12, fill=bg)
            sheet.paste(icon(176), (x+46, y+12), icon(176))
        draw.text((x, 594), 'Menu / actual pixels', font=font(16), fill='#42585A')
        for i, size in enumerate([16, 24, 32, 48, 64]):
            at = x + i*52
            pic = icon(size)
            sheet.paste(pic, (at, 634+(64-size)//2), pic)
            draw.text((at, 712), str(size), font=font(13), fill='#42585A')
        draw.text((x, 750), 'Tray / actual pixels', font=font(16), fill='#42585A')
        for row, bg in enumerate(['#FFFFFF', '#20272B']):
            y = 783 + row*68
            draw.rounded_rectangle((x, y, x+268, y+56), radius=8, fill=bg)
            for i, size in enumerate([16, 18, 22, 24, 32]):
                pic = icon(size, tray=True)
                sheet.paste(pic, (x+20+i*48, y+(44-size)//2), pic)
                draw.text((x+20+i*48, y+42), str(size), font=font(10),
                          fill='#42585A' if row == 0 else '#C9D4D4')
    save_png(sheet, root / 'comparison.png')


def preview(root: Path, designs: dict) -> None:
    cards = []
    for key, palette in designs.items():
        cards.append(f'<section><h2>{html.escape(palette["name"])}</h2><div class="light"><img src="variants/{key}/master/app_icon.svg" width="192"></div><div class="dark">'+
                     ''.join(f'<img src="variants/{key}/tray/tray_icon_{size}.png" width="{size}" height="{size}" title="{size}px">' for size in TRAY_SIZES)+ '</div></section>')
    (root / 'preview.html').write_text('<!doctype html><meta charset="utf-8"><title>Tawaq icons</title><style>body{font:16px system-ui;background:#f4f2ed;color:#182d30;margin:32px}main{display:flex;gap:24px;flex-wrap:wrap}section{width:320px}.light{background:white;padding:32px}.dark{background:#20272b;padding:24px;display:flex;align-items:center;gap:12px;flex-wrap:wrap}</style><h1>Tawaq icon directions</h1><main>'+''.join(cards)+'</main><p>Tray images shown at actual pixel sizes.</p>', encoding='utf-8')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='config.yaml')
    parser.add_argument('--out', default='out')
    parser.add_argument('--variant', choices=['crescent', 'qaf', 'arch', 'lune', 'monogram', 'leaf'])
    parser.add_argument('--collection', choices=['original', 'refined'], help='Limit --all to one design round.')
    parser.add_argument('--all', action='store_true', help='Export every candidate, in addition to the selected default.')
    parser.add_argument('--before', help='Directory with old app_icon.png and tray_icon.png for comparison.')
    parser.add_argument('--before-label', default='Old')
    parser.add_argument('--install', action='store_true')
    args = parser.parse_args()
    config = yaml.safe_load((TOOL_ROOT / args.config).read_text(encoding='utf-8'))
    selected = args.variant or config['default']
    if args.variant is None and args.collection:
        selected = config['collections'][args.collection][0]
    keys = (config['collections'][args.collection] if args.collection else config['designs']) if args.all else [selected]
    designs = {key: config['designs'][key] for key in keys}
    root = (TOOL_ROOT / args.out).resolve()
    # Refuse outputs that could overwrite source or the repo on installation.
    if root == TOOL_ROOT or root in TOOL_ROOT.parents or TOOL_ROOT / 'source' == root:
        parser.error('--out must be a dedicated output directory')
    root.mkdir(parents=True, exist_ok=True)
    export(selected, config['designs'][selected], root)
    for key, palette in designs.items():
        export(key, palette, root / 'variants' / key)
    comparison(root, designs, (TOOL_ROOT / args.before).resolve() if args.before else None, args.before_label)
    preview(root, designs)
    if args.install:
        install_assets(TOOL_ROOT.parent.parent, root)
    print(f'Generated {", ".join(designs)}; default: {selected}; output: {root}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
