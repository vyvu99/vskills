# vdesign: Level Collapse & --wow Launch (v6.0.0)

**Date**: 2026-09-09
**Severity**: High
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `SKILL.vi.md`, `README.md`, `README.vi.md`)
**Status**: Resolved

## What Happened

User ran `vdesign` for real and hit three concrete failures at once:
1. Phase 2 Audit missed real issues that Phase 3 Fix had to catch later
2. Phase 3 Fix sometimes exceeded the declared level's scope (e.g., rewriting JSX under `--L2` when only structure should move)
3. `--bold` output still read generic/safe despite "Vibe Commitment" gate, defeating the mode's purpose

Same-day investigation traced all three to the same structural gap: the agent writing the fix also grades its own audit/fix/anti-slop compliance — no independent re-check. Additionally, real usage confirmed `--L1`/`--L2` were **never invoked in practice** — users either touched nothing (`--L3`) or went all-in (`--bold`). The level system was overhead.

## The Fix

Shipped v6.0.0 (commit `ba49587`, breaking change):

1. **Deleted `--L1`/`--L2`/`--L3` ladder entirely.** Default `vdesign <target>` now = old `--L3` semantics: audit-driven, fixes everything Phase 2 finds, no depth ceiling. No more "found it but wrong level, can't fix" outcome.
2. **Renamed `--bold` → `--wow`**, dropped its old prerequisite (moot now — only one base mode).
3. **Expanded archetype catalog 3 → 16 vibes** (sourced from researcher survey of award-winning B2B design 2025–2026). Added "one signature element, boldness must be structural" discipline + 6-pattern table (Strategic Accent, Authentic Craft, Typography-First, High-Contrast, Motion-First, Product-Hero) to resolve the core complaint: B2B boldness must work *through* clarity, not despite it. Award winners prove this.
4. **Phase 2 media rework**: renamed "Decorative Images" → "Media & Images", added illustration-slop detection (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps unmodified now flags as 2025–2026 slop tell). Added hero video pattern + responsive art direction.
5. **Added independent verification layer** (Phase 4): Adversarial Verify subagent fires when Phase 3 touched structural code or `--wow` was used — re-audits final state fresh against Phase 2 checklist, loops back to Phase 3 if issues found. Mirrors `vreview`'s existing Adversarial Pass pattern in this repo (reused, not invented). Plus Self-Check gate (inline, every run) confirms fix proportionality.

## The Brutal Truth

This is the **third level-system cut in one day** (the prior two were `20260808-20260819` back-to-back abstract reasoning). But this one is grounded in *real usage data the user explicitly confirmed*, not speculation. That distinction matters: the prior journal (`20260819-vdesign-level-cut-5-to-3.md`) literally said "next change must wait for actual invocations, not abstract reasoning" — this change satisfies that condition rather than repeating the abstract pattern a third time.

Still, the cost is real: Adversarial Verify will fire on most runs now (post-collapse, most runs touch structural code; no level guard). That's the intended side effect, but it must be measured.

## Trade-Offs Accepted

- **No "light touch" mode.** Every invocation can now restructure. Users never used the guard rails anyway; now we match behavior to reality.
- **Adversarial Verify overhead likely significant.** Subagent fires on most runs, not rare cases. Cost to be measured against the concrete benefit (catching audit misses + fix overreach). If excessive, revisit per real data.
- **Breaking change, zero aliases.** Consistent with this skill's prior two cuts. `--L1`/`--L2`/`--L3`/`--bold` will break existing scripts.

## Lessons Learned

**1. Ground the third iteration in real data, not abstract refinement.** The first two cuts (2→5 levels, then 5→3) were both reasoning-driven. This one is usage-driven. That's the only reason it's not a third guess.

**2. Process != one mind grading its own work.** The root cause (Fix agent also auditing itself) is endemic to single-agent design. Adversarial Verify is the structural fix: fresh eyes on the final state, independent from the path taken. Same pattern already lives in `vreview` — reuse it.

**3. Illustration slop is a real UX tell, not gatekeeping.** The 2025–2026 design research (16 archetypes, hero patterns, responsive art direction) isn't about elitism — it's about what actually ships at award-winning B2B companies. Unmodified Blush/Storyset reads cheap now because it's ubiquitous, same as purple gradients 2-3 years ago. This is observable fact, not opinion.

## Next Steps

1. **Monitor Adversarial Verify cost.** Most runs trigger it now (structural-code frequency increased post-collapse). If subagent execution time becomes a blocker, revisit per real overhead metrics.
2. **Gather `--wow` usage metrics.** 16-archetype catalog + discipline pattern + media updates are all shipped blind — no real `--wow` runs on production designs yet. First batch of actual invocations will show if the "boldness through discipline" philosophy lands or needs rework.
3. **Illustration-slop classification refinement.** Initial list (unDraw/Storyset/etc.) is based on 2026 design surveys. May need tuning as new asset sources emerge or older ones go out of rotation.

---

**Related**: `plans/260909-1137-vdesign-level-collapse-and-wow-mode/plan.md` (execution plan, single phase), `plans/reports/brainstorm-113541-vdesign-level-collapse-and-wow-mode.md` (extensive user feedback rounds, naming decisions), `plans/reports/researcher-113037-vdesign-bold-uiux-philosophies.md` (16-archetype taxonomy, bold-through-discipline resolution), `plans/reports/researcher-113103-vdesign-media-image-patterns.md` (hero video + responsive art patterns), `plans/reports/researcher-093600-vdesign-illustration-slop-check.md` (illustration-slop sourcing), `plans/reports/code-reviewer-114909-vdesign-level-collapse-review.md` (PASS, EN/VI parity verified), `docs/journals/20260819-vdesign-level-cut-5-to-3.md` (prior level decision + "wait for real data" lesson that this entry satisfies).
