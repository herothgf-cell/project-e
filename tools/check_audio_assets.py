#!/usr/bin/env python3
"""Validate original Project E V4 WAV headers and Git-size budget."""
from pathlib import Path
import wave

BASE = Path(__file__).resolve().parents[1] / "game/project-e/assets/audio"
CUES = {"slash", "arcane", "nature", "hit", "level"}
TOTAL_LIMIT = 1_000_000

def main() -> None:
    total = 0
    for cue in sorted(CUES):
        file = BASE / f"{cue}.wav"
        if not file.exists():
            raise RuntimeError(f"missing sound: {file}")
        with wave.open(str(file), "rb") as stream:
            if stream.getnchannels() != 1 or stream.getsampwidth() != 2 or stream.getframerate() != 16000:
                raise RuntimeError(f"unsupported PCM specification: {cue}")
            if stream.getnframes() < 1200 or stream.getnframes() > 6400:
                raise RuntimeError(f"invalid short cue duration: {cue}")
        total += file.stat().st_size
    if total > TOTAL_LIMIT:
        raise RuntimeError(f"audio package exceeds lightweight Git budget: {total}")
    print(f"Original combat SFX: {len(CUES)} PCM WAVs, {total} bytes, license-free synthesis")

if __name__ == "__main__":
    main()
