# Fantasy V4 — Combat Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps are checkboxes for tracking.

**Goal:** V3 3등신 모델의 실루엣/모션, 실제 QWER 카툰 VFX, 간결한 로컬 전투 SFX를 강화한다.
**Architecture:** `hero_rig.gd`는 권한을 건드리지 않는 관절 메시와 additive pose, `skill_vfx.gd`는 기존 시야 승인 표본에만 새 룬 메시, `fantasy_audio.gd`는 제어 중인 영웅의 상태 변환만 감지.
**Tech Stack:** Godot 4.7.2 GDScript, 16-bit RIFF PCM mono WAV, GitHub Actions.
**Spec:** `doc/design/23-fantasy-v4-combat-presentation.md`

## Global constraints
- Battle state, hit radius, timing, fog, map geometry and camera stay unchanged.
- No external model/audio dependencies; assets must be small and distributable.
- F7 isolated review must not leak VFX/audio to the original match.

## Review focus
- Idle/walk transition must not accumulate root offsets.
- A hero with missing or empty cast must not play cast SFX.
- Two consecutive casts of same slot must each trigger exactly one SFX.
- Local levelup and hit events must not replay after pause/restart.
- Enhanced VFX must not reveal LOS-occluded or out-of-sight points.

### Task 1 — RED contract
- [ ] Add `test_fantasy_v4.gd` for 3 silhouettes, non-mutating animated offset, VFX identity, audio 5 files and cues.
- [ ] Run GitHub Actions and verify the expected failure on unimplemented V4.

### Task 2 — Hero models and additive motion
- [ ] Add `WeaponDetail`, `HairDetail`, `RuneEmblem` nodes and recognizable prop meshes for all three kits.
- [ ] Add clip-specific additive bob/recoil in `pose` using battle time without touching authority.
- [ ] Verify existing walk, attack, death, respawn and new checks.

### Task 3 — Skill VFX
- [ ] Add `style_for(hero_key,slot)` to define 12 distinct effect treatments.
- [ ] Render short glyphs/embers/leaves only inside existing sight/LOS/contains-gated sample loop.
- [ ] Verify red/green new tests and original V2 LOS regression.

### Task 4 — Original audio and observer
- [ ] Generate five small mono 16-bit WAV files with no borrowed audio.
- [ ] Add `fantasy_audio.gd` with local controlled hero phase/damage/level observation and dedup.
- [ ] Wire to playable scene with review-stage mute and selection/restart reset.
- [ ] Verify first-event vs repeated-frame vs hidden-enemy tests.

### Task 5 — Integration and review
- [ ] Update F7 header, README and art-asset inventory.
- [ ] Run `tools/check_godot.py` plus 12-ability render capture and Windows preview in CI.
- [ ] Review diff for battle state edits, asset size and visibility bugs, then PR to main.
