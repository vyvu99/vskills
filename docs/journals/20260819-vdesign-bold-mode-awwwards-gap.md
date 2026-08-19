# vdesign --bold: From "Suspend 3 Rules" to Vibe-Commit + Pattern-Pull

**Date**: 2026-08-19
**Severity**: Medium
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `skills/vdesign/SKILL.vi.md`)
**Status**: Resolved

## What Happened

User reported that `vdesign --L5 --bold` (shipped in commit `75216f5`, 2026-08-18) still wasn't producing output that could compete on Awwwards. Diagnosed via `/brainstorm` + 3 parallel researcher agents (2 local, 1 web) before touching the skill.

**Root cause, confirmed by all three research angles independently:**
1. `--bold` only *suspended* 3 negative constraints ("no avant-garde", "clarity > impressiveness" bias, "no copying creative design") — it never gave positive direction. Suspending constraints without a replacement direction just produces "default design, slightly less constrained," not "intentional bold design."
2. The workflow shape (Scan → Audit → Fix → Verify) is maintenance-reactive — it fixes what's flagged. Award-tier design is concept-first: commit to a vibe, then pull named patterns that belong to it. Without a vibe gate, even L5 output is "polish applied to a default design."
3. The dependency hard rule ("stop-and-ask before adding any new library, no complex animation if Motion/Framer isn't already present") blocked exactly the tooling (GSAP, Lenis, Motion) that 95%+ of 2025-2026 award winners are built on.

## The Fix

No new files, no architecture change — patched both `SKILL.md`/`SKILL.vi.md` in place, version `4.0.0` → `4.1.0`:

1. **Vibe Commitment gate** (new Phase 0 step, `--bold`-only): pick one aesthetic direction (archetype, named 2025-2026 movement, or custom) *before* touching code. Stated explicitly, not silently inferred.
2. **Pattern-pull replaces audit-fix as the Phase 3 ceiling** under `--bold`: audit still runs (catches broken states/a11y/responsive) but is now a floor; bold output is judged by how distinctive the pulled patterns are.
3. **Dependency allowlist**: GSAP, Motion, Lenis, native CSS scroll-driven animations/View Transitions, Rive, Lottie — addable directly under `--bold`, no stop-and-ask. React Three Fiber, Barba.js, paid SaaS beyond Rive, custom WebGL still require asking.
4. **Anti-slop gate before reporting done** — explicit fail conditions (Inter-only, purple-blue gradient, 3 identical cards, placeholder names/copy).
5. **GPU-safe motion rule added** (`transform`/`opacity` only) — B2B mobile LCP is already ~3x over budget per research; bold must not make it worse.

Rather than duplicating the ~300-line pattern/anti-slop catalogs inline, both new sections **reference** `~/.claude/skills/frontend-design/references/{premium-design-patterns.md,anti-slop-rules.md}` — that skill already solved "avoid AI slop" for a different entry point (mockup replication) and the catalogs are directly portable. Single source of truth, no drift risk between two skills maintaining parallel lists.

## Research Method

Per this session's orchestration rules, dispatched 3 parallel `researcher` subagents instead of doing this inline:
- One mined the *already-installed* `frontend-design` skill's reference docs (reuse-before-build; found the exact fix before any web search ran)
- Two did live web research: award-site visual/motion vocabulary (2024-2026 Awwwards/FWA trend data) and the current animation-library tech stack with a bundle-size/CWV-aware allowlist

All three converged on the same root cause (missing concept-first gate) independently — high confidence signal that this was the real fix, not a plausible-sounding guess.

## Lessons Learned

**1. "Suspend the constraint" ≠ "provide the alternative."** The v4.0.0 design correctly identified that `--bold` needed to turn off certain defaults, but stopped one step short: turning something off doesn't automatically turn something else on. The gap between "not corporate-safe" and "actually award-tier" needed a positive direction (vibe commitment), not just permission.

**2. Reuse-before-build caught the highest-value fix for free.** The `frontend-design` skill in this same collection had already solved a closely related problem (AI slop in from-scratch UI generation) with a battle-tested catalog. Referencing it instead of inventing new vocabulary was both faster and more consistent than writing vdesign-specific patterns from scratch.

**3. A hard rule that made sense at `--L1` can be actively wrong at `--bold`.** "Don't add dependencies without asking" is correct hygiene for maintenance work; it's a direct blocker for creative work where the entire toolkit (GSAP/Lenis/Motion) is genre-standard. Depth-level and boldness-level needed *different* dependency policies, not one shared rule with an unstated exception.

## Next Steps

No immediate action — both `SKILL.md` and `SKILL.vi.md` updated and consistent. Follow-up only if a real `--L5 --bold` run still underperforms after this change, in which case the next suspect is asset generation (custom illustration/3D) rather than the workflow shape, per the (unused) Imagen-4 asset-generation guidance surfaced during research but not pulled into this pass — deferred as out of scope until a concrete run demonstrates it's needed.

---

**Related**: `plans/reports/researcher-095509-frontend-design-slop-patterns.md`, `plans/reports/researcher-095509-awwwards-visual-vocabulary.md`, `plans/reports/researcher-095509-award-site-tech-stack.md` (research findings), `docs/journals/20260818-vdesign-depth-ladder-and-bold-flag.md` (prior --bold design this entry supersedes in part).
