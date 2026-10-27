# Consumables independent task reviews

## Task 1 independent review

# Task 1 independent review

## Verdict

**Spec compliance: PASS for Task 1. Code quality: APPROVE.** No actionable correctness or regression findings were identified in the reviewed scope. This review does not approve the separate shop/input or bot-policy tasks.

Reviewed the task brief, implementation report, complete `task-1-review.diff`, current versions of all four implementation/test files, and relevant live timer, damage, death, projectile and ability callers. Base: `0b1234f8918e0d5bbea2cefbab5f83c4434a9da7`.

## Requirement assessment

| Requirement | Assessment |
| --- | --- |
| I01 costs 40 and restores 40 energy over 2 seconds; I02 costs 50 and restores 200 HP over 4 seconds | Catalog literals and rate calculation agree. Tests isolate normal/base regeneration and cover real fixed ticks, partial final intervals and maximum capping. |
| Combined capacity two; shared twelve-second cooldown | Purchase checks the sum immediately before decrementing credits/incrementing stock. Use revalidates immediately before decrementing stock and setting the shared cooldown. Repeated commands cannot reuse a stale successful preview. |
| Living hero purchases only in its own base | Shared predicate validates hero identity, team and finite position and uses the original rectangles and exclusive far edges. Purchase additionally checks alive status. Regeneration reuses the same predicate without changing its combat-delay checks. |
| Read-only previews; empty selection allowed; no automatic swap | Preview paths contain no mutations. Selection does not consume or require stock. Purchase/use do not switch the selected item. Controlled-only `_reject` behavior is preserved. |
| Use during movement/casting/CC or away from base | Use validation does not impose those restrictions, and successful use changes only consumable inventory, cooldown, effect and event state. Existing orders, paths, cast, queue and CC fields remain untouched. |
| Damage interruption uses actual hostile hero ownership | Hook runs after valid positive applied damage and source-owner resolution, before contributor/reward fallback. Shield absorption counts as applied damage. Hero-owned device damage qualifies; a recent hero contributor does not turn minion/tower damage into qualifying damage. |
| Invalid damage and CC-only do not interrupt | Existing protection, friendly-source, missing-source, raw-value and duplicate-hit guards return before the hook. CC has no consumable hook. I01 is excluded by the helper. |
| Death preserves stock/selection, ends effects and continues cooldown | Death hook only clears the active consumable effect. Cooldown ticks before the dead-unit early return. Respawn does not recreate inventory or resume the old effect. Lethal damage takes the death route rather than emitting both interrupted and death end events. |
| Controlled-only events with item, target and end reason | Helper filters on controlled ID; successful purchase/use/end carry item and target. End emits the required completed/interrupted/death reason. Bot authority failures use the existing controlled-only error gate. |
| Existing values and tick ordering retained | Existing combat values and timer/actor/projectile/device phase order are unchanged. Healing is added after ordinary hero regeneration in the timer phase. Same-tick projectile interruption is explicitly tested. |
| Reset and completed match | Hero creation initializes independent dictionaries, including synthetic heroes. Reset rebuilds defaults. Match-end checks reject purchase/use, and the existing step guard freezes timers/effects. |

## Code quality assessment

The small dedicated helper keeps catalog, validation and state transitions together, while public state wrappers preserve a single API for human and bot callers. The changes to existing battle files are narrow. In particular, the interruption hook uses the already-resolved damage owner rather than adding a second attribution algorithm, and the death hook is placed in the existing authoritative death path.

The numerical cooldown correction is appropriate: repeated subtraction of `1.0 / 30.0` can leave a tiny positive remainder, while use validation correctly rejects any positive cooldown. Clamping a remainder at or below `1e-8` removes that numerical artifact and is many orders of magnitude smaller than one game tick. The added regression uses the real `state.step(12.0)` route, verifies an exact zero, successful second-item use and rejection of an immediate repeated use. Existing final-partial healing calculation pays only the remaining duration before ending the effect.

The behavioral suite exercises authority state rather than mocked permissions. Its direct timer checks are complemented by actual fixed-step, projectile and lethal-damage checks, addressing the important integration boundaries. No production change or additional reproducer was needed during this review.

## Evidence and limits

Inspected the retained cooldown red log (245 checks, 3 failures) and final consumables green log (245 checks, 0 failures). The implementation report also records battle-rules, next-combat and battle-match regression results. Those are author-provided test evidence; this reviewer did not rerun previously passing suites, as directed. Root remains responsible for the final complete integration run and script import/package verification.

