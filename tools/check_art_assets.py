#!/usr/bin/env python3
"""Validate the original Project E Fantasy V3 SVG pack before Godot imports it."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "game/project-e/assets"
DESIGN = ROOT / "doc/design/assets/fantasy-v3"
HEROES = ("bas", "rio", "nema")
SKILLS = ("q", "w", "e", "r")
FILES = [ASSET / "portraits" / f"{hero}.svg" for hero in HEROES]
FILES += [ASSET / "ui/skills" / f"{hero}_{slot}.svg" for hero in HEROES for slot in SKILLS]
FILES += [DESIGN / x for x in ("style-guide.svg", "arena-map.svg", "hud-mockup.svg", "skill-vfx-board.svg")]
SVG_NS = "{http://www.w3.org/2000/svg}"


def validate() -> None:
    total = 0
    for path in FILES:
        if not path.is_file():
            raise RuntimeError(f"missing fantasy art: {path.relative_to(ROOT)}")
        root = ET.parse(path).getroot()
        if root.tag != SVG_NS + "svg":
            raise RuntimeError(f"not an SVG root: {path.relative_to(ROOT)}")
        if not root.attrib.get("width") or not root.attrib.get("height"):
            raise RuntimeError(f"missing art dimensions: {path.relative_to(ROOT)}")
        total += path.stat().st_size
    if total > 10 * 1024 * 1024:
        raise RuntimeError(f"fantasy art pack too large for normal Git: {total} bytes")
    print(f"Fantasy original SVG assets: {len(FILES)} files, {total} bytes, valid XML, size limit passed")


if __name__ == "__main__":
    validate()
