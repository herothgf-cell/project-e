#!/usr/bin/env python3
"""Run Project E's actual Godot checks; no third-party Python dependencies."""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], expected: str | None = None, timeout: int = 60) -> str:
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout, check=False)
    output = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
    print(output, end="" if output.endswith("\n") else "\n")
    if result.returncode != 0 or re.search(r"(?m)^\s*(?:SCRIPT )?ERROR:", output):
        raise RuntimeError(f"Godot check failed (exit {result.returncode})")
    if expected is not None and re.search(expected, output) is None:
        raise RuntimeError("Godot did not print the expected completion result")
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"),
                        help="Path to the Godot 4.7.2 Standard executable")
    parser.add_argument("--long-match", action="store_true",
                        help="Continue six bots to a natural finish (up to 1860 simulated seconds)")
    args = parser.parse_args()
    if not args.godot:
        parser.error("Provide --godot with your Godot executable path")
    root = Path(__file__).resolve().parents[1]
    expected_version = (root / ".godot-version").read_text(encoding="utf-8").strip()
    executable = str(Path(args.godot).resolve())
    print("Checking the pinned engine version", flush=True)
    version = run([executable, "--version"]).strip()
    if not version.startswith(expected_version + ".stable."):
        raise RuntimeError(f"Expected {expected_version}.stable.*, got {version}")
    base = [executable, "--headless", "--path", str(root / "game" / "project-e")]
    print("Importing project", flush=True)
    run(base + ["--editor", "--import"])
    checks = (
        ("Original movement rules", "test_bas_motion.gd", "Bas motion"),
        ("Original physical scene", "test_probe_scene.gd", "Probe scene"),
        ("Combat and hero abilities", "test_battle_rules.gd", "Battle rules"),
        ("Lanes, bots and match lifecycle", "test_battle_match.gd", "Battle match"),
        ("Playable scene and UI routing", "test_battle_scene.gd", "Battle scene"),
        ("Cell tiers, turret boundaries and attack-move", "test_next_combat.gd", "Next combat"),
        ("Shared vision presentation and cell labels", "test_team_vision.gd", "Team vision"),
        ("Attack-move input, target priority and help", "test_next_input.gd", "Next input"),
        ("Wall-clipped area previews and effects", "test_effect_geometry.gd", "Effect geometry"),
        ("Raised XP platforms, ramps and high-ground sight", "test_elevation.gd", "Elevation"),
        ("R30 high-ground support rotation layout", "test_r30_layout.gd", "R30 layout"),
        ("Consumable purchase, recovery and interruption rules", "test_consumables.gd", "Consumables"),
        ("Shop, inventory and consumable input", "test_consumable_input.gd", "Consumable input"),
        ("Bot purchase and consumable decisions", "test_consumable_ai.gd", "Consumable AI"),
        ("Observed cell spawns and actual personal XP feedback", "test_xp_feedback.gd", "XP feedback"),
    )
    for label, script, result_label in checks:
        print(f"Checking {label}", flush=True)
        command = base + ["--script", f"tests/{script}"]
        if script == "test_battle_match.gd" and args.long_match:
            command += ["--", "--long"]
        run(command,
            rf"{re.escape(result_label)}: \d+ checks, 0 failures",
            timeout=300 if script == "test_battle_match.gd" else 60)
    print("Starting the main scene", flush=True)
    run(base + ["--quit-after", "90"])
    print(f"PASS: Godot import, all {len(checks)} behavioral suites and main-scene startup")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
