# Independent final source review — next local playtest

## Verdict and severity-ranked findings

**No open P0, P1, P2, or P3 actionable defect found in the source reviewed after the integration owner's source-ready signal.** The earlier P1 radial renderer cost issue and P3 minimap hover issue have corrective source and focused evidence. A separate P3 selection-screen F1 wording issue identified during this final review was corrected before this report.

This is an independent source-review approval to proceed through the integration owner's final full-suite, graphical capture, clean-source commit, Windows export, and publication gates. It is not a claim that those still-running/future gates, actual Windows execution, or human gameplay have passed.

Base: `85deaf26797d2bc64757d54bd2025d39d09c8a00`. Reviewed the working source after root declared the renderer and vision follow-ups ready on 2026-10-27. No production source or documentation was edited by this reviewer; only this report and the targeted ignored-build probe were written. No commits, pushes, subagents, or repeated full suites were performed.

## Scope and direct source findings

Read the approved implementation plan, progress ledger, Task 1–4 implementation reports and Task 1–3 review reports, then independently read production diffs and the new tests rather than treating the reports as proof of source correctness.

### Combat, command lifecycle, and selection

- `game/project-e/scripts/battle/battle_state.gd`: the original destination is separate from automatic target identity. Search is limited to legal visible heroes/minions/structures, target retention avoids nearest-enemy jitter, acquisition origins and blocked IDs prevent same-target leash refresh, and arrival allows in-range attacks without renewed chase. Fog validation runs before basic windup release. Death, stop, reset, accepted replacement, and queued transitions clear the appropriate prior state; rejected requests preserve current intent. The new tests exercise these contracts against real state, including ranged release and command queues.
- `game/project-e/scripts/battle/battle_rules.gd` and `battle_ai.gd`: cell rewards use per-cell XP while preserving shared credits and respawn; tower retaliation and bot margins derive from the actual attack-range field. The 20/30/40 spatial assignment is rotationally symmetric and matches the plan. Shared source visibility preserves the prior radius/LOS authority.
- `game/project-e/scripts/presentation/battlefield.gd`: direct target priority, screen-distance/ID tie-breaks, alive/team/visibility/locked filtering, A arming/confirmation, command rejection, aim replacement, death/result/restart, UI blocking, and help pause-state restoration are consistent with the stated contracts. Input tests inspect real scene and authority state rather than only mocked dispatch.

### Warning geometry and hidden information

- `game/project-e/scripts/battle/battle_map.gd`: radial warning rays use the same rectangular wall segments as authoritative LOS, with added wall-corner angles and conservative wall margin.
- `game/project-e/scripts/presentation/effects_view.gd`: the final implementation caches wall-clipped geometry and clips native convex regions against live allied sight polygons. Exact source positions and kinds, source identities/membership, shape parameters, and map/blocker changes feed invalidation. The cache is bounded; removed observers are pruned. Subtraction keeps shared observed regions disjoint, including enclosed complements, instead of filling hidden holes or doubling alpha. Hidden-origin enemy shapes can retain an observed near side. Enemy timing rings and existing line/persistent cues retain point visibility gates. The known allied-skill trajectory and already-released basic-projectile contracts were not expanded.
- Read `tests/test_effect_geometry.gd` directly, including partial hidden origins, small source movement, source death, overlap, wall corners, cache/query limits, and the large diagnostic visibility-island case. The polygon intersections are between convex subject/sight pieces; their emitted triangle fans are therefore consistent with the representation.

### Terrain, minimap, provider badges, and cells

- `game/project-e/scripts/presentation/team_vision_view.gd`, `arena_view.gd`, `tactical_map.gd`, and `unit_overlay.gd`: only living allied heroes/minions/towers/cores supply vision. Exact source-filter authority evaluates raster candidates. Terrain and minimap consume the same image with correct simulation-Y/screen-Y orientation. Public enemy structure location/destruction does not create an observer or expose health. Hidden/dead cells have neither models nor XP labels through the ordinary presentation gates.
- The minimap now reevaluates source hover under a stationary pointer every presentation update, including source motion/death. Fixed-pixel eye badges use the same anchor/width helpers as actual status bars and sit beside their own plate. Hover hit-testing uses that displayed badge position. Korean tooltips use the bundled font and distinguish pale sight from amber tower attack range.
- Inspected the actual `build/screenshots-next/source-badge-zoom-26.png` image: provider eyes are visible beside the hero/tower/minion plates, the visible cell has no eye, and Korean range text is readable. This is a supplied Linux graphical frame, not a reviewer-run Windows or human test.

### Packaging and honest handoff

