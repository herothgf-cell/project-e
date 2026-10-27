# Independent Windows package review

## Verdict

**PASS / APPROVE. No actionable P0–P3 findings.** The package in `build/windows-consumables/` is internally consistent and identifies the published consumables source correctly. No parked findings remain.

This was an independent read-only artifact inspection. The reviewer did not launch Godot, the Windows executable or PCK; rerun import/export; modify source/package files; stage; or commit. Only `build/base-consumables/package-review.md` and `package-review.json` were written. Root's separately performed exported-PCK behavioral/render checks are outside this review's execution evidence.

## Source identity

- Manifest revision: `e56286a064063bda84ccd9eb309ab8fb80a575a1`; manifest Git status is the empty string.
- Independently resolved commit tree: `b49c8c1f396047753ea3d0627d573f6f12b8ea46`, matching the supplied published-source tree.
- All **73** `source.files` entries were read from that commit with `git show` and compared byte-for-byte against current project files. Every recorded length and SHA-256 matches both versions.
- The manifest source path set exactly equals the tracked `game/project-e` file set in the commit; no tracked project source is missing or extra.
- Independently recomputed portable source digest: `c72929cec3509dbc7dc900c6d1f276fe9cffdfd05bde1bcb5469947fc20ae80e`, matching the manifest. This digest is distinct from the Git tree identifier.
- `git status --porcelain` was empty during inspection.

## ZIP and artifact integrity

ZIP: `ProjectE-windows-x86_64.zip`, **39,428,780 bytes**.

SHA-256: `a2d88d42da7623d4ddb71420af2fce2dd7b30a67cac87bca7616fd153a43ae4d`.

The digest agrees with the sibling `.sha256` file and the successful packaging log. ZIP CRC verification passed. There are exactly **11 unique file entries**, all under `ProjectE-windows-x86_64/`: EXE, PCK, Korean README, third-party notices, import/export logs, four license/provenance files, and manifest. The set is exactly the ten manifest artifact entries plus the manifest itself.

Every declared artifact's size and SHA-256 matches its external file and its ZIP bytes. The internal and external `manifest.json` are byte-identical. No unrelated delivery item or duplicate archive path was found. Per-file results are preserved in `package-review.json`.

## Formats, export and contents

| Check | Result |
|---|---|
| Windows executable | DOS `MZ`, `PE\0\0`, machine `0x8664` and PE32+ optional header verified. EXE is 109,268,480 bytes and its SHA-256 equals the recorded release template. |
| Godot pack | Nonempty 1,343,384-byte `GDPC` pack; format version 4, engine header 4.7.2. PCK SHA-256 `fe6dd096f7a96487b966538975c2c106f00c988dd21dea0775e138589681e3f7`. |
| Import/export | Retained logs identify Godot `4.7.2.stable.official.ed1daf0bf`, finish their import/editor and pack completion markers, and contain no `ERROR`, `SCRIPT ERROR`, `USER ERROR`, `FATAL ERROR` or export-failed marker. The overall packaging log ends with Windows release/ZIP PASS. Root reports the actual packaging process exit zero; this reviewer did not rerun that process. |
| New code present in export | Export log explicitly packs `battle_consumables.gdc`, AI/state/rules and the HUD/battlefield compiled scripts, including their remaps. This is static export evidence; runtime behavior is checked separately by root. |
| Controls and fixed values | README contains G growth/B walking return, P shop, slot selection and D/use button, living own-base purchase, bottle 40 credits/40 energy/2 seconds, patch 50 credits/200 HP/4 seconds, combined capacity two, shared twelve seconds and interruption/death guidance. |
| Notices and licenses | Included Godot license contains the MIT copyright, permission and warranty clauses; component copyright, font OFL and font provenance README are present and included in integrity checks. The generated README directs recipients to retain these notices. |
| Verification scope | Manifest explicitly leaves `actual_windows_pc` and `human_playtest` at `not_run`. README has an unperformed Windows-PC checklist and distinguishes host import/export/package checks from actual Windows execution, Alt-Tab, human play and performance. |

An initial reviewer-only text assertion looked for the optional literal heading “MIT License.” The actual Godot license has no such heading; full-text inspection confirmed all expected clauses. The assertion was corrected in the report data. This was not an artifact defect and required no package change.

## Remaining evidence boundaries

This approval establishes source identity, package integrity, static executable/pack format, retained export evidence and delivery guidance. It does not establish Windows execution, hardware/driver compatibility, DPI/Alt-Tab behavior, human balance or play experience. Root's source-independent PCK execution and graphical capture should be recorded separately with their actual results; actual Windows-PC and human gates remain unperformed.
