# Playable Visual Slice Implementation Plan

> Executed inline under the user's explicit autonomous implementation request. Existing main integration workflow is authorized. Final review is self-review; no subagent review tool was available.

**Goal:** Deliver actual playable camera/character/map/skill presentation and visible XP/support bot objectives.

**Architecture:** Extend the existing battlefield/arena with focused subclasses. Preserve battle authority and balance. New TacticalAI is injected by the playable scene; raw-state legacy AI remains a comparison baseline. Models are original modular engine meshes with visual joint posing, not final sculpted/skinned assets.

**Tech:** Godot 4.7.2 Standard, GDScript, real Linux headless/GL and Windows CI, existing packaging tool.

**Spec:** User 2026-10-29 request; doc/design/07-art-direction.md; R10/R31 backlog. Final evidence: doc/design/18-playable-visual-slice.md.

## Design decisions

- Camera proposal: perspective FOV42, pitch55; view spans30/50/18; F6 modes, Y follow, existing Space/drag/minimap, focused nonmodal edge pan. Not measured original-video values.
- Preserve all hero/XP/tower/consumable numeric values, footprints and high-ground sight contracts.
- Ceramic/copper/workwear palette; three original playable articulated silhouettes; Bas first close-review character.
- Terrain detail uses fog-aware materials and does not create new collision/walkability.
- Skill accents read current visibility and real phase/effect geometry; no damage logic.
- Bots use observed targets and bounded tasks; own-core defense, support, cell reservation, lane return and respawn clearing.
- Final roster art, detailed animation/audio, global team strategy and online transport remain outside this checkpoint.

## Completed tasks and evidence

- [x] Wrote AI/camera behavioral tests before implementation. Playable slice #1 (40826102787) RED: missing policy/preset.
- [x] Added bounded observed cell/support/defense AI using real authority commands.
- [x] Added perspective presets/input and real height-field click intersection.
- [x] Added hero rigs, cosmetic masonry and visible combat accents to actual battlefield.tscn.
- [x] Existing full regression: #54 (40828433640), 16 suites/3,633 checks/zero failures.
- [x] New regression: #14 (40828433627), 18 objective +34 playable +13 lifecycle checks/zero failures.
- [x] Ran actual enhanced six-bot match to core destruction at1,333.0s, winner1; recorded objectives and XP grant count.
- [x] Captured 102 actual renderer PNGs and reviewed representative combat/lineup/skill pixels.
- [x] Built Windows release using verified official editor/template archives and existing packaging checks.
- [x] Windows preview #3 (40828433632): exported EXE headless startup on Windows runner passed.
- [x] Downloaded artifacts; verified archive CRC, hashes and PE/PCK headers locally. Local Godot execution was not claimed.
- [x] Documented current implementation, old/new AI distinction, visual limitations and next review scope.

## Rulings and review ledger

Base: ecefca1a0e1367162380daac8f87a14eda44200a.
Game head: 032c8add4682f4e1e1da2bff9a71c38e9390c2df.
Tested PR merge snapshot: c1c0cb49efb434be480406f43e023d1631e4ffe8.

Ruling: no local engine/repo or working outbound DNS — use isolated GitHub feature branch and actual pinned-engine CI; obtain output bytes through the GitHub artifact download connector.
Ruling: an abort at the exact home point correctly finishes return immediately — split test into off-home lost-sight and on-home completion assertions, preserving target/cooldown requirements.
Bug: respawn reused a hero dictionary with stale objectives. Lifecycle test failed in #12 (40828003579); clear objectives when death count changes. #14 passed unchanged lifecycle requirement.
Ruling: map/roster remains a first playable art pass. Capture review is not final-art approval, Windows headless is not manual graphics/input verification.
Final review: self-review (no subagent tool). Read inheritance/lifecycle, fog/target filtering, input/modal boundaries, capture cleanup and artifact provenance separately. No unresolved blocking code issue found in this scope. Remaining visual polish, global AI and human balance are recorded, not silently completed.

Integration: merge only this verified code plus documentation-only changes with an expected-SHA lease against the unchanged main base; confirm resulting main workflow status before final completion claim.
