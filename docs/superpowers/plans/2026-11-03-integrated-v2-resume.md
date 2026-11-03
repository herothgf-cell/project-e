# Integrated V2 Recovery Implementation Plan — Completed

**Goal:** Finish the interrupted integrated art/skill/terrain review build and deliver a verified executable.
**Architecture:** Recover saved tree; preserve authority; isolate review state/rendering; fix reproduced integration failures.
**Tech Stack:** Godot4.7.2 Standard, GDScript, Linux renderer, Windows x86_64 export.
**Spec:** doc/design/19-integrated-v2.md
**Delivery:** doc/design/20-v2-delivery.md

## Constraints and review focus
Preserve numeric balance, team visibility and authoritative height. No production-art or original-video measurement claims. User chose all-in-one integration followed by iterative feedback. Check state isolation, height, Nema prerequisites, concealment and animation/reset lifecycle.

## Completed tasks
- [x] Recover main0834cc6/featuredf4c9e4/saved tree9eeeaa7 without rewriting.
- [x] Recovered baseline21suites/4,517checks/0failures.
- [x] Pixel review finds XP objectives missing; regression RED3/5.
- [x] Fix isolated authority initial spawn/full-map visibility; GREEN5/5.
- [x] Full22suites/4,522checks/0failures; import/main startup pass.
- [x] Capture40stills+282frames covering3heroes/12casts/hit/death/respawn/hill/map.
- [x] Windows CI41590279866 export/ZIP and Windows headless startup pass.
- [x] Downloaded artifact CRC/SHA/manifest pass;57GDScript/scenes match tested source.
- [x] Exported PCK outside source:329integration+5objective checks pass.
- [x] PR#4 merged into main73dc3f0 with expected-SHA lease, no force.

Ruling: exact existing feature work is resumed in a clean local snapshot. Connected GitHub transports sources because container GitHub DNS is unavailable. Self-review only; no independent reviewer claimed. Manual Windows graphics/input/performance and final art/audio remain separate gates. Final delivery commit changes documentation only.
