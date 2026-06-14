#!/usr/bin/env python3
"""Render Tawaq icons from IBM Plex Sans Arabic via headless Chrome.

Requires: Python 3.10+, Pillow, PyYAML, Google Chrome or Chromium, ImageMagick (magick).

Usage:
  ./generate.sh              # write to tooling/icons/out/
  ./generate.sh --install    # copy into the Flutter project tree
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import yaml
from PIL import Image, ImageDraw, ImageFilter

MACOS_SIZES = [16, 32, 64, 128, 256, 512, 1024]
WINDOWS_ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
LINUX_SIZES = [16, 32, 48, 64, 128, 256, 512]

APP_TEXT_HTML_TEMPLATE = """<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8">
<style>
@font-face {{
  font-family: 'IBM Plex Sans Arabic';
  src: url('{font_url}') format('truetype');
  font-weight: {font_weight};
  font-style: normal;
}}
html, body {{
  margin: 0;
  width: {width}px;
  height: {height}px;
  overflow: hidden;
  background: transparent;
}}
body {{
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  padding: {padding_px}px;
}}
span {{
  font-family: 'IBM Plex Sans Arabic', sans-serif;
  font-weight: {font_weight};
  font-size: {font_size_px}px;
  color: {foreground};
  letter-spacing: {letter_spacing};
  line-height: {line_height};
  white-space: nowrap;
  user-select: none;
  {text_shadow_rule}
}}
</style>
</head>
<body><span>{text}</span></body>
</html>
"""

PREVIEW_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Tawaq icon preview</title>
<style>
  body {{ font-family: system-ui, sans-serif; margin: 24px; background: #1e1e1e; color: #eee; }}
  h1 {{ font-size: 1.1rem; font-weight: 600; }}
  p {{ color: #aaa; max-width: 52rem; }}
  .row {{ display: flex; gap: 32px; flex-wrap: wrap; margin-top: 24px; }}
  .panel {{ text-align: center; }}
  .checker {{
    background:
      linear-gradient(45deg, #ccc 25%, transparent 25%),
      linear-gradient(-45deg, #ccc 25%, transparent 25%),
      linear-gradient(45deg, transparent 75%, #ccc 75%),
      linear-gradient(-45deg, transparent 75%, #ccc 75%);
    background-size: 24px 24px;
    background-position: 0 0, 0 12px, 12px -12px, -12px 0;
    padding: 24px;
    border-radius: 12px;
  }}
  .light {{ background: #f6f6f6; padding: 24px; border-radius: 12px; }}
  .dark {{ background: #303030; padding: 24px; border-radius: 12px; }}
  img {{ width: 192px; height: 192px; image-rendering: auto; }}
  code {{ color: #f5d90a; }}
</style>
</head>
<body>
  <h1>Tawaq app icon preview</h1>
  <p>
    Opening a transparent PNG directly in the browser uses a <strong>white page background</strong>,
    which can look like the icon is a sharp square. Use this page to judge transparency and rounding.
    Regenerate with <code>./generate.sh</code>.
  </p>
  <div class="row">
    <div class="panel"><div class="checker"><img src="master/app_icon.png" alt="app icon"></div><p>Checkerboard</p></div>
    <div class="panel"><div class="light"><img src="master/app_icon.png" alt="app icon"></div><p>Light launcher</p></div>
    <div class="panel"><div class="dark"><img src="master/app_icon.png" alt="app icon"></div><p>Dark launcher</p></div>
  </div>
</body>
</html>
"""

