# Three-lane Battlefield Implementation Plan

> For agentic workers: execute the scoped tasks with tests and one independent final review. User request already authorizes implementation, design documents in `doc/design`, and visual concepts.

**Goal:** 기존 Godot 이동 진단을 3라인·3영웅·기본 공격·Q/W/E/R·봇 교전·공성·승패가 연결된 오프라인 플레이 버전으로 확장한다.

**Architecture:** 표시와 입력은 Godot 3D 장면, 전투와 경기 상태는 고정 시간으로 진행하는 GDScript 시뮬레이션에 분리한다. 같은 시뮬레이션에 사람 명령과 봇 명령을 넣으며, 기존 이동 진단과 테스트는 유지한다. 현 단계는 한 프로세스 안의 로컬 판정이며 온라인 서버 권위를 구현했다고 부르지 않는다.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, Compatibility, 30Hz simulation, Windows-first source project.

**Spec:** `docs/01-core-rules.md`, `docs/characters/01-bas.md`, `02-rio.md`, `03-nema.md`, `docs/content/02-arena-and-objectives.md`. 구현 차이는 새 `doc/design`에 명시한다.

## User request and implementation decisions

- 사용자 요청: 3라인 전장, 기본 공격, 나머지 스킬, 영웅 간 전투 구현. 콘텐츠별 기획서는 `doc/design`. 게임과 캐릭터 이미지 시안 제작.
- 구현 기본값: 한 명이 바스·리오·네마 중 선택, 같은 팀 두 명과 상대 세 명은 봇. 같은 팀 영웅 중복 없음.
- 일반 경기는 레벨 1·초기 2포인트로 시작. 별도의 기술 체험 옵션은 레벨 3·R 해금으로 시작하며 연습 조건임을 화면에 표시한다.
- 게임 한 판은 병력 전진, 외곽→내곽→핵 파괴, 사망·부활, 성장으로 연결한다.
- 기존 M01 좌표와 초기 3종 기술의 핵심 기하·타이밍·비용을 따른다. 자동매칭·Steam·인터넷 대전은 이 작업에 포함하지 않는다.
- 아트 제안: 밝은 도자기/구리/목재/천 수로 공방. 실제 화면은 식별 가능한 임시 3D 자산, 생성 이미지는 별도의 목표 시안.
- 검토한 구성: 바스 1명만 확장하면 나머지 영웅의 상호작용을 확인할 수 없고, 온라인부터 만들면 이번 조작·전장 요청의 피드백이 늦어진다. 따라서 3종을 갖춘 오프라인 봇 경기를 먼저 구현한다.

## Shared interfaces

`game/project-e/scripts/battle/battle_state.gd` extends `RefCounted`.

```gdscript
var units: Dictionary # int ID -> entity Dictionary
var effects: Array # active telegraphs and resolved visual effects
var projectiles: Array
var controlled_id: int
var time: float
var winner: int # -1 running, 0 west, 1 east, 2 draw
var events: Array # bounded event log for UI
var map # map helper

func reset(hero_key: String = "bas", practice: bool = false) -> void
func step(delta: float) -> void
func command_move(actor_id: int, target: Vector2) -> bool
func command_attack(actor_id: int, target_id: int) -> bool
func command_cast(actor_id: int, slot: String, target: Vector2) -> bool
func command_stop(actor_id: int) -> void
func invest(actor_id: int, stat: String) -> bool
func is_visible(team: int, unit_id: int) -> bool
func get_cast_preview(actor_id: int, slot: String, target: Vector2) -> Dictionary
```

Entity required display fields: `id`, `kind` (`hero`, `minion`, `tower`, `core`, `cell`, `pin`), `team` (0/1; cells 2), `hero` (`bas`/`rio`/`nema` or empty), `name`, `pos` (`Vector2` x/z; +y north), `facing` (`Vector2`), `radius`, `alive`, `hp`, `max_hp`, `shield`, `energy`, `max_energy`, `level`, `xp`, `points`, `r_unlocked`, `cooldowns` (Q/W/E/R seconds), `respawn_left`, `lane` (0 north,1 center,2 south), `phase`, `locked`. Extra simulation fields are allowed; UI uses defaults for optional values. `last_error` should describe a rejected player command.

Effects and previews: dictionaries with `shape` (`circle`, `cone`, `line`, `triangle`), `origin`, `target`, optional `points`, `radius`, `width`, `angle` (degrees), `team`, `remaining`, `duration`, `telegraph`, `valid`. UI can inspect these, never infer damage independently. Projectiles expose `pos`, `team`, `kind`, optional `target_pos`.

Map public methods/data: `lane_paths` (three arrays of Vector2), `connectors` (four pairs), `blockers` (Rect2 array), `is_walkable(point: Vector2, radius: float = 0.45) -> bool`, `find_path(start: Vector2, end: Vector2) -> Array`. UI geometry must match map data; use +north simulation y -> negative Godot z.

Input convention: RMB floor move/enemy attack; Q/W/E/R then LMB confirmation; Esc cancel aim or pause menu; S stop; G growth; B return-to-base movement; mouse wheel zoom; Space camera recenter. Do not hijack typing in UI. Start screen chooses hero/practice; result can restart.

## Global constraints

- Preserve `combat_probe.tscn` and existing movement tests.
- Keep core rules in dedicated scripts; do not put damage rules in drawing code.
- Invalid/NaN/out-of-range casts cost nothing; accepted interrupted casts do not refund.
- Cap all per-stage hits, remove dead owner devices, enforce cooldown/resource checks.
- R gate and growth options must be usable through the UI; practice conditions must be explicit.
- Record what is implemented, simplified, and untested. Never label AI/manual/online checks as performed without evidence.
- No downloaded third-party art. Generated concept art is a visual proposal and does not replace gameplay screenshots.