No Windows PC execution or human match was performed or inferred from automated checks. UI translation, modal/input behavior and bot purchasing/consumption policy require their separate task reviews.


## Task 2 independent review

# Task 2 independent spec and quality review

## Verdict

- **Specification: PASS** for the frozen implementation and existing automated/graphical evidence.
- **Code quality: PASS.** No actionable P0, P1, P2 or P3 defect found in the reviewed scope.
- Final integration evidence verified: root's `full-result.json` records twelve suites, **3,453 checks, zero failures**, a ninety-frame main-scene smoke and exit zero. Final `render.log` records **16 frames, PASS**, including selection at both resolutions and refreshed shop instructions.

Reviewed `task-2-brief.md`, `task-2-report.md`, `task-2-review.diff`, the actual four owned source files, the design contract, existing red/green logs and rendered frames. This was a read-only implementation review; only this review record was written. No suite was rerun and no source, tests or commits were changed.

## Specification and integration assessment

| Contract | Assessment and evidence |
|---|---|
| Real scene wiring and authority boundary | PASS. `battlefield.gd:64–68` connects all five HUD signals. Scene methods at `179–228` own the mutation calls. HUD previews use the authority at `battle_hud.gd:332–343`; purchase commands revalidate through `battle.command_buy_consumable` even after a stale preview. |
| Inventory and shop | PASS. `battle_hud.gd:228–287` supplies the prescribed inventory band, separate item selection buttons, P/D controls, two shop cards, fixed prices/effects, capacity and close action. `321–343` renders the controlled hero's credits, both stock counts, selection, shared cooldown and active recovery. Offbase/dead inspection remains available while authority errors disable purchases. |
| Input and accepted actions | PASS. `battlefield.gd:211–228` does not clear aim or change orders when selecting/using. `306–363` preserves G/B and routes P/D/Esc. Shop opening intentionally clears aim and camera drag while retaining already accepted authority orders. Tests explicitly establish nonempty real windup/cast and queued movement before D, avoiding a vacuous preservation assertion. |
| Pause and modal reciprocity | PASS. Shop stores/restores the prior paused boolean at `battlefield.gd:185–198`. Growth, help, pause and result gates prevent incompatible shop opening. `_accepts_commands`, world click, minimap and mouse-input paths block gameplay while shop is visible. |
| Click-through protection | PASS. `battle_hud.gd:655–679` makes the modal full-screen and blocking, and adds inventory, hint and toast to point blocking. Tests check world/minimap entrypoints and inventory/control geometry against the actual instantiated scene. |
| Feedback, privacy and replay | PASS. `battle_hud.gd:289–357` translates rejection reasons, shows buy/use/end feedback only for the controlled hero, and consumes event sequence numbers once. `515–537` closes shop and resets the cursor on selection/new match; `641–646` closes it for results. No enemy stock or damage-source identity is projected. |
| Help and selection hints | PASS in source. F1 retains G/B and explains P, slot selection, D and shared cooldown (`battle_hud.gd:496`). Shop instructions explicitly require closing it before selecting/using (`262`), and selection hint retains the `경기 중:` qualifier (`434`). |

## Test evidence and its actual reach

`task-2-red.log` records **11 checks, 11 failures** for absent scene methods/signals. `task-2-green.log` records **113 checks, 0 failures**. The test loads `scenes/battlefield.tscn`, emits its actual connected Button signals, and constructs physical-key events passed through the production `_input` handler. It uses the real battle authority; only fixture state and tick scheduling are controlled.

Coverage includes stale money/location previews, repeated purchase signals, capacity, repeated D and echo, cooldown-zero boundary, full resource/dead rejection, selection of empty kinds, preservation of skill/attack aim and accepted commands, completion/interruption feedback, cursor nonreplay/reset, enemy-state isolation, modal exclusivity, pause restoration, world/minimap blocking, results/selection/restart, and logical 1280×720 / 1920×1080 geometry.

These are scene integration tests of connected signals and input handlers. They do not claim OS-level mouse/keyboard injection or a human-played match. The distinction does not invalidate their coverage of the requested scene contracts.

## Graphical evidence

