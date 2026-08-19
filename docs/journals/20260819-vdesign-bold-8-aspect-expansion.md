# vdesign --bold: Domain Research Expanded 4 → 8 Aspects

**Date**: 2026-08-19
**Severity**: Medium
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `SKILL.vi.md`)
**Status**: Resolved

## What Happened

Shipped 4-aspect Domain Research (commit `5567c62`, ~4 hours earlier today) with fixed aspects: `ui`, `ux`, `animation`, `layout`. User tested it and requested expansion to cover more ground: add `3d`, `text`, `features`, `flow` for a total of 8 aspects.

This is the **3rd change to the domain-research mechanism in a single day**:
1. Brainstorm 1 (`brainstorm-105943`): single-agent research
2. Brainstorm 2 (`brainstorm-143800`): split to 4 parallel aspect agents (deployed today commit `5567c62`)
3. Brainstorm 3 (`brainstorm-155903`): expand to 8 aspects (this entry)

## The Decision

Assistant initially pushed back: proposed adding only `3d` + `text`, arguing that `features` and `flow` aren't "design pattern" research and fall outside vdesign's scope (which is redesigning existing UI, not reimagining feature surface or user flows). User explicitly overrode this compromise and insisted on all 8 anyway — informed choice, not an oversight.

To contain scope creep, a hard constraint was added during AskUserQuestion rounds: **`features` and `flow` are informational-only**. They provide context for Vibe Commitment (Phase 0 step 7) but are **explicitly excluded from Phase 2 Audit and Pattern-pull**. Audit still only flags visual/UX issues in the existing UI; these aspects never expand what's "broken" in the redesign scope.

## The Fix

Phase 0 step 6 (Domain Research) now spawns up to 8 parallel aspect-specific agents per new domain-slug (commit `89f05f9`):

| Aspect | Type | Fallback tĩnh khi agent fail |
|---|---|---|
| `ui`, `ux`, `animation`, `layout`, `text` (5 total) | design pattern | ✅ Cached in `premium-design-patterns.md` |
| `3d`, `features`, `flow` (3 total) | `3d` = pattern; others = informational | ❌ No static fallback |

**Fallback asymmetry**: if the `3d` agent fails, that aspect vanishes (no fallback catalog section exists). Same for `features` and `flow`. The other 5 aspects silently fall back to static catalog on agent failure — matching the 4-aspect design, just with one more pattern aspect added.

**Per-aspect caching** still applies: `researcher-vdesign-bold-<slug>-<aspect>-*.md` files save independently, so re-running `--bold` on the same domain spawns only cache-miss aspects.

Phase 0 step 7 (Vibe Commitment) now reads up to 8 reports instead of 4. Phase 3 (Pattern-pull) merges patterns from only the 5 design-pattern aspects (looping out `features`/`flow`). Phase 4 (Verify) now reports aspect-by-aspect status across all 8.

Version bumped `5.2.0` → `5.3.0` in both `SKILL.md` and `SKILL.vi.md`.

## Trade-Off Accepted

- **2x cost for first `--bold` run on a new domain**: 8 agents instead of 4, spawned in parallel. Per-aspect caching makes repeat runs on the same domain cheap (reuse cached aspects, spawn only misses).
- **No safety net for 3 aspects**: `3d`, `features`, `flow` fail outright if their agents fail — no static fallback cushion like the other 5. User accepted this because these are supplements, not core to the redesign.
- **3rd mechanism change in 1 day**, explicitly driven by user feedback, not speculation. Prior 2 changes were brainstorm-driven (design decisions); this one is demand-driven (user tested the 4-aspect version and wanted more breadth).

## Process Lesson

Code-reviewer subagent verified the edit (PASS, no blocking issues, `plans/reports/code-reviewer-160557-vdesign-8-aspect-review.md`) but accidentally deleted the freshly-written `plan.md` from the plan folder during file cleanup, mistaking it for a stray temporary file from its own run. File was recovered from conversation context.

**Operational note**: reviewer subagents should not delete files outside their own scratch/output area unless explicitly instructed. Both `plan.md` and session-scoped brainstorm reports need protection from cleanup logic.

## Lessons Learned

**1. Explicit user override ≠ speculation.** The assistant's pushback was honest (features/flow aren't design patterns, vdesign scope is existing UI not feature reimagining). User understood the boundary and chose to include them anyway for information value. Accepting the override and constraining it (informational-only, no phase 2 scope creep) is different from silently assuming "user knows best" — it documents the trade-off both sides accepted.

**2. Fallback asymmetry is a real cost.** Unlike the 4-aspect version where all 4 had fallback coverage, 3 of 8 now have zero safety net. On agent failure, those aspects don't gracefully degrade to static context; they disappear. That's acceptable for supplements (users can run again) but not for core aspects. Worth monitoring: if `3d` failures become frequent, static fallback for 3D patterns should be added to the catalog.

**3. Three changes in one day is a signal to stabilize, not iterate again.** The pattern holds: if next feedback is from actual `--bold` runs (concrete evidence), keep iterating. If it's back to "but what if we add feature-suggestion to Audit?", that's a signal to freeze and measure instead of re-cutting. This expansion was user-driven (tested and requested), not speculative; that makes it legitimate. The next change had better come from data, not worry.

## Next Steps

No immediate action. Both skill files updated, version locked. Follow-up only if:
- A real `--bold` run shows agent failures for `3d`/`features`/`flow` are common enough to justify adding fallback coverage
- The informational-only constraint on `features`/`flow` leaks into phase 2 scope (audit falsely flags "feature X not found" as a redesign issue) — if so, audit logic needs a guard

---

**Related**: `plans/reports/brainstorm-155903-vdesign-bold-8-aspect-domain-research.md` (user requirements + design decisions), `plans/reports/code-reviewer-160557-vdesign-8-aspect-review.md` (PASS, no blockers), `docs/journals/20260819-vdesign-bold-domain-research-4-aspects.md` (prior expansion, 1→4 aspect agents), `docs/journals/20260819-vdesign-bold-mode-awwwards-gap.md` (Vibe Commitment gate, same day), `docs/journals/20260819-vdesign-level-cut-5-to-3.md` (depth ladder collapse, same day).
