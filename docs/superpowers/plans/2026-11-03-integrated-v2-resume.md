# Integrated V2 Recovery Implementation Plan

**Goal:** Finish the interrupted integrated art/skill/terrain review build and deliver a verified executable.
**Architecture:** Recover the saved Git tree instead of rewriting it. Keep authority unchanged; separate review state and rendering. Fix only reproduced integration failures.
**Tech Stack:** Godot 4.7.2 Standard, GDScript, Linux renderer, Windows x86_64 export.
**Spec:** doc/design/19-integrated-v2.md

## Constraints
Preserve numeric balance, team visibility and authoritative ground height. No production-art or original-video measurement claims. The user already chose all-in-one integration followed by iterative feedback.

## Review focus
State isolation; renderer depth versus click height; all twelve real skills including Nema prerequisites; hidden effects/death concealment; animation/reset lifecycles.

## Tasks
- [x] Locate main, feature branch and uncommitted saved tree; preserve existing work.
- [ ] Run recovered tests and identify exact failures before fixes.
- [ ] Add regression tests for any additional integration defect, verify RED, fix, verify GREEN.
- [ ] Run complete suite and actual renderer captures; inspect character/map/skill pixels.
- [ ] Export current Windows package, verify exact source, CRC and file hashes.
- [ ] Record evidence and limitations; integrate only verified code into main without force.

## Recovery ledger
2026-11-03: main 0834cc6, feature df4c9e4. Saved tree 9eeeaa7 contains the interrupted V2 implementation and tests but was not attached to a commit. Container Git network access failed; use connected GitHub for source recovery and pinned offline kit for local execution.
