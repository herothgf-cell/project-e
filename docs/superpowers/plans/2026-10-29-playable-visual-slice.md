# Playable Visual Slice Implementation Plan

> Execute inline with superpowers:executing-plans. The user explicitly delegates implementation decisions and permits art review along the way. Do not restart product clarification.

**Goal:** Deliver playable camera/character/map/skill presentation rather than another prose-only milestone, and connect visible XP objectives to bot rotations.

**Architecture:** Extend the existing battlefield and arena through focused scripts wired by battlefield.tscn. Preserve the 30Hz battle authority, existing terrain/vision/effect rules and all numeric balance. Inject an enhanced AI subclass in the playable scene; run dedicated enhanced-AI simulation tests in addition to legacy state regressions. Art consists of original in-engine modular meshes and articulated node animation: a first production-facing pass, not finished sculpted/skinned assets.

**Tech:** Godot 4.7.2 Standard, GDScript, existing GitHub regression CI plus rendered preview capture. No external paid assets or new third-party game dependencies.

**Spec:** User request dated 2026-10-29; doc/design/07-art-direction.md; R10 follow-up in doc/design/11-remaining-development.md.

## Design decisions / evidence boundary

- Keep ceramic, copper, dark workwear, mint waterways and team teal/orange. Bas is the primary quality reference; Rio/Nema remain compatible and get distinct articulated silhouettes where feasible.
- The supplied YouTube video still cannot be fetched as continuous frames. Camera values below are Project E tuning proposals, NOT measured City of Tempest values.
- Combat camera: fixed heading, oblique perspective, default vertical view span30m and pitch55degrees; tactical wider view and close art view selectable with F6. Y toggles hero follow, Space uses existing recenter, middle drag/minimap/wheel retained. Edge panning is enabled only in an active focused gameplay viewport, not on HUD/modal/aiming.
- Terrain footprints, ramps, height queries, tower positions and vision authority remain unchanged. New masonry/props are cosmetic and must use existing fog-aware materials. Do not create apparent walkable bridges outside authority ground.
- Hero rig pose follows actual unit phase/time; no new combat timing. Footprint/collision/attack ranges remain authoritative. Visual status and projectile flourishes must not reveal unseen units or home in through fog.
- Tactical AI observes only current team vision for non-public targets. Healthy bots may acquire a visible nearby XP cell, help a nearby ally, then return to their saved lane position. Low HP, visible danger, target loss and timeout abort. Own-core defense has priority. Do not take over the controlled hero or change home lane.
- Whole-roster final art, recorded sounds, online transport and full map reconstruction are out of this slice. Do not claim them done.

## Approaches

1. Finish all roster assets first: rejected; wastes effort before camera/readability review.
2. Concept images only: rejected; user specifically needs to judge actual play.
3. Playable modular art pass with adjustable camera and captures: chosen by implementation judgment under delegated autonomy.

## Files and contracts

- `scripts/battle/tactical_ai.gd`: extends existing AI; `_hero` handles bounded objectives and falls back to legacy combat. Source state remains the same authoritative commands.
- `scripts/presentation/playable_battlefield.gd`: extends battlefield; camera modes/edge pan and rig update; same public scene methods.
- `scripts/presentation/workshop_arena.gd`: extends arena; original meshes and terrain detailing with unchanged footprints/fog.
- `scripts/presentation/hero_rig.gd`: `build(key, team_color)`, `pose(unit, time)`; no simulation writes.
- `scripts/presentation/combat_accents.gd`: observed status/projectile accents; no damage or hidden-target reads.
- `scenes/battlefield.tscn`: wires new subclasses without rewriting the large existing controller/authority.
- `tests/test_playable_slice.gd`: real battlefield, camera ray roundtrips, modal/input, rig movement, fog boundaries and lifecycle.
- `tests/test_tactical_ai.gd`: real state, visible cell acquisition/abandon/return, reservations, support, player isolation, low HP and enhanced match diagnostic.
- `tests/capture_playable_slice.gd`: real renderer preview harness only; no invented mock screenshot.
- `.github/workflows/playable-slice.yml`: new tests and render capture artifacts; existing full regression stays mandatory.

## Review focus

1. New camera projection must not break elevated clicks, selection, HUD routing or minimap.
2. Art must not change footprints or silently reveal hidden targets; procedural first pass must not be called final art.
3. Objective AI must abort without reading hidden target positions and return without per-frame oscillation.
4. Restart must clear rig/effect/AI task state and retain original XP feedback.
5. Real rendering is a separate gate from headless assertions; capture must load the actual gameplay scene.

## Tasks

- [ ] Add failing behavioral tests and observe missing-feature RED on branch CI.
- [ ] Implement tactical AI with real authority commands; pass its behavioral tests.
- [ ] Implement camera presets/input and articulated hero/arena/status art; pass integration tests.
- [ ] Run all legacy regressions and enhanced match diagnostic.
- [ ] Capture real gameplay/art views and publish preview artifacts where supported.
- [ ] Self-review (no subagent tool), update current design/backlog and verify exact integrated head.

## Execution ledger

Base: ecefca1a0e1367162380daac8f87a14eda44200a.
Environment: container has no Godot/Blender/repository and direct network DNS fails; use isolated feature branch and actual pinned-engine GitHub CI. No local runtime claim.
User authorization: autonomous continuation including camera/gameplay art and prior main-push workflow; art proposals may be reviewed after a playable checkpoint. No background-work promises.
