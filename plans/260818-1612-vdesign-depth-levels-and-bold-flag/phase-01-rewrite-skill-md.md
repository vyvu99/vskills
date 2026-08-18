---
phase: 1
title: Rewrite SKILL.md
status: completed
priority: P2
effort: 1-2h
dependencies: []
---

# Phase 1: Rewrite skills/vdesign/SKILL.md

## Overview
Rewrite the English source of the vdesign skill (`skills/vdesign/SKILL.md`, 357 lines) to replace the 2-mode `--uplift`/`--redesign` system with a 5-level depth ladder (`--L1`-`--L5`), add an orthogonal `--bold` flag, and generalize the hardcoded eTARO constraints block into a Project Profile mechanism. Full rationale: `plans/reports/brainstorm-20260818-vdesign-depth-levels.md`.

## Requirements

### Functional
- `--L1`..`--L5` flags replace `--uplift`/`--redesign` entirely — no aliases, no back-compat shim.
- Each level's allowed-action set is cumulative (Ln includes everything Ln-1 allows, plus its own additions).
- No-flag behavior: infer level directly from unambiguous wording; if ambiguous, ask exactly 1 question via `AskUserQuestion` (reuse the existing Phase 0 step-4 pattern used for empty input).
- Phase 2 (Audit) checklist stays untouched — it is not split per level.
- Phase 3 (Fix) only applies fixes within the current level's unlocked scope. Findings outside scope are still reported to the user (not silently dropped), with a note on which `--L` would unlock the fix.
- New `--bold` flag, independent of the L-axis: unlocks Awwwards-tier creative freedom (suspends the "no avant-garde/portfolio" default) but requires `--L4` or `--L5` — if passed with no level or with `--L1`-`--L3`, auto-bump to `--L5` and tell the user.
- `--bold` never suspends: accessibility requirements, tech-stack constraints, logic/state/API preservation, or the "stop and ask before adding a new dependency" rule.
- "Constraints for eTARO" section renamed to "Project Profile", sourced in this order: (1) `.vdesign/profile.md` at the target project's git root if present, (2) inferred from `package.json`/tailwind config/components folder, (3) ask 1 question if still ambiguous, offering to save the answer to `.vdesign/profile.md` (never write it unprompted). Old eTARO values remain as a labeled example of the profile's shape, not as a default.

### Non-functional
- Keep the file as a single flat `SKILL.md` — no `references/` directory, no changes to `install.sh`.
- Preserve all content that isn't explicitly called out for change: Input Modes (7 types), Aesthetic vocabulary keywords table, Phase 1 (Scan), Phase 2 (Audit checklist), Phase 4 (Verify), the bulk of Anti-Patterns.

## Architecture

### 1. Frontmatter (lines 1-12)
- Update `argument-hint` from `"[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--uplift | --redesign]"` to `"[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--L1 | --L2 | --L3 | --L4 | --L5] [--bold]"`.
- Bump `metadata.version` from `3.1.0` to `4.0.0` (breaking flag change).

### 2. Top-of-file level table (lines 18-26, currently "Two levels")
Replace the 2-row table + prose with a 5-row cumulative table:

| Flag | Level | Unlocks (cumulative on top of the previous level) |
|------|-------|------|
| `--L1` | Polish | Spacing/alignment, icon size, text-overflow. Does NOT touch color, state, or layout. |
| `--L2` | Uplift | + missing states (loading/empty/error/hover/focus/active/disabled), color/token alignment, typography hierarchy |
| `--L3` | Component rework | + swap/extract/merge components; grid/flex structure stays as-is |
| `--L4` | Layout redesign | + change grid/flex structure, section order, density — visual direction stays the same (a card stays a card) |
| `--L5` | Full redesign | + change visual direction entirely (card→list, sidebar→top nav), rewrite JSX/TSX from scratch |
| _(none)_ | Ask | If wording is ambiguous, ask 1 question via `AskUserQuestion` listing the 5 levels with a 1-line description each — do not silently guess |

Add directly below: `--bold` (optional, independent flag) — see new subsection under Phase 3.

