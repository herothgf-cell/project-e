# V9 Vertical Battlefield and Core Siege Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for integration and superpowers:test-driven-development for behavioral changes. The user authorized resuming implementation; routine design choices are recorded below without another approval pause.

**Goal:** Present the COT-inspired three-lane battlefield vertically and remove avoidable bot core-siege stalls.

**Architecture:** Preserve the tested simulation coordinate system and share one presentation basis across camera, controls and minimap. Reassign healthy bots leaving home to a publicly open lane, capped at two allied heroes per lane, then compare natural matches against the recorded V8 baseline.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, Python packaging.

**Spec:** `doc/design/30-v9-vertical-siege.md`

## Global Constraints

- Keep original fantasy art, eight heroes, three-lane offline 3v3 and public-state fog rules.
- Do not infer exact original game values from low-resolution video frames.
- Keep simulation positions and combat parameters unchanged in the first controlled experiment.
- Main verification engine: `4.7.2.stable.official.ed1daf0bf`.
- Do not edit the original V8 audit or its recorded data as if it described V9.

## Review Focus

- Camera and minimap must agree at all four corners and both bases, including fog and input inverses.
- 960×540 UI must keep minimap and world input separate after portrait-map fitting.
- Lane reassignment must not exploit hidden enemy state or bypass existing tower danger checks.
- Retreat, home defense, busy phases and active tactical tasks retain priority. Clear previous-life state before checking a fresh departure; a dead ally still reserves its lane for respawn.
- Faster endgame must not come from forced winners, shortened early waves or silently disabled existing tests.

## Task 1: Unified vertical presentation

**Files:** shared presentation helper if needed; `battlefield.gd`, `playable_battlefield.gd`, `tactical_map.gd`, presentation lane/team labels; `tests/test_vertical_map_v9.gd`, existing camera tests.

**Interfaces:** Existing commands continue to consume simulation `Vector2` points. The display basis maps simulation `+x` to screen up and simulation `+y` to screen left; both forward and inverse functions must agree.

- [x] Add behavioral assertions for both bases, lane order, world projection and minimap inverse, pan/drag directions and fog alignment. Run against V8 and retain expected failures.
- [x] Apply the shared display basis across camera, pan, drag, minimap terrain/fog/viewport and labels.
- [x] Run presentation regression and actual 720p/540p captures. Verify clicks and edge movement on the displayed map.

## Task 2: Open-lane redeployment

**Files:** `scripts/battle/tactical_ai.gd` and minimal related AI helpers only if required; `tests/test_siege_v9.gd`; `tools/measure_siege.gd` and comparison evidence under `doc/design/verification/v9-20261110/`.

**Interfaces:** Use existing state commands and observation gates. Existing retreat and defense decisions retain priority. Only public structure destruction and allied lane assignments inform the new decision; no direct HP mutation or synthetic victory.

- [x] Compare individual explanations. Core-priority tasks did not improve natural completion; home departure onto an open lane did. Preserve negative results.
- [x] Reproduce the fixed-lane behavior in isolated tests; capture RED, then add the smallest safe reassignment supported by the experiment. Keep unit and structure balance values fixed.
- [x] Verify healthy home departures, capacity limits, current open lanes, defense/retreat priority, hidden defenders and respawn reservations. Existing tactical/minion suites are included in the full final verifier.
- [x] Compare the original six-bot fixture and additional roster compositions through natural end or an explicit observation cap, retaining summaries, source hashes and conditions.

## Task 3: Integrated verification and delivery

**Files:** `tools/check_godot.py`, project version, game hub/README, verification report and source evidence; Windows package tooling only if a new version label requires it.

- [x] Add new behavioral suites to the standard verifier and run the full existing suite without removing checks.
- [x] Render the actual game, inspect the vertical map/HUD and test exported PCK input/startup; create Windows package.
- [x] Have a separate reviewer inspect the whole diff and resolve material findings with evidence.
- [x] Publish the source changes and build, link the exact verification evidence and summarize measured improvement and remaining limits.

## Execution Notes

- Existing checkout is a fresh isolated clone on `codex/v9-vertical-siege`; there is no user working tree to disturb.
- Baseline regression was started before production edits. Research, presentation and siege diagnosis run independently with separate file ownership.
- A common view basis was chosen after reviewing the original map evidence. No observation requires changing the engine's internal axes.
- The initial core-objective hypothesis was replaced after controlled experiments. Home redeployment capped at two heroes retained early combat exactly and removed the observed stall without changing combat values.
- Product code `200df52e018e46b5b7847bfd808c59206dca7a75` was published in PR #11. All four source CI workflows passed; the delivered Windows artifact also passed its actual Windows startup job. Final documentation and preserved evidence accompany the same PR.
