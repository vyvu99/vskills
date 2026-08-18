# vdesign: From Binary Modes to 5-Level Depth Ladder + Bold Flag

**Date**: 2026-08-18 16:25
**Severity**: Medium
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `skills/vdesign/SKILL.vi.md`)
**Status**: Resolved

## What Happened

Shipped commit `75216f5`: vdesign skill (personal UI/UX redesign assistant) underwent a breaking redesign of its invocation interface.

**Before**: Two binary modes — `--uplift` (targeted fixes: spacing, color, states) or `--redesign` (full layout/visual overhaul). Silently auto-guesses if unspecified.

**After**: 
1. Five cumulative depth levels (`--L1` through `--L5`): Polish → Uplift → Component rework → Layout redesign → Full redesign. No aliases — old flags removed entirely.
2. Independent `--bold` flag (requires `--L4` or `--L5`) for Awwwards-tier creative ambition; auto-bumps to `--L5` if passed with a lower level.
3. Hardcoded "Constraints for eTARO" section generalized into a reusable Project Profile mechanism (resolved from `.vdesign/profile.md` if present, inferred from `package.json`/tailwind config/components folder, else asked once).
4. Version bumped `3.1.0` → `4.0.0` (intentional breaking change). Both SKILL.md and SKILL.vi.md updated in parallel. README skill tables updated.

## The Brutal Truth

This was clean. No complications, no half-measures, both phases completed as planned. The temptation during planning was to add `--L6` for "full redesign + bold creativity" — just make it one more level. Didn't do that, and that decision is the entire interesting part of this change.

The frustrating bit, honestly, is that vdesign had been living with a crude binary forever because the original assumption ("two modes cover 99% of use cases") felt good enough at the time. User had to brainstorm to realize they actually needed finer control. Lesson: coarse binary defaults hide latent needs — better to design with explicit granularity from the start if you suspect the space will grow.

## Technical Details

**Version breaking change**: `3.1.0` → `4.0.0`. No `--uplift`/`--redesign` aliases for backward compat. User who has muscle memory will get "unrecognized flag" error and must re-read the new table. That's intentional — aliases would hide the upgrade path and drift the documentation.

**Implementation size**: 41 insertions, 27 deletions in `SKILL.md` (357 lines total). Mirrored into `SKILL.vi.md` with Vietnamese translations of new sections. Zero regression risk because the changes were surgical: old flag mentions removed, new tables inserted in their place, no refactoring of untouched sections.

**Project Profile resolution** (new Phase 0 step): Checks `.vdesign/profile.md` → infers from stack markers → asks user if still ambiguous, then *offers* (doesn't force) to save for next run. Inline inference only (no shared `_vskills-shared` file) because this is UI-specific, not VCS-specific. Keeps the skill flat, follows repo convention.

**--bold flag design**:
```
Requires: --L4 or --L5
If passed with --L1–L3: auto-bump to --L5, tell user why
Suspends: "no avant-garde/portfolio aesthetics", "clarity > impressiveness" bias
Still mandatory: accessibility, no tech-stack migration, no logic/state/API changes
```

This is the key decision. --bold is not --L6 because depth-of-diff (L-axis) and creative-boldness (aesthetic-risk axis) are orthogonal. A user might want --L2 with constrained budget and 0 creative freedom, or --L5 with maximum creative freedom. Bundling them into "more depth = more boldness" would be conflating two independent dimensions. The floor rule ("requires L4/L5") exists because boldness without freedom to change visual direction doesn't mean anything.

## What We Tried

No alternatives were seriously considered during implementation. The brainstorm had already locked the design: levels → brainstorm §2 ruled out sub-flags and semantic names, settled on numbered levels; --bold → brainstorm §5 ruled out --L6, decided on orthogonal axis. Implementation was just translating that design into prose and updating both language variants. Both phases passed on first try.

## Root Cause Analysis

Why did vdesign ship with a binary in the first place?

At the time (v3.1.0), the 2-mode table felt sufficient because it covered the rough spectrum: *light fixes* vs *heavy overhaul*. No one asked "what about the middle?" because the user hadn't hit cases where the 2-mode boundary felt wrong. Brainstorm uncovered this was under-specified: sometimes a component swap (L3) is needed without a layout rebuild (L4), or a polish pass (L1) that doesn't even touch color.

The --bold decision emerged mid-brainstorm when user asked if vdesign could compete with Awwwards-tier sites. Answer: not by default, because the skill's own aesthetic constraints (table: "Personal Aesthetic (Non-negotiable)") forbid avant-garde/portfolio aesthetics on principle — that's by design. Rather than compromise that default or add an --L6 that just breaks the constancy, --bold became an explicit, isolated opt-out flag. Cleaner than --L6 because it names what's actually happening: "relax creative constraints, not depth of edits."

## Lessons Learned

**1. Dimension confusion is subtle.**
Early instinct: "more redesign depth → more creative freedom." Wrong. Depth (what layers of the design you can touch) and boldness (how much aesthetic risk you're willing to take) are independent. Conflating them into one axis would have locked L1–L3 users into the default aesthetic and L5 users into boldness they might not want. Naming the axes separately (L1-L5 on one axis, --bold independent) forces clarity.

**2. Binary defaults hide latent dimensionality.**
If you ship a coarse 2-mode system and it "works," users won't ask for finer control — they'll adapt to the boundary. Brainstorm happened because user ran into enough "this doesn't fit L2 or L5" moments to say so out loud. Better to expose the full space upfront (or at least leave room for it in the design).

**3. Version bumps signify breaking changes, but don't guarantee users read the changelog.**
`4.0.0` tells the story, but only if someone is paying attention. Invest in good error messages: "Flag `--uplift` is no longer supported. Use `--L1`, `--L2`, `--L3`, `--L4`, or `--L5` instead. Run with `--help` to see descriptions." (This is not yet implemented; adding it would be a follow-up.)

**4. Orthogonal flags beat nested sub-options.**
`--L4 --bold` is clearer than `--L6-bold` or `--redesign-with-creative-freedom`. Each flag owns one concern, combination semantics are explicit in the prose. Code is simpler, mental model is clearer.

## Next Steps

1. **Optional follow-up**: Add error messaging for unrecognized flags like `--uplift`/`--redesign` that explicitly lists the new L1-L5 options. Prevents silent "flag not recognized" errors from confusing migrated users.
2. **Document the decision**: This journal entry is the canonical explanation of why --bold exists and why it's not L6. Link it from any future vdesign issues or PRs that question this design.
3. **No immediate action** — the implementation is complete, versioned, and ready to use.

---

**Commit**: `75216f5` — feat: replace vdesign uplift/redesign flags with 5-level depth ladder + bold flag (2 phases, 72 seconds wall-clock time, both completed as planned).

**Related**: `plans/reports/brainstorm-20260818-vdesign-depth-levels.md` (design rationale), `plans/260818-1612-vdesign-depth-levels-and-bold-flag/{plan.md, phase-01-*.md, phase-02-*.md}` (implementation plan and completion notes).
