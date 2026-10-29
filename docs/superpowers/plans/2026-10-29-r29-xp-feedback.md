# R29 XP Feedback Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans. Execute the already requested R29 scope without reopening product decisions. Track the checks below.

**Goal:** Make observed cell creation, actual personal XP awards, and level/growth progression readable without changing rewards or leaking fog-of-war information.

**Architecture:** Keep battle_state.gd as authority. Emit immutable cell-spawn and XP-award snapshots into a bounded, damage-independent feedback queue. A dedicated Control under the existing unit overlay consumes only the local player's authorized feedback; the existing HUD remains authoritative for XP and growth.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, existing GitHub Actions regression runner.

**Spec:** doc/design/11-remaining-development.md, section 4 / R29; design decisions below refine that approved scope.

## Scope and design decisions

- Preserve 20/30/40 XP, HP 180, first spawn 30 s, respawn 45 s, sharing among living allied heroes within 14 m, credit reward 10.
- Preserve tower 8.5 m, R28/R30 geometry, hero balance, consumables and bot decisions.
- Compare-on-render was rejected: it can mistake entering fog for a spawn and cannot identify XP crossing a level threshold. Use authority events instead.
- Cell events freeze the teams that could see the location at creation. Presentation also checks current visibility and alive status. Hidden creation is never replayed on later reveal.
- XP events contain recipient position, actual applied XP, share count/source category, and level/point deltas. They contain no defeated source position or ID.
- Max-level recipients retain existing credit eligibility but receive no fictitious XP. At level 11 with 340 XP, a 40 XP allocation produces 10 applied XP and reaches level 12.
- Nonintegral XP remains full precision in rules/events; the display explicitly marks two-decimal approximations.
- Draw a short spawn pulse, local recipient floating reward, and a compact personal notification with level/growth and G/R guidance. Add a slim progression meter next to the current XP label. All feedback controls ignore mouse input.
- Feedback uses simulation time (pause freezes it), a match serial (restart cannot replay old events), a 128-event feedback buffer and a 16-cue presentation cap.
- No new sounds/assets, online transport, bot strategy or balance changes in R29. Windows export/human play are not silently marked complete.

## Interfaces and files

1. `battle_state.gd`: `match_serial`, `feedback_events`, `_log_cell_spawn(cell, is_respawn)`; initial/respawn hooks; log_event copies only cell_spawn/xp_gain to bounded feedback storage.
2. `battle_rules.gd`: `award_xp(state, unit_id, amount, context={}) -> float` returns accepted progression; `_share(..., source_kind="")` supplies share metadata. Existing callers may ignore the return value.
3. New `presentation/xp_feedback_view.gd`: battle/camera/ui_font/xp_label/enabled bindings; reset_feedback(), update_feedback(delta), progression_ratio(), progress_rect(), reward_text(cue), cues. Rendering is driven by that same cue list.
4. `unit_overlay.gd`: creates the view, propagates bindings and calls update/reset; existing HP/damage handling remains unchanged.
5. `tests/test_xp_feedback.gd`: real state and real battlefield fixtures; register in tools/check_godot.py.

## Review focus

- Hidden spawn then late reveal; lose/regain vision during a cue. Must not create/replay a spawn.
- 40 XP shared by 2 or 3 heroes; dead/distant allies and level-cap overflow. Display must follow actual grant, not object value or XP gauge delta.
- Repeated render, pause, restart with reused IDs and sequence numbers. Never duplicate or retain stale feedback.
- Damage event bursts must not evict recent XP events; queues must remain bounded.
- High-ground projection, 720p/1080p HUD layout and mouse-through behavior. No click interception or hidden-source coordinate leak.

## Task 1 — Authority events

- [ ] Add tests for actual cell kills, shares, cap/invalid amounts, initial spawn and respawn visibility snapshots.
- [ ] Run existing suite plus new test in PR CI; record expected RED with missing events (not syntax errors).
- [ ] Add the authority hooks and reward metadata; preserve gameplay results.
- [ ] Run tests to GREEN.

## Task 2 — Feedback presentation

- [ ] Add real scene tests for player-only cues, no fog replay, duplicate prevention, reset/pause and progression meter.
- [ ] Confirm RED for missing XPFeedback view.
- [ ] Implement the Control and unit-overlay integration.
- [ ] Run entire Godot suite, not only the new file.

## Task 3 — Review, documentation and integration

- [ ] Separate self-review of diff and boundaries (no subagent tool available).
- [ ] Resolve important findings with regression tests.
- [ ] Record actual CI evidence and limitations in doc/design/17-xp-feedback-verification.md.
- [ ] Update current README/backlog without erasing historical verification.
- [ ] Integrate only a green feature head into main with an expected-SHA check; verify main.

## Execution ledger

- Base: 10dc2225c60cd900769c717016543b4b77a94033 (R30).
- Ruling: container has no usable repo/engine and external DNS fails; use an isolated GitHub feature branch and actual pinned-engine CI instead of claiming local runtime verification.
- Pre-flight: authority events feed the new overlay; recipient-only payload and event-time visibility are common contracts for Tasks 1 and 2. No other subsystem consumes the new feedback queue.
