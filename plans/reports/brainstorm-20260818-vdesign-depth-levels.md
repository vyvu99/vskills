# Brainstorm: vdesign — redesign depth levels (L1-L5)

## Problem
`vdesign` (skills/vdesign/SKILL.md) only has 2 depth modes: `--uplift` (targeted fixes) and `--redesign` (full layout/visual overhaul). User wants finer granularity — sometimes needs a level between these, or something even lighter/heavier — so they can dial exactly how deep a redesign goes instead of a binary choice.

## Scope decided
- Single-file SKILL.md only — no `references/` split, no install.sh changes (repo has zero precedent for multi-file skills; all 10 skills are flat SKILL.md + SKILL.vi.md).
- Bundled in same pass: generalize the hardcoded "Constraints for eTARO" block (personal company name in a public repo) into a reusable Project Profile mechanism.

## Approaches considered
1. **Keep 2 flags, add sub-flags** (e.g. `--uplift --deep`) — rejected, doesn't scale cleanly past 2x2.
2. **5 numbered levels `--L1`..`--L5`, cumulative scope** — chosen. Matches existing content structure (Uplift mode's fix-priority list already reads like a depth ladder: spacing → states → color → typography → components → animation).
3. Semantic-named flags (`--polish`, `--rework`...) — considered, rejected in favor of numbered flags per user preference (simpler to reason about ordering).

## Final design

### 1. Flags — replace `--uplift`/`--redesign` entirely (no alias, no back-compat)
| Flag | Level | Unlocks (cumulative) |
|---|---|---|
| `--L1` | Polish | spacing/alignment, icon size, text-overflow. NOT color/state/layout. |
| `--L2` | Uplift (= old `--uplift`) | + missing states, color/token alignment, typography hierarchy |
| `--L3` | Component rework | + swap/extract/merge components, keep existing grid/flex structure |
| `--L4` | Layout redesign | + change grid/flex structure, section order, density — keep visual direction (card stays card) |
| `--L5` | Full redesign (= old `--redesign`) | + change visual direction entirely, rewrite JSX/TSX from scratch |

Update `argument-hint` in frontmatter accordingly.

### 2. No-flag behavior
Drop silent auto-guessing (riskier to misjudge across 5 levels than 2). If wording is unambiguous ("chỉnh nhẹ thôi" / "làm lại toàn bộ") infer directly; if ambiguous, ask exactly 1 question via `AskUserQuestion` — same pattern already used in Phase 0 step 4 for empty input.

### 3. Phase 2 (Audit) — unchanged
Keep the full audit checklist as-is, not split per level. Phase 3 (Fix) only acts on findings within the current level's unlocked scope; findings outside scope are still reported to the user ("needs `--L4` to fix this") rather than silently dropped.

### 4. Project Profile — generalize "Constraints for eTARO"
Rename section to "Project Profile". Resolution order in Phase 0:
1. `.vdesign/profile.md` in target project's git root, if present → use directly.
2. Absent → infer from `package.json` / tailwind config / components folder.
3. Still ambiguous → ask 1 question, offer to save the answer as `.vdesign/profile.md` for next time (don't write unprompted).

Old eTARO values stay in the doc as a labeled example of the profile shape, not as a default.

### 5. `--bold` — independent axis for Awwwards-tier ambition
Mid-brainstorm the user asked whether any level competes with Awwwards. Answer: no, by design — the "Personal Aesthetic (Non-negotiable)" table and anti-patterns ("DO NOT apply portfolio/avant-garde aesthetics", "clarity > impressiveness") cap every L1-L5 level, since depth-of-diff (L-axis) and creative-boldness (aesthetic-risk axis) are orthogonal. Decision: add `--bold` as a separate flag, not `--L6`.

- **Requires `--L4` or `--L5`.** If passed with no level or with `--L1`-`--L3`, Claude auto-bumps to `--L5` and tells the user it did so — boldness needs layout/visual-direction freedom to mean anything.
- **Suspends** (only for this invocation): "DO NOT apply portfolio/avant-garde aesthetics", "Copy creative design from landing page/portfolio into product UI" anti-pattern, and the "clarity > impressiveness" default bias — allows bespoke art direction, expressive typography scale, unique/asymmetric layout, custom motion.
- **Still mandatory even under `--bold`:** accessibility (contrast, focus rings, loading/empty/error states), no tech-stack migration, no logic/state/API changes, still stop-and-ask before adding a new dependency (e.g. an animation library) — boldness is about visual risk, not about skipping the hard engineering rules.
- Reword the "Non-negotiable" table intro to state it's the default, suspended only when `--bold` is explicitly passed.

### Unchanged
Input Modes (7 types), Aesthetic vocabulary, Phase 1 (Scan), Phase 4 (Verify), Anti-patterns (add one line about mixing levels, e.g. running `--L1` but changing layout anyway).

## Risks
- Boundary between L2 (typography hierarchy edits) and L3/L4 can be fuzzy in practice — left for implementation to resolve case-by-case rather than pre-enumerating every checklist item's minimum level.
- Dropping auto-guess in favor of asking may add one extra round-trip for ambiguous requests — accepted tradeoff per user's explicit preference for explicit numbered flags over guessing.

## Next steps
Hand off to `/ck:plan` (default mode, no TDD — this is a markdown skill-content rewrite, not testable code) to produce the phase file(s) for rewriting `skills/vdesign/SKILL.md` (and mirroring into `SKILL.vi.md`).
