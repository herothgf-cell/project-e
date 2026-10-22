#!/usr/bin/env python3
"""Run Project E's actual Godot checks; no third-party Python dependencies."""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], expected: str | None = None) -> str:
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=60, check=False)
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
    print("Checking movement rules", flush=True)
    run(base + ["--script", "tests/test_bas_motion.gd"], r"Bas motion: \d+ checks, 0 failures")
    print("Checking the physical scene", flush=True)
    run(base + ["--script", "tests/test_probe_scene.gd"], r"Probe scene: \d+ checks, 0 failures")
    print("Starting the main scene", flush=True)
    run(base + ["--quit-after", "90"])
    print("PASS: Godot import, rules, physical scene and headless startup")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
