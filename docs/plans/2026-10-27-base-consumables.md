# 기지 상점과 소모품 Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans. Execute all already-authorized tasks; root owns integration and GitHub publication.

**Goal:** 크레딧→기지 구매→선택→D 사용→회복/중단을 실제 경기와 봇에 연결한다.

**Architecture:** `battle_consumables.gd`가 두 품목의 공통 검사와 지속 회복을 맡고 `battle_state.gd`가 공개 명령을 제공한다. HUD와 봇은 동일 명령을 사용하며 `battle_rules.gd`의 유효 피해/사망 경계에서 회복을 중단한다.

**Tech Stack:** Godot4.7.2 Standard, GDScript, Compatibility, Python 표준 라이브러리 패키징.

**Spec:** [설계](2026-10-27-base-consumables-design.md).

## Global Constraints

- I01: 40크레딧, 에너지40/2초. I02: 50크레딧, HP200/4초. 합산2개, 공유12초 사용 쿨타임.
- 자기 기지의 살아 있는 영웅만 구매. 죽으면 효과만 종료하고 재고/선택 유지, 쿨타임은 계속 감소.
- 수리 패치는 유효 적 영웅 귀속 피해(장치·지속·보호막 포함)로만 중단. 병력/탑 피해·무효 피해는 제외.
- G 성장/B 기지 이동 유지. P 상점/D 사용, 슬롯 클릭은 선택만. 기존 전투 명령·조준 보존.
- 로컬 상점은 일시정지; 모달 상호 배제·직전 상태 복원·뒤 전장 입력 차단.
- 봇은 동일 권한 API, 자기 상태만 사용. 조작 영웅 자동 소비 금지.
- 기존 시야·성장·전투/구조물 수치와 틱 순서 유지. 외부 의존성·장비/계정 재화 추가 금지.
- 실제 Windows PC/사람 경기 미실시 상태를 자동 검사로 완료 처리하지 않는다.

## Review Focus

- 버튼이 오래된 구매 가능 상태를 보여도 실제 명령은 현재 돈·위치·재고를 재검사한다(Task1/2).
- 패치 중단은 최근 도움 기여자가 아닌 실제 피해 소유자를 사용한다(Task1).
- 반복 입력과 쿨타임0 경계에서 재고나 돈을 두 번 쓰지 않는다(Task1/2).
- 상점 클릭/닫기/모달 전환이 A 조준이나 이동을 발생시키지 않는다(Task2).
- 봇이 플레이어의 선택·last_error를 덮거나 사망/기지 밖에서 구매하지 않는다(Task3).

## Task 1: 권한 소모품 규칙

**Files:** create `game/project-e/scripts/battle/battle_consumables.gd`, `game/project-e/tests/test_consumables.gd`; modify `battle_state.gd`, `battle_rules.gd` in the same battle directory.

**Interfaces:** Battle state provides:

```gdscript
func is_in_home_base(actor_id: int) -> bool
func consumable_purchase_error(actor_id: int, item_id: String) -> String
func consumable_use_error(actor_id: int, item_id: String = "") -> String
func command_buy_consumable(actor_id: int, item_id: String) -> bool
func command_select_consumable(actor_id: int, item_id: String) -> bool
func command_use_consumable(actor_id: int) -> bool
```

Catalog `battle_consumables.gd.ITEMS` has I01/I02 fields `name`, `cost`, `resource`, `amount`, `duration`. Each hero has `consumables = {"I01":0,"I02":0}`, `consumable_selected = "I01"`, `consumable_cooldown = 0.0`, `consumable_effect = {}`. Active effect fields: `item_id`, `remaining`, `rate`. Preview error methods are read-only and return empty string on success. Selection of an empty item is allowed and never auto-swaps after use. Human-readable errors flow through existing `last_error` and UI translations. Controlled-only events `consumable_purchase`, `consumable_use`, `consumable_end` include `target_id`, `item_id`; end includes reason `completed`/`interrupted`/`death`.

- [x] Write behavioral tests: both home rectangles and exclusive far edges; exact40/50 price; insufficient funds and combined2 cap; invalid/other unit; full resource; CD/repeat calls; buy duringCD and combat; use offbase while moving/casting/CC preserves command.
- [x] Run test red before production changes; preserve red output.
- [x] Implement helper + wrappers. Reuse same base predicate for regen and purchases. Tick sharedCD before dead return; HoT only living heroes. Damage hook after applied>0 and actual owner resolution; death hook clears active effect.
- [x] Test literal40/2s and200/4s with base/natural regen isolated; partial/max capping; normal regen additive; interruption by hero/device/shield vs minion/tower/protection/duplicate/CC; actual lethal hit, respawn, reset, ended match.
- [x] Run targeted suite and relevant battle regressions; report exact commands/output. Root reviews and publishes.