### 3. Phase 0 (Determine scope) — add Project Profile resolution
Insert a new step after the existing step 3 (`--pr` resolution) and before step 4 (empty → ask):
- Resolve Project Profile: check `.vdesign/profile.md` at the target project's git root (`git rev-parse --show-toplevel`) → if present, read and use as the Project Profile for this run.
- Absent → infer UI library / design tokens by scanning `package.json` dependencies, `tailwind.config.*`, and the components folder structure (this reuses the same kind of stack-detection spirit as `~/.claude/skills/_vskills-shared/repo-profile.md`, but stays inline in vdesign since it's UI-specific, not VCS-specific — do not create a shared file for this).
- Still ambiguous → ask exactly 1 question, then offer (don't force) to save the resolved profile to `.vdesign/profile.md` for future runs.

### 4. Phase 3 (Fix) — replace "Uplift mode" / "Redesign mode" fix-order lists
Replace the two separate ordered lists (lines 265-277) with one cumulative table matching the level table in section 2 above (same 5 rows, same "unlocks" column reused or referenced). Directly below it, add the `--bold` subsection:

> **`--bold` (optional, requires `--L4` or `--L5`)**
> If passed without a level, or with `--L1`-`--L3`, bump to `--L5` and tell the user why.
> Suspends for this run only: "DO NOT apply portfolio/avant-garde aesthetics" and the "clarity > impressiveness" default bias, and the anti-pattern "Copy creative design from a landing page/portfolio into product UI".
> Still mandatory even under `--bold`: accessibility (contrast, focus rings, all required states), no tech-stack migration, no logic/state/API changes, still stop-and-ask before adding a new dependency (e.g. an animation library).

Update the "Hard rules (apply to both modes)" header (line 279) to "Hard rules (apply to every level, including `--bold`)" since it's no longer 2 modes.

### 5. Personal Aesthetic (Non-negotiable) section (lines 44-59)
Reword the intro sentence to make explicit that the table is the default, suspended only when `--bold` is passed: e.g. "This is the user's vocabulary — **ALL** must be met by default, not just a few picked at random. Suspended only when `--bold` is explicitly passed (see Phase 3)."

### 6. Constraints for eTARO (lines 308-320) → Project Profile
Rename heading to "## Project Profile". Rewrite the intro to describe the 3-step resolution order from section 3 above. Keep the existing eTARO table content but relabel it clearly, e.g.: "### Example — eTARO project profile (illustrative shape, not a default)" followed by the same table (UI library, design tokens, motion library, context, good reference UI, font, form fields) unchanged in content.

### 7. Anti-Patterns (lines 324-352)
Add one new bullet: "❌ Run a low level (e.g. `--L1`) but change layout/visual direction anyway — stay within the current level's unlocked scope, report out-of-scope findings instead of fixing them."

## Related Code Files
- Modify: `skills/vdesign/SKILL.md`

## Implementation Steps
1. Read the current full file (`skills/vdesign/SKILL.md`) fresh before editing (it may have shifted since this plan was written).
2. Update frontmatter: `argument-hint`, `metadata.version`.
3. Replace the "Two levels" table + prose (top of file) with the 5-level cumulative table + `--bold` mention, per Architecture §2.
4. Insert the Project Profile resolution step into Phase 0, per Architecture §3.
5. Replace the Phase 3 "Uplift mode"/"Redesign mode" lists with the cumulative level table + `--bold` subsection + reworded "Hard rules" header, per Architecture §4.
6. Reword the Personal Aesthetic (Non-negotiable) intro sentence, per Architecture §5.
7. Rename "Constraints for eTARO" to "Project Profile", restructure per Architecture §6.
8. Add the new anti-pattern bullet, per Architecture §7.
9. Re-read the full file once more end-to-end to check internal consistency: no leftover reference to `--uplift`/`--redesign`, no leftover "Uplift mode"/"Redesign mode" wording anywhere in the file (grep for these terms to confirm zero hits outside intentional historical mentions, e.g. "L2 Uplift" is fine, bare "Uplift mode" is not).

## Success Criteria
- [x] `grep -n "uplift\|redesign" skills/vdesign/SKILL.md` shows no leftover references to the old flag names as flags (mentions of "redesign" as a general English word, e.g. "redesign UI/UX", are fine and expected).
- [x] Frontmatter `argument-hint` lists `--L1`-`--L5` and `--bold`, `metadata.version` is `4.0.0`.
- [x] 5-level table present near the top of the file with cumulative "unlocks" wording.
- [x] Phase 0 includes the Project Profile 3-step resolution order.
- [x] Phase 3 has one cumulative level table (not two separate mode lists) plus a `--bold` subsection stating the `--L4`/`--L5` requirement and what it suspends vs. keeps mandatory.
- [x] "Personal Aesthetic (Non-negotiable)" intro explicitly states it's suspended only under `--bold`.
- [x] "Project Profile" section exists with the 3-step resolution order and the old eTARO table kept as a clearly-labeled example.
- [x] New anti-pattern bullet about mixing levels is present.
- [x] Everything not called out above (Input Modes table, Aesthetic vocabulary table, Phase 1 Scan, Phase 2 Audit checklist, Phase 4 Verify, remaining Anti-Patterns) is unchanged from the current file.

## Risk Assessment
- **Fuzzy L2/L3 boundary**: typography-hierarchy edits (L2) can blur into component swaps (L3) in practice. Not resolved here — left for real invocations to judge case-by-case, consistent with the brainstorm's decision not to pre-enumerate every audit checklist item's minimum level.
- **Version bump visibility**: bumping to `4.0.0` with no alias is a deliberate breaking change (confirmed by user in brainstorm) — no mitigation needed, but flag it in the phase completion note so it's not mistaken for an oversight.
