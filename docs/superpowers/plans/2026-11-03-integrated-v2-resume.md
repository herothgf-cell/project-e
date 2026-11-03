# Integrated V2 Recovery Implementation Plan

**Goal:** Finish the interrupted integrated art/skill/terrain review build and deliver a verified executable.
**Architecture:** Recover the saved Git tree instead of rewriting it. Keep authority unchanged; isolate review state and rendering. Fix reproduced failures only.
**Tech Stack:** Godot 4.7.2 Standard, GDScript, Linux renderer, Windows x86_64 export.
**Spec:** doc/design/19-integrated-v2.md

## Constraints and review focus
Preserve numeric balance, team visibility and authoritative ground height. No production-art or original-video measurement claims. User chose all-in-one integration followed by iterative feedback. Review state isolation, rendered/clicked height, Nema pin prerequisites, hidden effects/death, animation/reset lifecycles.

## Tasks and ledger
- [x] Locate main 0834cc6, feature df4c9e4, saved uncommitted tree 9eeeaa7; recover, do not rewrite.
- [x] Run recovered tests: 21 suites, 4,517 checks, zero failures.
- [x] Inspect actual renderer. Find review objectives missing because spawn marked complete before entities existed.
- [x] Add test_review_objectives: RED 3/5 failures; fix with authority initial-spawn boundary in isolated state; GREEN 5/5.
- [x] Run full suite: 22 suites, 4,522 checks, zero failures; import/main startup pass.
- [x] Capture/inspect all 12 real casts, three heroes, hit/death/respawn, hill and full map: 40 stills + 282 animation frames.
- [ ] Verify final Windows CI package and Windows headless startup; separate human graphical gate.
- [ ] Integrate verified branch into main without force; attach final exact-source artifacts.

Ruling: existing feature branch and fresh isolated snapshot are reused; no new worktree or redesign required. Container cannot resolve GitHub; connected GitHub transports exact source/toolkit. Local index tree 0b8acf526583aa7d61f06ad04378e5c7e4e0eb85 exactly matches remote verified game tree. Code review is self-review, not an independent subagent review.
