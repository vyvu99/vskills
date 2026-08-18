---
phase: 2
title: Mirror SKILL.vi.md
status: completed
priority: P2
effort: 1h
dependencies:
  - 1
---

# Phase 2: Mirror changes into skills/vdesign/SKILL.vi.md

## Overview
Apply the same structural changes from Phase 1 to the Vietnamese translation (`skills/vdesign/SKILL.vi.md`, ~25.8K) so both language variants stay in parity — `install.sh --lang=vi` symlinks this file as the installed `SKILL.md` for Vietnamese users, so it must carry the identical flag/behavior contract as the English source, not just similar prose.

## Requirements
- Every structural/behavioral change from Phase 1 (§2-§7 of that phase's Architecture) must have a Vietnamese-language equivalent in the same relative location in `SKILL.vi.md`.
- Match the existing translation register already used in this file: section headers are translated (e.g. "## Ràng buộc riêng cho eTARO" → becomes "## Hồ Sơ Dự Án" or similar consistent with how other headers are phrased, e.g. "## Gu Thẩm Mỹ Cá Nhân (Không thương lượng)"), while technical terms (component, layout, flag, grid/flex, token) stay in English as the file already does throughout.
- Do NOT re-translate or touch any section outside what Phase 1 changed (Input Modes, Aesthetic vocabulary table body, Phase 1 Scan, Phase 2 Audit checklist, Phase 4 Verify, unrelated Anti-Patterns bullets) — this is a mirror pass, not a full re-translation.
- Frontmatter fields (`argument-hint`, `metadata.version`) must match Phase 1's English file exactly (these are not translated content).

## Architecture
1. Diff the finished Phase 1 `SKILL.md` against its pre-Phase-1 git version (`git diff skills/vdesign/SKILL.md` or compare against the version described in `plans/reports/brainstorm-20260818-vdesign-depth-levels.md`) to get the exact set of changed sections.
2. For each changed section, locate the corresponding section in `SKILL.vi.md` using the header mapping already observable in the file (English → Vietnamese header pairs are 1:1 today, e.g. "Constraints for eTARO" ↔ "Ràng buộc riêng cho eTARO", "Anti-Patterns" ↔ "Anti-Patterns (KHÔNG được làm)").
3. Translate the new/changed English content into the same register, reusing existing Vietnamese terminology already present in the file for concepts that repeat (e.g. how "redesign" and "uplift" were previously handled as loanwords — check how the file currently phrases the mode table before deciding whether `--L1`-`--L5`/`--bold` names stay as literal flags, likely as-is since they're CLI flags, not prose).

## Related Code Files
- Modify: `skills/vdesign/SKILL.vi.md`
- Read (reference, do not modify): `skills/vdesign/SKILL.md` (Phase 1 output), `plans/reports/brainstorm-20260818-vdesign-depth-levels.md`

## Implementation Steps
1. Read the finished `skills/vdesign/SKILL.md` from Phase 1 in full.
2. Read the current full `skills/vdesign/SKILL.vi.md` in full.
3. Update frontmatter (`argument-hint`, `metadata.version`) to match Phase 1 exactly.
4. Replace the Vietnamese "2 levels" table/prose near the top with the translated 5-level cumulative table + `--bold` mention.
5. Insert the Project Profile resolution step into the Vietnamese Phase 0 section, in the same position as Phase 1.
6. Replace the Vietnamese Phase 3 "Uplift mode"/"Redesign mode" lists with the translated cumulative table + `--bold` subsection + reworded "Hard rules" header.
7. Reword the Vietnamese "Gu Thẩm Mỹ Cá Nhân (Không thương lượng)" intro to state it's suspended only under `--bold`.
8. Rename "Ràng buộc riêng cho eTARO" to a Vietnamese equivalent of "Project Profile", restructure with the 3-step resolution order (translated) and keep the eTARO table as a labeled example.
9. Add the translated anti-pattern bullet about mixing levels.
10. Re-read both files side by side once more to confirm section-for-section parity (same number of changed sections, same flags, same behavioral claims) — this is a consistency check, not a literal word-for-word translation check.

## Success Criteria
- [x] `skills/vdesign/SKILL.vi.md` frontmatter matches `SKILL.md` frontmatter exactly on `argument-hint` and `metadata.version`.
- [x] All 6 changed sections from Phase 1 have a corresponding, behaviorally-equivalent Vietnamese section in the same relative position.
- [x] No leftover Vietnamese references to `--uplift`/`--redesign` as flags, or to "Uplift mode"/"Redesign mode" as named modes.
- [x] Sections Phase 1 did not touch remain byte-identical to their pre-Phase-1 state in `SKILL.vi.md`.

## Risk Assessment
- **Drift risk**: if Phase 1's exact section wording changes during its own implementation (e.g. a reviewer tweaks phrasing), this phase must re-diff against the actual Phase 1 output, not against this plan's Architecture prose — the plan describes intent, Phase 1's real file is the source of truth.