The final capture log identifies real Mesa/llvmpipe OpenGL rendering, records 1280×720 and 1920×1080 image sizes, and ends with **16 frames, PASS**. The helper refuses a headless display, uses the actual scene and authority commands/damage, and saves the rendered viewport image. Both `root.size` and `root.content_scale_size` are set, so the larger frames also exercise logical 1920-wide layout.

Independently inspected these initial frames: `01-shop-720p`, `02-inventory-1080p`, `03-recovery-720p`, `04-interruption-720p`, `05-help-720p`, `06-offbase-shop-1080p`, and `07-dead-shop-720p`. Inventory, hint, skills and minimap occupy separate bands; Korean labels/reasons, item counts, selected indication, recovery/cooldown and close controls fit.

After final capture completed, independently inspected both `00-selection` frames and both refreshed `01-shop` frames. The selection hint visibly retains `경기 중:` and the shop visibly says to close it before selecting and using D. All four fit their respective viewports without clipping or overlap. The earlier fourteen-frame evidence has been superseded by the sixteen-frame log; no graphical-evidence item remains pending for this review.

No actual Windows PC, Windows DPI validation or human match is claimed. Those unavailable activities are not requirements for this scoped source review to pass.


## Task 3 independent review

# Task 3 independent review

## Verdict

**Spec compliance: PASS for Task 3 implementation. Code quality: APPROVE.** No actionable P0–P3 correctness or regression findings were identified in the reviewed scope.

Reviewed `task-3-brief.md`, `task-3-report.md`, the complete `task-3-review.diff`, the current AI and behavioral test files, and the Task 1 authority/timer methods they call. The production scope is the 20 added lines in `battle_ai.gd`; the new behavioral suite is 246 lines. Core authority was reviewed separately and is not reapproved by this review.

## Requirement assessment

| Requirement | Assessment |
| --- | --- |
| Living, enabled, noncontrolled heroes only | The existing alive guard precedes the added dispatch. The dispatch additionally checks hero kind, `bots_enabled`, and controlled ID (`battle_ai.gd:7–10`). Tests cover all three exclusions both at home and offbase. |
| At home, target one I02 then one I01 and fill missing types only | The ordered loop visits I02 then I01, checks the current count, previews each purchase, and calls the shared authority command (`battle_ai.gd:23–27`). The authority rechecks live credits, position and combined capacity. Tests include literal credit deductions, 39/40/49/50/89/90 boundaries, missing-type refill and existing two-of-one inventories. |
| No use at home; no purchase offbase | The home branch returns before use logic, and purchase commands appear only inside that branch. Both home rectangles, enemy bases, exclusive far edges and a central point are covered. |
| Offbase patch at HP deficit >=200 and damage elapsed >=2 seconds; otherwise bottle at energy deficit >=40 | The comparisons are inclusive and patch has priority only when its preview succeeds (`battle_ai.gd:31–34`). An unavailable patch permits the bottle fallback. Tests exercise 199.99/200 HP, 39.99/40 energy, 1.999/2 seconds, empty stock and full resources. |
| Shared cooldown and actual recovery | Positive shared cooldown returns before selection; use flows through the same selected-item command (`battle_ai.gd:28–36`). Tests exercise real 200 HP / four-second and 40 energy / two-second recovery, twelve-second unlock and repeated decisions. |
| Preview before selection or failed mutation; preserve player error/selection | Both purchase and use previews precede commands. No selection is changed for denied use. Tests snapshot the controlled hero and unrelated error/events, and cover ended-match, cooldown, empty, full-resource and unaffordable denials. The inspected authority preview methods are read-only. |
| Preserve attack-move, phase, queue and other battle orders | Dispatch occurs before the existing attack-move skip and existing hero phase/CC guards. Consumable commands modify item fields, without writing order/path/cast/queue fields. The behavioral tests cover attack-move, basic/windup/dash/recovery and stun, with field-level preservation checks. |
| No hidden-enemy input | The helper reads the actor's own status, public match time and own-base/authority predicates only. It does not inspect other units or visibility. A behavioral comparison changes hidden enemy position/HP and verifies identical bot state. |
| Existing movement/retreat strategy and tick sequence | No existing tactics or simulation-order lines are changed. The scope is purchase/use policy only; this does not complete broader R10 tactics. |

## Code quality assessment