- `tools/package_windows.py`: verifies official-version string and matching TPZ version, extracts only explicitly named template entries, copies an isolated source snapshot, rejects source symlinks, edits only the copied preset, checks process errors as well as exit status, checks fresh PE/x86_64 and PCK headers, includes required notices and Korean instructions, verifies ZIP CRC/content hashes, and publishes only the complete staged directory. Failed export cannot reuse old EXE/PCK or consume the previous known bundle. Unrelated output files block replacement.
- Read `tools/tests/test_package_windows.py`: its nine CLI-level boundary tests distinguish a process double from actual export and cover success content, engine/template mismatch, zero-exit errors, nonzero export, missing PCK with previous-bundle preservation, import error, unrelated output preservation, and missing license.
- `tools/check_godot.py` registers all nine suites. README, design updates, Windows guide, and blank local-playtest record keep implementation/export, actual Windows PC execution, and human gameplay distinct. The pending final export is not represented as an actual Windows run. R05 remains unperformed with a usable observation form.

## Corrections verified in this review

1. **Earlier P1 radial redraw cost:** the old per-triangle repeated LOS/whole-world sampling is removed for radial fill/strokes. The recorded focused comparison in `task-3-render-cost-fix.md` / `effect-cost-profile.log` moves mean allied-circle/enemy-circle/enemy-cone/unseen-cone redraw from approximately 20/432/392/219ms to 0.707/2.081/0.703/0.034ms. The supplied focused geometry result is 35 checks / 0 failures, plus existing scene 96 / 0. Dynamic rebuilding is separately measured; no static-cache result is presented as an overall frame-rate guarantee.
2. **Earlier P3 stationary minimap hover:** source motion/death now changes selection and tooltip even without mouse motion; the focused tests exercise the current pointer and live state.
3. **Final-review P3 selection copy:** selection originally advertised F1 help while `handle_hotkey` and `open_help` reject a non-active match. Root changed `battle_hud.gd` selection copy to **`경기 중 F1 도움말`**, accurately qualifying when that action is available. No unsupported pre-match help is promised.
4. **Render-found obscured provider halos:** final badges are separate from their own health/name plates; the source and new projected-layout tests cover hero/minion/tower/core at three zoom levels. Supplied focused vision result is 499 / 0.

## Independent targeted verification

Ran a new focused geometric probe after source-ready, using pinned Godot `4.7.2.stable.official.ed1daf0bf` headless and fixed seed `462718`:

- **62 valid randomized circle/cone fixtures** at varied positions around the real six wall rectangles.
- One or two allied observers at varied angles/distances, with exact unthrottled visibility authority.
- **171,990 triangle samples** (vertices, edges, and interior barycentric points) across emitted nondegenerate warning triangles.
- Every sampled point satisfied both authoritative team visibility and effect-origin wall LOS.
- Exit 0; no ERROR/SCRIPT ERROR in the probe log.

Probe: `build/next-local-playtest/final_review_geometry_probe.gd`.
Log: `build/next-local-playtest/final-review-geometry.log`.

Also ran `git diff --check`: clean. No unchanged full suite was rerun by this reviewer.

## Limits and remaining release evidence

- Root's final nine-suite run was still underway when this report was written. The initial integrated run passed 2,859 assertions and naturally ended the unchanged-combat six-bot match at 1,638.2s; those are prior supplied evidence, not a substitute for the post-renderer standard suite. Root must attach the completed final log and resulting count to its final verification record.
- Root owns the final 11-frame capture and review, final source commit, matching Windows export, exported-resource smoke if available, manifest/ZIP inspection, and GitHub publication. This report does not pre-approve unreviewed future source changes.
- The 1m terrain raster and movement-refresh cadence can differ from exact visibility at boundaries. The recorded populated-map refresh cost of roughly 28–36ms remains a disclosed frame-time risk. Exact targeting/model/health and enemy-effect gates are independent of that raster. Multiple changing enemy warnings also retain measurable CPU cost; the focused single-warning improvement is not a 60fps or Windows performance guarantee.
- Hover contours use angular sampling. Polygon inset/chord geometry conservatively underfills a small boundary strip. The targeted random sample probe gives additional boundary evidence, not exhaustive mathematical coverage of all possible positions.
- Wall-detour attack-move pursuit, dense collision behavior, first-time user comprehension, actual Windows display scaling/focus/Alt-Tab, editor-free execution, and full human matches remain actual-play/platform checks. No concrete new regression in those areas was established here, and no Windows/human success is claimed.


## Integration-owner evidence after review

Final full standard runner exited0:40+19+115+1923+96+152+499+32+35=2911assertions,0failures;main90framespassed. See2026-10-27-headless.log. FinalrealGLcapture exited0 with11frames andGPUmasktransitionsPASS;rootinspected thefinalimages. See2026-10-27-render.log and../assets/next-*.png. Packagingboundarytests9/0. These areintegration-owner observations addedaftertheindependentreview, notclaimsthatreviewerreran suites. FinalgameWindowsexport follows sourcecommit;actualWindowsPC/humanplaynotrun.
