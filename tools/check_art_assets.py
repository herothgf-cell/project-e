#!/usr/bin/env python3
"""Validate Project E hero, skill and consumable SVG assets before Godot imports."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "game/project-e/assets"
DESIGN = ROOT / "doc/design/assets/fantasy-v3"
HEROES = ("bas", "rio", "nema", "orin", "tere", "mua", "sera", "lume")
SKILLS = ("q", "w", "e", "r")
FILES = [ASSET / "portraits" / f"{hero}.svg" for hero in HEROES[:3]]
FILES += [ASSET / "ui/skills" / f"{hero}_{slot}.svg" for hero in HEROES for slot in SKILLS]
FILES += [ASSET / "ui/items" / f"{item}.svg" for item in ("starlight_elixir", "grove_salve")]
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
    # The authoring source and shipped ability metadata must agree on every title.
    import re
    source = (ROOT / "game/project-e/scripts/battle/hero_abilities.gd").read_text()
    skill_section = source.split("const SKILLS:", 1)[1].split("const SKILL_HELP", 1)[0]
    vectors = set()
    for hero in HEROES:
        match = re.search(r'"' + hero + r'":\s*\[([^]]+)\]', skill_section)
        names = re.findall(r'"([^"\n]+)"', match.group(1)) if match else []
        if len(names) != 4:
            raise RuntimeError(f"missing authoritative skill names: {hero}")
        for slot, name in zip(SKILLS, names):
            path = ASSET / "ui/skills" / f"{hero}_{slot}.svg"
            root = ET.parse(path).getroot()
            title = root.find(SVG_NS + "title")
            if title is None or title.text != name:
                raise RuntimeError(f"skill icon title mismatch: {hero}_{slot}, expected {name}")
            geometry = tuple(ET.tostring(node) for node in root if node.tag != SVG_NS + "title")
            if geometry in vectors:
                raise RuntimeError(f"duplicate skill vector: {hero}_{slot}")
            vectors.add(geometry)
    if total > 10 * 1024 * 1024:
        raise RuntimeError(f"fantasy art pack too large for normal Git: {total} bytes")
    print(f"Fantasy original SVG assets: {len(FILES)} files, {total} bytes, valid XML, size limit passed")


if __name__ == "__main__":
    validate()