TRAY_HTML_TEMPLATE = """<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8">
<style>
@font-face {{
  font-family: 'IBM Plex Sans Arabic';
  src: url('{font_url}') format('truetype');
  font-weight: {font_weight};
  font-style: normal;
}}
html, body {{
  margin: 0;
  width: {width}px;
  height: {height}px;
  overflow: visible;
  background: transparent;
}}
body {{
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  padding: {padding_px}px;
}}
span {{
  font-family: 'IBM Plex Sans Arabic', sans-serif;
  font-weight: {font_weight};
  font-size: {font_size_px}px;
  color: {foreground};
  letter-spacing: {letter_spacing};
  line-height: {line_height};
  white-space: nowrap;
  user-select: none;
  display: block;
  {text_shadow_rule}
}}
</style>
</head>
<body><span>{text}</span></body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        default="config.yaml",
        help="YAML config path (default: config.yaml)",
    )
    parser.add_argument(
        "--out",
        default="out",
        help="Output directory (default: out)",
    )
    parser.add_argument(
        "--install",
        action="store_true",
        help="Copy generated assets into the Tawaq Flutter project tree.",
    )
    parser.add_argument(
        "--chrome",
        default=None,
        help="Chrome/Chromium binary (auto-detected if omitted).",
    )
    args = parser.parse_args()

    tool_root = Path(__file__).resolve().parent
    repo_root = tool_root.parent.parent
    config_path = (tool_root / args.config).resolve()
    out_root = (tool_root / args.out).resolve()

    config = load_config(config_path, tool_root)
    chrome = args.chrome or find_chrome()
    if chrome is None:
        print(
            "Chrome/Chromium not found. Install Google Chrome or pass --chrome PATH.",
            file=sys.stderr,
        )
        return 1

    if out_root.exists():
        shutil.rmtree(out_root)
    out_root.mkdir(parents=True)

    print(f"Config: {config_path}")
    print(f"Chrome: {chrome}")
    print(f"Output: {out_root}")

    app_master = out_root / "master" / "app_icon.png"
    app_master.parent.mkdir(parents=True, exist_ok=True)
    render_variant(
        chrome=chrome,
        tool_root=tool_root,
        config=config,
        variant="app",
        output=app_master,
    )
    print(f"  Master app_icon.png ({config['app']['canvas_size']}px)")

    tray_master = out_root / "master" / "tray_master.png"
    render_variant(
        chrome=chrome,
        tool_root=tool_root,
        config=config,
        variant="tray",
        output=tray_master,
    )
    print(f"  Master tray_master.png ({config['tray']['canvas_size']}px)")

    export_platform_icons(app_master, out_root)
    export_tray_icons(tray_master, config["tray"]["sizes"], out_root)
    write_preview_page(out_root)

    if args.install:
        install_assets(repo_root, out_root)
        print(f"Installed icons into {repo_root}")

    print("Done.")
    return 0


def load_config(config_path: Path, tool_root: Path) -> dict[str, Any]:
    with config_path.open(encoding="utf-8") as handle:
        config = yaml.safe_load(handle)

    fonts_dir = (tool_root / config["fonts_dir"]).resolve()
    if not fonts_dir.is_dir():
        raise FileNotFoundError(f"fonts_dir not found: {fonts_dir}")

    for section in ("app", "tray"):
        font_file = fonts_dir / config[section]["font_file"]
        if not font_file.is_file():
            raise FileNotFoundError(f"Font not found: {font_file}")
        config[section]["_font_path"] = font_file

    config["_fonts_dir"] = fonts_dir
    return config


def render_variant(
    *,
    chrome: str,
    tool_root: Path,
    config: dict[str, Any],
    variant: str,
    output: Path,
) -> None:
    section = config[variant]
    canvas_size = int(section["canvas_size"])
    padding_px = round(canvas_size * float(section.get("padding_ratio", 0.12)))

    font_size_px = section.get("font_size_px")
    if font_size_px is None:
        font_size_px = round(canvas_size * float(section["font_size_ratio"]))
    font_size_px = int(font_size_px)

    background = section["background"]
    transparent = isinstance(background, str) and background.lower() == "transparent"

    text_shadow = section.get("text_shadow")
    text_shadow_rule = f"text-shadow: {text_shadow};" if text_shadow else ""
    line_height = section.get("line_height", 1.1)

    common = dict(
        font_url=section["_font_path"].resolve().as_uri(),
        font_weight=section.get("font_weight", 600),
        width=canvas_size,
        height=canvas_size,
        padding_px=padding_px,
        font_size_px=font_size_px,
        foreground=section["foreground"],
        letter_spacing=section.get("letter_spacing", "0"),
        line_height=line_height,
        text_shadow_rule=text_shadow_rule,
        text=section["text"],
    )

    if variant == "app":
        html = APP_TEXT_HTML_TEMPLATE.format(**common)
        text_layer = output.with_name(f"{output.stem}_text.png")
        with tempfile.TemporaryDirectory(prefix="tawaq-icon-") as tmp:
            html_path = Path(tmp) / "app_text.html"
            html_path.write_text(html, encoding="utf-8")
            screenshot_to_png(
                chrome=chrome,
                html_path=html_path,
                width=canvas_size,
                height=canvas_size,
                output=text_layer,
                transparent=True,
            )

        corner_radius_ratio = float(section.get("corner_radius_ratio", 0.225))
        composed = compose_app_icon(
            text_layer=Image.open(text_layer).convert("RGBA"),
            canvas_size=canvas_size,
            background=background,
            corner_radius_ratio=corner_radius_ratio,
            shadow=bool(section.get("shadow", True)),
            border=section.get("border"),
            text_depth=bool(section.get("text_depth", True)),
        )
        composed.save(output, format="PNG", optimize=True)
        text_layer.unlink(missing_ok=True)
        return

    html = TRAY_HTML_TEMPLATE.format(**common)
    with tempfile.TemporaryDirectory(prefix="tawaq-icon-") as tmp:
        html_path = Path(tmp) / f"{variant}.html"
        html_path.write_text(html, encoding="utf-8")
        screenshot_to_png(
            chrome=chrome,
            html_path=html_path,
            width=canvas_size,
            height=canvas_size,
            output=output,
            transparent=transparent,
        )

    if variant == "tray":
        margin_ratio = float(section.get("trim_margin_ratio", 0.14))
        image = Image.open(output).convert("RGBA")
        padded = fit_trimmed_content(image, margin_ratio=margin_ratio)
        padded.save(output, format="PNG", optimize=True)


def screenshot_to_png(
    *,
    chrome: str,
    html_path: Path,
    width: int,
    height: int,
    output: Path,
    transparent: bool,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        chrome,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={width},{height}",
        f"--screenshot={output}",
    ]
    if transparent:
        cmd.append("--default-background-color=00000000")
    cmd.append(html_path.as_uri())

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0 or not output.is_file():
        raise RuntimeError(
            "Chrome screenshot failed.\n"
            f"command: {' '.join(cmd)}\n"
            f"stdout: {result.stdout}\n"
            f"stderr: {result.stderr}",
        )


def export_platform_icons(master: Path, out_root: Path) -> None:
    master_image = Image.open(master).convert("RGBA")

    macos_dir = out_root / "macos" / "AppIcon.appiconset"
    macos_dir.mkdir(parents=True, exist_ok=True)
    for size in MACOS_SIZES:
        path = macos_dir / f"app_icon_{size}.png"
        resize_png(master_image, size, path)
        print(f"  macOS  app_icon_{size}.png")

    windows_dir = out_root / "windows"
    windows_dir.mkdir(parents=True, exist_ok=True)
    windows_pngs: list[Path] = []
    for size in WINDOWS_ICO_SIZES:
        path = windows_dir / f"app_icon_{size}.png"
        resize_png(master_image, size, path)
        windows_pngs.append(path)
        print(f"  Windows app_icon_{size}.png")

    magick = find_magick()
    if magick is not None:
        ico_path = windows_dir / "app_icon.ico"
        cmd = [magick, "convert", *[str(p) for p in windows_pngs], str(ico_path)]
        subprocess.run(cmd, check=True)
        print("  Windows app_icon.ico")
    else:
        print("  Skipped app_icon.ico (ImageMagick not found)")

    for size in LINUX_SIZES:
        linux_dir = out_root / "linux" / "hicolor" / f"{size}x{size}" / "apps"
        linux_dir.mkdir(parents=True, exist_ok=True)
        path = linux_dir / "tawaq.png"
        resize_png(master_image, size, path)
        print(f"  Linux  hicolor/{size}x{size}/apps/tawaq.png")


def parse_hex_color(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    if len(value) != 6:
        raise ValueError(f"Expected #RRGGBB color, got {value!r}")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def rounded_mask(size: int, radius_px: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius_px, fill=255)
    return mask


def add_text_depth(text_layer: Image.Image, *, canvas_size: int) -> Image.Image:
    """Add a warm shadow under gold glyphs for small-size legibility."""
    alpha = text_layer.getchannel("A")
    if alpha.getextrema() == (0, 0):
        return text_layer

    warm_brown = (66, 42, 25, 110)
    offset_y = max(1, round(canvas_size * 0.005))
    blur = max(1, round(canvas_size * 0.004))

    shadow = Image.new("RGBA", text_layer.size, (0, 0, 0, 0))
    shadow_fill = Image.new("RGBA", text_layer.size, warm_brown)
    shadow_fill.putalpha(alpha)
    shadow.alpha_composite(shadow_fill)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))

    layered = Image.new("RGBA", text_layer.size, (0, 0, 0, 0))
    layered.alpha_composite(shadow, (0, offset_y))
    layered.alpha_composite(text_layer)
    return layered


def compose_app_icon(
    *,
    text_layer: Image.Image,
    canvas_size: int,
    background: str,
    corner_radius_ratio: float,
    shadow: bool,
    border: str | None = None,
    text_depth: bool = True,
) -> Image.Image:
    """Build a rounded app icon in Pillow (reliable alpha, visible on light UIs)."""
    radius_px = round(canvas_size * corner_radius_ratio)
    plate_rgb = parse_hex_color(background)
    mask = rounded_mask(canvas_size, radius_px)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    if shadow:
        offset = max(2, round(canvas_size * 0.008))
        shadow_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow_layer)
        shadow_draw.rounded_rectangle(
            (offset, offset * 2, canvas_size - 1 - offset, canvas_size - 1 - offset),
            radius=radius_px,
            fill=(0, 0, 0, 72),
        )
        blur = max(2, round(canvas_size * 0.012))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(blur))
        canvas = Image.alpha_composite(canvas, shadow_layer)

    plate = Image.new("RGBA", (canvas_size, canvas_size), plate_rgb + (255,))
    plate.putalpha(mask)
    canvas = Image.alpha_composite(canvas, plate)

    if border:
        border_rgb = parse_hex_color(border)
        border_width = max(1, round(canvas_size * 0.004))
        inset = border_width // 2
        border_draw = ImageDraw.Draw(canvas)
        border_draw.rounded_rectangle(
            (inset, inset, canvas_size - 1 - inset, canvas_size - 1 - inset),
            radius=max(1, radius_px - inset),
            outline=border_rgb + (255,),
            width=border_width,
        )

    text = fit_trimmed_content(text_layer, margin_ratio=0)
    if text_depth:
        text = add_text_depth(text, canvas_size=canvas_size)
    paste_x = (canvas_size - text.width) // 2
    paste_y = (canvas_size - text.height) // 2
    canvas.alpha_composite(text, (paste_x, paste_y))
    return canvas


def write_preview_page(out_root: Path) -> None:
    preview = out_root / "preview.html"
    preview.write_text(PREVIEW_HTML, encoding="utf-8")
    print(f"  Preview preview.html")


def fit_trimmed_content(image: Image.Image, *, margin_ratio: float) -> Image.Image:
    """Crop transparent edges, add safe margin, and center in a square."""
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image

    cropped = image.crop(bbox)
    margin = max(1, round(max(cropped.size) * margin_ratio))
    padded_size = (cropped.width + margin * 2, cropped.height + margin * 2)
    padded = Image.new("RGBA", padded_size, (0, 0, 0, 0))
    padded.paste(cropped, (margin, margin))

    side = max(padded.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    offset = ((side - padded.width) // 2, (side - padded.height) // 2)
    square.paste(padded, offset)
    return square


def export_tray_icons(master: Path, sizes: list[int], out_root: Path) -> None:
    tray_dir = out_root / "tray"
    tray_dir.mkdir(parents=True, exist_ok=True)
    master_image = Image.open(master).convert("RGBA")

    for size in sizes:
        path = tray_dir / f"tray_icon_{size}.png"
        resize_png(master_image, size, path, resample=Image.Resampling.LANCZOS)
        print(f"  Tray   tray_icon_{size}.png")

    primary = tray_dir / "tray_icon.png"
    primary_size = 32 if 32 in sizes else sizes[-1]
    resize_png(master_image, primary_size, primary, resample=Image.Resampling.LANCZOS)


def resize_png(
    image: Image.Image,
    size: int,
    path: Path,
    *,
    resample: Image.Resampling = Image.Resampling.LANCZOS,
) -> None:
    resized = image.resize((size, size), resample=resample)
    path.parent.mkdir(parents=True, exist_ok=True)
    resized.save(path, format="PNG", optimize=True)


def install_assets(repo_root: Path, out_root: Path) -> None:
    macos_out = (
        repo_root / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    )
    macos_out.mkdir(parents=True, exist_ok=True)
    for size in MACOS_SIZES:
        shutil.copy2(
            out_root / "macos" / "AppIcon.appiconset" / f"app_icon_{size}.png",
            macos_out / f"app_icon_{size}.png",
        )

    windows_resources = repo_root / "windows" / "runner" / "resources"
    windows_resources.mkdir(parents=True, exist_ok=True)
    ico = out_root / "windows" / "app_icon.ico"
    if ico.is_file():
        shutil.copy2(ico, windows_resources / "app_icon.ico")

    linux_src = out_root / "linux" / "hicolor"
    if linux_src.is_dir():
        linux_dest = repo_root / "linux" / "icons" / "hicolor"
        if linux_dest.exists():
            shutil.rmtree(linux_dest)
        shutil.copytree(linux_src, linux_dest)

    shutil.copy2(out_root / "tray" / "tray_icon.png", repo_root / "assets" / "images" / "tray_icon.png")

    master_app = out_root / "master" / "app_icon.png"
    source_dir = repo_root / "tooling" / "icons" / "source"
    source_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(master_app, source_dir / "app_icon.png")


def find_chrome() -> str | None:
    for candidate in (
        "google-chrome",
        "google-chrome-stable",
        "chromium",
        "chromium-browser",
        "chrome",
    ):
        if shutil.which(candidate):
            return candidate
    return None


def find_magick() -> str | None:
    return "magick" if shutil.which("magick") else None


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CLI entrypoint
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