## Task 2: 실제 상점·재고·입력

**Files:** modify `game/project-e/scripts/presentation/battle_hud.gd`, `battlefield.gd`; create `game/project-e/tests/test_consumable_input.gd`, `capture_consumables.gd`.

**Interfaces:** Consume Task1 public methods/catalog/fields. HUD emits `shop_requested`, `shop_closed`, `consumable_purchase_requested(item_id)`, `consumable_selected(item_id)`, `consumable_use_requested`. Scene owns `open_shop`, `close_shop`, `shop_visible`, `buy_consumable`, `select_consumable`, `use_consumable`; only scene calls state mutations. `hud.shop` is the modal; HUD updates stock/cooldown/reasons from authority.

- [x] Test new P/D/selection behavior red in actual loaded battlefield scene.
- [x] Build compact inventory strip above skill panel (720p: x18..width−298, yheight−240..−184); adjust hint so it does not overlap. Show credits, two counts, selected item, P, D, cooldown and active recovery. Do not show enemy stock.
- [x] Build two-card shop, prices/effects/limits/reasons and close; inspectable offbase/dead but purchases disabled. Validate again at click; reject with Korean reason. Block background and all gameplay commands while open. Restore previous pause state on close.
- [x] Wire P/Esc, modal reciprocity, reset/selection/result cleanup, all `blocks_point` surfaces. D and selection preserve aim/order. Update F1/start hints.
- [x] Test purchase/select/use through actual button signals and hotkeys; cooldown, full resource feedback, replay, dead/result, modal click-through, viewport720p/1080p; capture actual frames and inspect text/clipping.

## Task 3: 봇의 구매·사용 연결

**Files:** modify `game/project-e/scripts/battle/battle_ai.gd`; create `game/project-e/tests/test_consumable_ai.gd`.

**Interfaces:** Use Task1 methods. Check previews before changing selection or calling failed commands so unrelated `last_error` is preserved.

- [x] Test that real bot decisions purchase at home, spend actual credits, respect total2/stock/affordability and skip the controlled hero/disabled bots/dead heroes.
- [x] Implement stock target one I02 then one I01; at home fill missing types only. Do not alter existing movement/retreat strategy.
- [x] Offbase choose patch when HP deficit≥200 and last_damage elapsed≥2s; otherwise bottle when energy deficit≥40. Skip sharedCD; no consumable use insidebase. Use same selected-item command and preserve battle order.
- [x] Verify actual resource gain and rules denial; no outsidebase/dead purchase, no negative credits, no hidden-enemy-dependent decision, no player selection/error mutation.
- [x] Run targeted AI suite and integrated natural-match check. Report measured match as bot-only evidence, never as human balance.

## Task 4: 통합·검토·문서·Windows 전달

**Files:** update `tools/check_godot.py`, README and canonical design/controls/economy/backlog/verification docs; evidence under `doc/design/verification`, screenshots under `doc/design/assets`.

- [x] Register three new suites with explicit completion markers and full9+3suites run.
- [x] Independent task reviews + whole change review; fix actionable findings and record focused evidence. 전체 명세 PASS/코드 품질 APPROVE, 조치할 지적 없음. [최종 검토 원문과 범위](../../doc/design/verification/2026-10-27-consumables-reviews.md#whole-change-final-independent-review). 게시·새 Windows export·실제 Windows PC/사람 검증은 아래 별도 게이트로 유지한다.
- [x] Render720p/1080p shop/inventory/recovery/guide, record conditions and selected source.
- [x] Update implementation statuses without marking complete fullR06/R10/R11 or human/WindowsPC gates.
- [ ] Verify whitespace/links and commit/push source through existing GitHub authorization with remote lease.
- [ ] Build clean-source WindowsZIP with existing package tool, verify manifest/hash/ZIP/PCK startup; save durable package and record exact source commit.
- [ ] Push final documentation/evidence, verify remoteSHA/tree and clean checkouts. Deliver Korean feature/controls/test/limitation summary and download.