The helper is narrow and consistent with the existing deterministic command model. Shared authority handles affordability, capacity and use validation; the AI adds only the agreed stock and resource policy. The preview-then-command sequence is synchronous, and authority commands revalidate before spending, avoiding reliance on stale affordability or inventory state.

The tests call the real `state._ai.think(state)` entry point and shared commands rather than mocking the decision. Fixtures intentionally put unrelated hero logic into windup or attack-move so assertions isolate the new policy. Direct timer recovery checks are appropriate for this scope; the root-owned natural match supplies the broader integration evidence. No additional reproducer or source change was needed.

## Evidence and limits

The retained green log records **186 checks, zero failures**. The author report records preimplementation behavioral red evidence (**186 checks, 52 failures**) and a clean diff check. Those are retained implementation evidence; this reviewer did not rerun passed tests, as directed.

Root completed the integrated natural match during review. The inspected `long-match.log` records actual East core destruction at **431.8 simulated seconds**, West winner (`winner=0`), six towers destroyed, 201467.8 damage, five hero deaths, 54 units and **1922 checks, zero failures**. Root reports exit zero and unchanged battle sources throughout that run. No replay was performed. This is one automated bot-only condition; the changed result relative to the prior baseline is not itself a defect against the specified policy or human balance evidence.

Root still owns the final complete integration gate. Automated bot evidence does not establish Windows PC execution, human balance, or completion of broader R10 tactics.


## Whole-change final independent review

**전체 명세 준수 PASS / 코드 품질 APPROVE.** 최종 검토에서 조치가 필요한 P0/P1/P2/P3 또는 보류한 지적은 없었으며 추가 구현 변경이나 이미 통과한 검사 재실행을 요청하지 않았다. R09와 명시적으로 한정한 R10 구매/사용 판단을 검토한 결론이다. 새 Windows export·게시·실제 Windows PC·사람 플레이·전체 봇 전술·게임 밸런스를 승인한 결과는 아니다.

출처는 최종 검토자가 작성한 `build/base-consumables/final-review.md`이며, 아래에 원문을 보존한다. 검토 대상은 같은 시점의 `build/base-consumables/final-review.diff`, 실제 구현·검사·문서, 확정 설계·계획과 기존 작업별 검토 기록이다. 기준은 `0b1234f8918e0d5bbea2cefbab5f83c4434a9da7`, 브랜치는 `feat/base-consumables`다.

검토자는12묶음3,453 assertion·실패0·main90프레임,16개 실제 렌더 프레임의 로그와 root/UI 검토자의 확인 기록,431.8초 자연 경기 및 소스 불변 기록을 대조했다. 이 전체 검토자가 그래픽을 다시 실행하거나 독립적으로 화면을 한 번 더 관찰한 것으로 표시하지 않는다. 실행 증거는 [최신 검증](../13-consumables-verification.md)에 분리했다. 소스 게시와 깨끗한 소스의 Windows 패키징은 이 검토 다음의 통합 게이트로 남는다.

### 원문

# Whole-change independent review — base consumables

## Verdict

**Specification: PASS. Code quality: APPROVE. No actionable P0, P1, P2 or P3 findings.** No parked findings or requested implementation changes remain from this review. The reviewed source is suitable to proceed through the already planned source publication and clean-source Windows packaging gates.

This verdict covers the R09 implementation and the explicitly limited R10 consumable policy. It does not certify an export that has not yet been made, execution on a Windows PC, human play, broader bot tactics, or game balance.

## Scope and method

Reviewed the whole-change package `build/base-consumables/final-review.diff`, its current implementation/test/document files, `docs/plans/2026-10-27-base-consumables-design.md`, the implementation plan and progress ledger, and the retained task-review and integrated evidence records. Base is `0b1234f8918e0d5bbea2cefbab5f83c4434a9da7` on `feat/base-consumables`.

The review followed the cross-task paths from HUD signals and physical-key handlers through public commands to state mutation, fixed-step timers, damage ownership and death; it also checked the same authority from the real AI entrypoint. Previously passing suites were not rerun. No concrete uncovered defect required a reproducer. Only this review report was written; no implementation, tests, commits or publication were changed.

## Cross-task assessment

