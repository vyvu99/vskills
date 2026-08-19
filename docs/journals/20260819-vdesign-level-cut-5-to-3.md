# vdesign: 5-Level Depth Ladder Cut Back to 3

**Date**: 2026-08-19
**Severity**: Low
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `SKILL.vi.md`, `README.md`, `README.vi.md`)
**Status**: Resolved

## What Happened

One day after shipping the `--L1`..`--L5` depth ladder (`75216f5`, journaled in `20260818-vdesign-depth-ladder-and-bold-flag.md`), user flagged it as too granular in practice. The 5-level design's own risk section had already predicted this: "Boundary between L2 (typography hierarchy edits) and L3/L4 can be fuzzy in practice — left for implementation to resolve case-by-case." That fuzziness turned out to be real friction, not a theoretical risk.

## The Fix

Collapsed `--L1`..`--L5` (Polish/Uplift/Component rework/Layout redesign/Full redesign) into `--L1`..`--L3`:
- **`--L1` Light** = old L1+L2 merged (spacing, states, color/token, typography — no structural change)
- **`--L2` Structural** = old L3+L4 merged (component swap + layout/grid restructure — visual direction stays the same)
- **`--L3` Full redesign** = old L5 unchanged (visual direction change, JSX/TSX rewrite)

Rationale for the merge boundary: the three collapsed groups map to the only 3 decisions that actually differ in practice — *don't touch structure* / *touch structure but keep visual direction* / *change visual direction entirely*. The old L2/L3/L4 split was cutting inside one of those groups, which is exactly where users can't reliably self-classify before invoking.

`--bold`'s floor moved from requiring `--L4`/`--L5` to requiring `--L2`/`--L3` (same semantic requirement — "needs layout/visual-direction freedom to mean anything" — just renumbered). Version bumped `4.1.0` → `5.0.0` (second breaking change to this skill in 2 days; no aliases, same policy as the original L1-L5 cutover).

## Lesson

Both the 2-mode → 5-level jump and this 5-level → 3-level cut were made without real usage data — the first was over-corrected, this one is a same-day gut-check correction, not a data-driven one either. Worth watching if 3 levels also turns out wrong; if so, the fix next time should wait for a few real `vdesign` invocations to see which boundary actually gets invoked before re-cutting again, rather than reasoning about it in the abstract twice in a row.

---

**Related**: `docs/journals/20260818-vdesign-depth-ladder-and-bold-flag.md` (the 2→5 design this reverses in part), `docs/journals/20260819-vdesign-bold-mode-awwwards-gap.md` (same-day --bold rework, done first, level numbers in that entry refer to the old L1-L5 scheme).
