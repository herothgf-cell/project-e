# R29 XP Feedback Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans. The requested R29 implementation and regression checks below are complete. Integration is tracked by [PR #2](https://github.com/herothgf-cell/project-e/pull/2) and its exact head/main refs.

**Goal:** Make observed cell creation, actual personal XP awards, and level/growth progression readable without changing rewards or leaking fog-of-war information.

**Architecture:** Keep battle_state.gd as authority. Emit immutable cell-spawn and XP-award snapshots into a bounded, damage-independent feedback queue. A dedicated Control under the existing unit overlay consumes only the local player's authorized feedback. Its progression meter is a child of the existing HUD XP label so the opaque HUD cannot hide it.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, existing GitHub Actions regression runner.

**Spec:** doc/design/11-remaining-development.md, section 4 / R29; design decisions below refine that approved scope. Evidence: doc/design/17-xp-feedback-verification.md.

## Scope and design decisions

- Preserve 20/30/40 XP, HP 180, first spawn 30 s, respawn 45 s, sharing among living allied heroes within 14 m, credit reward 10.
- Preserve tower 8.5 m, R28/R30 geometry, hero balance, consumables and bot decisions.
- Compare-on-render was rejected: it can mistake entering fog for a spawn and cannot identify XP crossing a level threshold. Use authority events instead.
- Cell events freeze the teams that could see the location at creation. Presentation also checks current visibility and alive status. Hidden creation is never replayed on later reveal.
- XP events contain recipient position, actual applied XP, share count/source category, and level/point deltas. They contain no defeated source position or ID.
- Max-level recipients retain existing credit eligibility but receive no fictitious XP. At level 11 with 340 XP, a 40 XP allocation produces 10 applied XP and reaches level 12.
- Nonintegral XP remains full precision in rules/events; the display explicitly marks two-decimal approximations.
- Draw a short spawn pulse, local recipient floating reward, and a compact personal notification with level/growth and G/R guidance. Add a slim progression meter next to the current XP label. All feedback controls ignore mouse input.
- Pause freezes feedback lifetime. A match serial prevents restart replay. Bound the feedback buffer to 128 events and presentation to 16 cues.
- No new sounds/assets, online transport, bot strategy or balance changes in R29. Windows export/human play are not silently marked complete.

## Interfaces and files

1. `battle_state.gd`: `match_serial`, `feedback_events`, `_log_cell_spawn(cell, is_respawn)`; initial/respawn hooks; log_event copies only cell_spawn/xp_gain to bounded feedback storage.
2. `battle_rules.gd`: `award_xp(state, unit_id, amount, context={}) -> float` returns accepted progression; `_share(..., source_kind="")` supplies share metadata. Existing callers may ignore the return value.
3. `presentation/xp_feedback_view.gd`: state/camera/font/label bindings, event filtering, lifecycle, public progression_ratio()/progress_rect()/reward_text() and actual drawing.
4. `unit_overlay.gd`: creates the view and propagates update/reset. Existing HP/damage handling stays unchanged.
5. `tests/test_xp_feedback.gd` and `tests/test_xp_meter.gd`: real state and battlefield tests, registered in tools/check_godot.py.

## Review focus

- Hidden spawn then late reveal; lose/regain vision during a cue. No spawn replay.
- Fractional sharing, dead/distant allies and cap overflow. Show accepted grant, not object value or XP gauge delta.
- Repeated render, pause, restart with reused IDs/sequences. No stale or duplicated feedback.
- Damage bursts must not evict recent XP; buffers stay bounded.
- High-ground projection and 720p/1080p control bounds; actual HUD draw order and input passthrough.

## Task 1 — Authority events: complete

- [x] Added real kills, shares, cap/invalid amounts, spawn/respawn visibility tests.
- [x] Observed missing-feature RED in CI #29, not a parse-error substitute.
- [x] Added authority hooks and recipient-only reward metadata.
- [x] Passed real Godot tests without changing reward values or map rules.

## Task 2 — Feedback presentation: complete

- [x] Added real scene tests for authorized cues, deduplication, pause/reset and meter.
- [x] Confirmed missing view RED in #29 and actual HUD meter RED in #34.
- [x] Implemented the Control, HUD-owned ProgressBar and overlay integration.
- [x] Passed the entire 16-suite runner in #35.

## Task 3 — Review and documentation: complete

- [x] Re-read complete feature diff and boundary contracts. No subagent was available; this is self-review, not independent review.
- [x] Fixed the opaque-HUD layering finding with a failing regression before the fix.
- [x] Fixed transcription errors caught by import/diff checks; final movement/core-lock blocks match the base.
- [x] Recorded CI results and limits in doc/design/17-xp-feedback-verification.md.
- [x] Updated current README/backlog while preserving historical verification files.

Integration rule: fast-forward only a green feature head into main using `expected_sha`; then verify the main push CI. PR #2 records the resulting merge state rather than claiming it in advance here.

## Execution ledger

- Base: `10dc2225c60cd900769c717016543b4b77a94033`.
- Ruling: no usable local repo/engine and external DNS unavailable; used isolated remote feature branch plus actual pinned-engine CI.
- Pre-flight: recipient-only payload and creation-time visibility are shared contracts between authority and presentation.
- RED: [#29](https://github.com/herothgf-cell/project-e/actions/runs/40819779205), missing events/view. Existing 14 suites passed.
- Ruling: a world-overlay rectangle is hidden by the opaque bottom HUD; meter became a real XP-label child, preserving modal order. [#34](https://github.com/herothgf-cell/project-e/actions/runs/40821527117) demonstrates the missing-meter failure.
- GREEN: code `cc2ae035fa658795b9544f828cdb12a13f29e1e7`, [#35](https://github.com/herothgf-cell/project-e/actions/runs/40821728887): 16 suites, 3,633 checks, zero failures; import and main-scene startup passed.
- Command: `python tools/check_godot.py --godot <Godot 4.7.2 executable>` on the CI runner.
- Not performed: real rendered-frame inspection, Windows execution/export, human play or online tests.
