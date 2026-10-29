# R30 High-Ground Support Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect each 40 XP high-ground platform to its adjacent support connector with a second ramp so collecting the objective creates a fast lane-support and tower-retreat choice.

**Architecture:** Keep the existing 2D authority and 2.5D height field. Add symmetric data-driven high-ground ramps to `battle_map.gd`; pathfinding remains AStarGrid2D over the same authority footprint. Presentation reads the same ramp data for 3D surfaces and minimap lines, while tower/XP values remain unchanged.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, Compatibility renderer, GitHub Actions regression suite.

**Spec:** `doc/design/14-tempest-reference-reprioritization.md` and `doc/design/15-high-ground-verification.md`.

## Global Constraints

- Preserve XP values 20/30/40, cell HP 180, first spawn 30 seconds and respawn 45 seconds.
- Preserve all 12 tower positions, 8.5m attack range, 12m sight and current structure stats in this task.
- Preserve existing lane paths, four original support connectors, wall rectangles and structure collision radii.
- Add geometry symmetrically under 180-degree rotation.
- Do not grant cells, pins or return marks vision.
- Do not change hero abilities, movement speeds, damage, cooldowns or consumables.
- Hidden enemy/cell state must remain hidden; only static terrain may be public on the minimap.

## Review Focus

- The new route must not overlap a tower collision circle enough to make the corridor impassable.
- The second ramp must not create an off-ground shortcut outside the declared 3m corridor.
- Height must be continuous at plateau and lane endpoints so models and telegraphs do not jump.
- AStar should prefer the new route for high-ground-to-support rotation without breaking the original lane ramp.
- Minimap and 3D rendering must use map data rather than duplicate hard-coded coordinates.

---

### Task 1: Authority layout and path contract

**Files:**
- Modify: `game/project-e/scripts/battle/battle_map.gd`
- Create: `game/project-e/tests/test_r30_layout.gd`
- Modify: `tools/check_godot.py`

**Interfaces:**
- Produces: `high_ground_ramps: Array[Dictionary]` entries with `high: Vector2`, `low: Vector2`, `kind: String`, `width: float`.
- Produces: `ramps_for_high_ground(center: Vector2) -> Array`.
- `ground_height(point)` and `_ground(point, margin)` consume the same ramp list.

- [ ] **Step 1: Write the failing test**

Add `test_r30_layout.gd` asserting:
- Four ramps exist: two original lane ramps and two new support ramps.
- Northwest support ramp is `(-18,24) -> (-12,18)` and southeast is its 180-degree mirror.
- Every ramp is 3m wide and endpoints are walkable.
- Ramp height is 2.4m at the plateau edge, approximately 1.2m halfway and 0m at the low endpoint.
- Path from northwest high ground to west-north connector endpoint `(-10,18)` is shorter with the support ramp than a route forced through `(-18,18)`.
- Corridor samples avoid tower collision and remain inside declared ground.

- [ ] **Step 2: Run CI and verify RED**

Open a PR from the feature branch so the existing pull-request workflow runs. Expected: `test_r30_layout.gd` fails because `high_ground_ramps`/support ramps do not exist.

- [ ] **Step 3: Implement the minimal authority data and queries**

Refactor the existing high-ground height logic to consume `high_ground_ramps`. Add the two support ramps and include all ramps in `_ground`; keep AStar generation unchanged so it automatically indexes the new corridor.

- [ ] **Step 4: Run CI and verify GREEN for authority tests**

Expected: new R30 suite passes and existing elevation/path suites stay green.

### Task 2: Shared 3D and minimap presentation

**Files:**
- Modify: `game/project-e/scripts/presentation/arena_view.gd`
- Modify: `game/project-e/scripts/presentation/tactical_map.gd`
- Extend: `game/project-e/tests/test_r30_layout.gd`

**Interfaces:**
- Consumes: `map.high_ground_ramps` and `map.ramps_for_high_ground(center)`.
- Produces no new gameplay authority.

- [ ] **Step 1: Extend the test first**

Assert that:
- Arena rendering creates two ramp surfaces for each 40 XP platform from map data.
- Support ramps use a visually distinct support-route material/rail marker.
- Tactical map exposes all four ramp segments and does not reveal unit/cell state.

- [ ] **Step 2: Verify RED**

Expected: presentation assertions fail before rendering/minimap changes.

- [ ] **Step 3: Render all data-driven ramps**

Replace the one-ramp hard-code in `_elevated_cell_access` with iteration over `ramps_for_high_ground`. Build each slope with a basis aligned to its arbitrary diagonal. Draw static high-ground ramp lines on the minimap.

- [ ] **Step 4: Verify GREEN**

Run the full GitHub Actions Godot regression. Expected: all suites and main-scene startup pass without engine errors.

### Task 3: Documentation and integration

**Files:**
- Modify: `doc/design/02-map-m01.md`
- Modify: `doc/design/11-remaining-development.md`
- Modify: `doc/design/14-tempest-reference-reprioritization.md`
- Create: `doc/design/16-r30-high-ground-flow-verification.md`
- Modify: `README.md`

- [ ] **Step 1: Record exact geometry and gameplay intent**

Document the two additional ramps, their endpoint coordinates and the intended loop: 40 XP platform → support ramp → existing connector → central lane, while the original ramp remains the lane-return route.

- [ ] **Step 2: Record evidence boundaries**

Record CI run/commit, exact assertion count and remaining unverified items: human route preference, Windows performance, tower dive balance, bot objective selection.

- [ ] **Step 3: Final review and fast-forward main**

Compare the feature branch against its base, verify only planned files changed, then fast-forward `main` with an expected-SHA lease after CI is green.
