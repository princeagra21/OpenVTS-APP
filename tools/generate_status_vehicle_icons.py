#!/usr/bin/env python3
"""
Generate status-colored transparent vehicle marker PNGs.

Base icons:
  assets/images/vehicle_icons_named/*.png

Outputs:
  assets/images/vehicle_icons_status/<type>_<status>.png
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "images" / "vehicle_icons_named"
OUTPUT_DIR = ROOT / "assets" / "images" / "vehicle_icons_status"

STATUS_COLORS = {
    "running": (0x22, 0xC5, 0x5E),
    "stop": (0xEF, 0x44, 0x44),
    "idle": (0xF5, 0x9E, 0x0B),
    "inactive": (0x6B, 0x72, 0x80),
    "nodata": (0x37, 0x41, 0x51),
}


def colorize_icon(source: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    """Apply a controlled tint while keeping transparency and shading."""
    rgba = source.convert("RGBA")
    alpha = rgba.getchannel("A")

    # Keep detail by colorizing the grayscale luminance instead of flattening.
    gray = ImageOps.grayscale(rgba)
    dark = rgb
    light = tuple(min(255, int(c * 1.35 + 24)) for c in rgb)
    tinted = ImageOps.colorize(gray, black=dark, white=light).convert("RGBA")
    tinted.putalpha(alpha)
    return tinted


def main() -> int:
    if not SOURCE_DIR.exists():
        raise SystemExit(f"Source directory not found: {SOURCE_DIR}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    generated: list[Path] = []

    for source_path in sorted(SOURCE_DIR.glob("*.png")):
        base_name = source_path.stem
        with Image.open(source_path) as source:
            for status, rgb in STATUS_COLORS.items():
                out_path = OUTPUT_DIR / f"{base_name}_{status}.png"
                colorize_icon(source, rgb).save(out_path, format="PNG")
                generated.append(out_path)

    for path in generated:
        print(path.relative_to(ROOT))

    print(f"Generated {len(generated)} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