| Boundary | Assessment |
|---|---|
| Catalog, capacity and mutation | `battle_consumables.gd:4–9,23–100` implements the fixed 40-credit/40-energy/2-second bottle and 50-credit/200-HP/4-second patch, combined capacity two and shared twelve-second cooldown. Both mutation commands revalidate current authority state; stale UI previews cannot authorize a purchase. Selection remains independent of stock and does not automatically substitute another kind. |
| Existing actions and aim | `battlefield.gd:211–228` and `battle_consumables.gd:77–100` leave action, cast, queue, movement and aim state untouched for selection/use. The scene tests establish a real nonempty cast and queued move before D, in addition to ordinary movement and armed skill/attack aim. Shop opening separately clears only presentation aim/drag as specified. |
| Modal lifecycle and click protection | `battlefield.gd:179–209,306–377` makes the shop inspectable while dead or away from base, remembers/restores the previous paused state, gates incompatible shop/modal paths and prevents gameplay commands while open. `battle_hud.gd:515–537,641–662` closes/reset-cleans shop presentation across selection, restart and result, and blocks the inventory/modal surfaces. World/minimap entrypoints honor these gates. |
| Recovery, damage attribution and death | `battle_state.gd:168–212` decrements the shared cooldown before the dead-unit return and pays healing after existing natural/base regeneration. `battle_rules.gd:36–55,168` calls patch interruption only after valid applied damage and actual owner resolution, and routes lethal hits through one death termination. Hero-owned devices and shield absorption qualify; minion/tower damage does not inherit a prior contributor's identity. `battle_consumables.gd:103–143` preserves stock/selection on effect termination and filters events to the controlled hero. |
| Boundaries and simulation order | The final partial recovery interval is paid before effect termination. The tiny cooldown clamp unlocks after exactly 360 fixed ticks. Existing timer/actor/projectile/device order remains unchanged, so healing paid earlier in the tick is not retroactively revoked. Match-end step guards freeze effects and cooldown; reset rebuilds independent hero inventories. |
| Bot policy and player isolation | `battle_ai.gd:6–36` dispatches only living, enabled, noncontrolled heroes. At home it fills missing types in patch-first order via preview and command; outside home it uses the agreed inclusive HP/elapsed-damage and energy thresholds. The helper precedes the existing attack-move skip but does not replace movement/retreat policy. It reads its own state, does not inspect hidden enemies, and previews before selection/mutation so failures do not overwrite human state or errors. |
| Feedback and source boundaries | `battle_hud.gd:289–357` maps rejection/event text to Korean, renders the controlled inventory only, and consumes sequence numbers once. The helper's controlled-only event boundary and reset cursor agree. HUD cards use the shared catalog and authority previews. The new module's public state wrappers keep UI and bots on one rule implementation. |

## Verification and documentation assessment

The retained integrated output and `full-result.json` agree on **12 suites, 3,453 assertions, zero failures**, exit zero, import success and a **90-frame** main-scene smoke. The three new suites contain 245 authority, 113 scene-input and 186 AI assertions. Their source tests cover the important state transitions and denied paths, with actual authority calls and loaded-scene input/signal wiring rather than mocked rule outcomes.

The final render log records **16 actual frames at 1280×720 and 1920×1080**, PASS. The capture helper explicitly changes logical UI dimensions as well as window dimensions; the verification document correctly distinguishes this from Windows DPI or OS input testing. Root and the independent UI reviewer inspected the actual frames. This whole-change reviewer inspected their evidence and capture implementation and did not claim another graphical run or independent visual inspection.

The natural-match evidence records **431.8 simulated seconds, West victory through actual East core destruction, 1,922 checks and zero failures**. The recorded source manifest states unchanged battle sources during that run. Documentation preserves the prior 1,638.2-second East result and describes the new result as one bot-only condition, without asserting balance or a human match-duration target.

The nine packaging boundary tests passed. The packaging-tool change is limited to the generated Korean controls/checklist text, while the new actual Windows export and ZIP/PCK verification remain explicitly pending. `13-consumables-verification.md` separates those future artifact facts from existing automated/render evidence and from unperformed Windows-PC/human testing. The plan's remaining publication/export/evidence checkboxes are consistent with this prepublication stage. Filling those records after the corresponding operations is an integration gate, not a source-review defect.

Documentation preserves the narrow R10 scope, fixed item numbers, G/B behavior, P/D usage, purchase-vs-inspection distinction, death/inventory/cooldown contract and actual-source-vs-old-package distinction. No unrelated combat/vision/growth-number or tactical expansion was found.

## Actionable findings

**None.** No further source change or repeated test execution is requested by this review.
