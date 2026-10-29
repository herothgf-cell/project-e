# R30 High-Ground Support Flow Implementation Plan

> **Execution status:** Completed on `feature/r30-high-ground-flow`; final integration follows green CI and review.

**Goal:** Connect each40XP high-ground platform to its adjacent support connector with a second ramp so collecting the objective creates a fast lane-support and tower-retreat choice.

**Architecture:** Preserve the existing2D authority and2.5D height field. Define all ramps in `battle_map.gd`; AStarGrid2D indexes the same authority footprint. A dedicated presentation node renders only new support ramps, and the minimap consumes the same map data. Tower/XP/hero values remain unchanged.

**Tech Stack:** Godot4.7.2 Standard, GDScript, Compatibility renderer, GitHub Actions.

**Spec and evidence:** [Reference priorities](../../../doc/design/14-tempest-reference-reprioritization.md) · [R28](../../../doc/design/15-high-ground-verification.md) · [R30 verification](../../../doc/design/16-r30-high-ground-flow-verification.md).

## Constraints preserved

- [x] XP20/30/40, cellHP180, first spawn30s, respawn45s unchanged.
- [x] Tower count, positions, HP, damage,8.5m attack range and12m sight unchanged.
- [x] Existing lane paths, connectors, walls and structure collision radii preserved.
- [x] New geometry is180-degree symmetric.
- [x] Cells, pins and return marks still grant no vision.
- [x] Hero abilities, speeds, damage, cooldowns and consumables unchanged.
- [x] Static terrain is public; hidden unit/cell state remains concealed.

## Task 1 — Authority layout and path contract

- [x] Added a failing R30 contract test before implementation.
- [x] Confirmed RED because `high_ground_ramps` did not exist.
- [x] Added four data-driven ramps: two legacy lane returns and two support rotations.
- [x] Added `ramps_for_high_ground()` and `ramp_high_edge()`.
- [x] Refactored `_ground()` and `ground_height()` to consume the shared ramp list.
- [x] Preserved R28 midpoint height after CI caught a1.26m regression against the1.2m contract.
- [x] Verified route shortening,3m width, off-ground rejection and tower collision avoidance.

## Task 2 — Shared 3D and minimap presentation

- [x] Added the presentation contract test before rendering changes.
- [x] Confirmed RED for missing `Arena/HighGroundRamps` and minimap ramp segments.
- [x] Added `support_ramp_view.gd` for the two new support slopes.
- [x] Built arbitrary diagonal3D bases from authority endpoints and2.4m height difference.
- [x] Reused the exact fog-aware connector ShaderMaterial.
- [x] Added copper rails to distinguish support routes without affecting collision.
- [x] Added `high_ground_ramp_segments()` and four static ramp lines to the minimap.
- [x] Verified all presentation assertions in the real battlefield scene.

## Task 3 — Documentation and integration

- [x] Documented exact coordinates and intended XP→support→central rotation.
- [x] Updated map, backlog, roadmap, reference analysis, design index and root README.
- [x] Recorded RED→GREEN CI runs and evidence boundaries.
- [x] Recorded that Windows ZIP, human play, bot objective use and online sync remain unverified.
- [x] Compared the feature branch with its base; only planned code, tests and docs changed.
- [ ] Fast-forward `main` after the final branch CI and review complete.

## Final automated result before integration

- Godot `4.7.2.stable.official.ed1daf0bf`.
-14 behavioral suites.
- R30 layout/presentation:61checks,0failures.
- Total:3,531 assertions,0failures.
- Project import and main-scene90-frame startup PASS.
- Evidence: [Godot regression #19](https://github.com/herothgf-cell/project-e/actions/runs/40811635924).