## Review focus

1. Navigation from all spawn points into every lane and around towers; no water/wall tunneling during dash.
2. Same-stage repeated hits, friendly fire, dead targets, ability interruption and stale device references.
3. Hidden enemies and click targets, especially minimap / effects / HUD disclosure.
4. Core unlock, simultaneous core deaths, restart clearing all old state, and a full bot simulation terminating or retaining legitimate pressure.
5. UI command routing, no mouse clicks through panels, selectable hero and R access, visible ground and readable HUD.

## Task 1 — Battle simulation and rules

Owner: battle implementation worker. Files: `scripts/battle/*`, `tests/test_battle_rules.gd`, `tests/test_battle_match.gd`.

- [x] Write and run failing battle tests covering damage/shields, target validity, all three kits, lane waves, siege locks, death and respawn.
- [x] Implement map navigation and the shared interface; communicate any necessary additions before consumers diverge.
- [x] Implement the 3 heroes, minions, structures, progression, bot commands and bounded visual events.
- [x] Run those behavioral tests and a longer deterministic bot simulation. Provide actual outputs and clear limitations.

## Task 2 — Playable scene and presentation

Owner: scene implementation worker. Files: `scripts/presentation/*`, `scenes/battlefield.tscn`, `tests/test_battle_scene.gd`.

- [x] Build the battlefield from map data and give heroes distinct silhouettes.
- [x] Add character selection, camera, contextual RMB, aim/confirm, previews, HP/energy/cooldowns, growth, minimap and results/restart.
- [x] Test input routing and scene initialization against the real shared interface; inspect a rendered frame when available.

## Task 3 — Content documents

Owner: design documentation worker. Files: `doc/design/*.md` and `doc/design/characters/*.md` only.

- [x] Write the document index and element-level specs for loop, map, combat, heroes, growth/economy, AI, UI, art and verification.
- [x] Preserve numeric source authority; distinguish current local implementation from planned online/Steam content.
- [x] Cross-check document links and implementation status after code integration.

## Task 4 — Visual concepts and integration

Owner: root. Files: `doc/design/assets`, image briefs, README/index/status, quickstart, project main scene, verification helper.

- [x] Generate a battlefield/HUD concept and a 3-character concept sheet with the image tool; inspect and save repository references if files are supplied.
- [x] Integrate the new main scene and verification commands, run old and new tests with the pinned engine.
- [x] Perform fresh independent code review and fix material defects with regression checks.
- [x] Update user-facing run instructions and honest validation record; prepare GitHub main publication through a checked commit.

## Execution ledger

- 2026-10-26: Base `0bda61d316b2b54dfafe8bb8d88e65715b593c60`; clean isolated branch `feat/three-lane-battlefield`. Existing docs establish the 3 heroes and M01 map. User's new `doc/design` path supersedes the older documentation placement for new content design.

- Continuation recovery: original uncommitted work recovered from the previous session into a clean clone at base `0bda61d`; same branch intent preserved. Recovered battlefield and hero concept PNGs, battle rules/tests, presentation helpers and content drafts. Missing AI/controller/scene and hero docs are being completed in scoped parallel work.
- Integration: main scene now targets battlefield; verification helper covers original two suites plus three battle suites. Korean UI font (Noto CJK subset, all Hangul) bundled with OFL. Original probe is retained. Actual result counts and rendering evidence will be recorded before completion.
- Delivery transport: direct git push has no CLI credentials; use connected GitHub API and expected-head check. A large image-blob request was interrupted without a confirmed receipt; inspect by deterministic blob hash before retrying. Do not claim remote publication without checking the branch ref.

- Final review fix: a newer accepted attack during basic windup could leave a queued W intact. `test_new_attack_replaces_queued_cast` reproduced 4 failures (energy82, cooldown4.633, shield135 after replacement); immediate accepted attack now clears the prior queued command. Rules suite115/115 green. Invalid newer target still preserves the valid queue.
- Natural full-bot diagnostic before final review fixes: six normal-start bots, no forced damage or modified constants, East victory at1211s (20m11s),11towers destroyed,22hero deaths; actual combat ends the game. This exceeds the12–18minute target hypothesis and does not establish player-versus-bot or human balance.

- Final review fix: persistent Nema0.5m link, Rio W mark/expiry arc, and fixed Q return route were missing; enemy line effects also exposed hidden endpoints. Scene regression96checks/13failures RED→96/96 GREEN. Renderer now reads persistent authority state and clips enemy line geometry to observed portions.
- Final: minor (deferred): overlapping click targets use projected distance and may include locked structures, rather than hero-first priority. Recorded in doc/design/10-differences; affects selecting closely overlapping units, not the validated command/damage authority.
- Final scope rulings: online/Steam/reconnection remain outside this offline request (risk: no internet play claim); human balance/fun and12–18minute duration need actual playtests (risk: observed bot result is not human balance); final art/audio, shop, advanced bots, target cycling and configurablekeys remain documented follow-ups (risk: prototype lacks those product features); wall-unclipped circle/cone outlines and1m-grid optimality are disclosed (risk: outline can cross a wall and paths need not be shortest); final tests/publication require fresh root evidence below.

- Fresh final integration: pinned Godot 4.7.2, import and all five suites passed (Bas 40, probe 19, rules 115, extended match 1922, scene 96; 2192 checks, zero failures), main scene starts, exit0. The post-fix natural match repeats East victory at1211s,11towers,22hero deaths; see doc/design/verification/2026-10-26-headless.log. Actual software-OpenGL frame capture also exits0; final screenshot helper checks the return projectile phase and active pin link.
