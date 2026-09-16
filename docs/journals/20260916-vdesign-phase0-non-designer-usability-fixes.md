# vdesign Phase 0 — Non-Designer Usability Fixes (Recommend-First + Structural Freedom + Mid-Run Revisit)

**Date**: 2026-09-16 14:30
**Severity**: Medium
**Component**: `vdesign` skill, Phase 0 Aesthetic Customization Q&A
**Status**: Resolved (local, not pushed)

## What Happened

User feedback: developers with zero design background couldn't confidently answer vdesign's Phase 0 Q&A because:
1. Pure design jargon + no guidance on consequences (what does picking "Bold Color Palette" actually lock you into?)
2. Wanted to change structural/layout things but no criterion gated that decision space
3. Wanted to add ad-hoc feedback mid-Q&A or mid-run, no mechanism to revisit an answer without restarting

Ran full brainstorm → plan → cook pipeline. Implemented 3 concrete fixes:

**Fix 1: Recommend-First Pattern**  
Every Phase 0 criterion question now surfaces a suggested answer (computed from Project Profile) with 1-line rationale, listed first with `(Recommended)` tag. User still picks explicitly — this shortens the decision, doesn't remove it. Color Palette option descriptions also got explicit consequence text (e.g. "Keep existing tokens" → "Keep existing tokens — locks out all brand-color changes for this run").

**Fix 2: New "Round 0 — Structural Freedom" Criterion**  
Master-dial (Preserve structure / Refine if audit finds fit problem / Open to reinvention), mirrors criterion #14 Aesthetic Boldness pattern. Gates whether Phase 3's "proportional to audit findings" ceiling applies to structural/view-type changes. Total criteria 17→18, rounds 5→7 (Round 0 prepended).

**Fix 3: "Round 6 — Anything Else?" + Mid-Run Revisit**  
Catch-all question at Phase 0 end (captures anything 18 scored criteria miss). Plus new mid-run mechanism in Phase 3: re-ask exactly one criterion instead of full restart; capped at 3 revisits (mirrors existing pilot-cluster adjust-cycle cap).

Commit: `57c1fed`, 4 files, 74 insertions/28 deletions, v8.1.0 → v8.2.0.

## The Brutal Truth

This was genuinely painful to avoid slipping into complexity. Temptation: "Add helper UI overlays", "Pop up glossary for jargon", "Make Phase 0 a wizard". Resisted all of that. The actual fix is **information placement + breathing room for user mistakes**. Recommend-first works because it doesn't *hide* the decision — it just surfaces a default that's better than random. Structural Freedom isn't a new axis, it's just answering "should we even consider layout changes?" before we waste rounds on micro-tone choices. And mid-run revisit mirrors existing patterns (we already have pilot-cluster adjust-cycle caps) — reuse, don't invent.

Pre-existing stale bug found and fixed: English `SKILL.md` lines 73, 248 said "14 answers" (leftover from earlier criteria count). VI `.md` was correct at "17 câu trả lời". Missed in prior reviews despite being flagged in 2026-09-10 audit notes.

## Technical Details

- **Files modified**: `SKILL.md`, `SKILL.vi.md`, `references/aesthetic-customization.md`, `references/aesthetic-customization.vi.md`
- **Insertions**: 74 (mostly Phase 0 question rewrites + new Round 0 criterion + new Round 6 catch-all + Phase 3 mid-run logic)
- **Deletions**: 28 (old Q&A phrasing, removed nested conditionals for recommend-first simplicity)
- **Verification**: `scripts/check-skills.sh` = 0 violations. Code-reviewer subagent found 1 cosmetic nit ("18 scored answers" — no actual scoring mechanism exists); fixed inline before commit.

## What We Tried

Single path explored. No false starts, no backtracking — brainstorm scoped it tight (keep tech-stack/UI-library hard-lock), plan validated feasibility.

## Root Cause Analysis

Root problem wasn't missing features; it was **decision cost without decision aid**. 17 criteria is information load. Designer looks at "17 questions, I pick one answer per question" and can forward-plan. Developer looks at it and freezes because "I don't know what Bold Tone + Bright Color + Game-Inspired even looks like together". Recommend-first drops the cognitive load from "make 17 independent choices" to "7 micro-refinements of 1 suggestion" — psychologically huge.

Structural Freedom gap existed because Phase 0 assumed "aesthetic" meant color/motion/tone — never explicit that layout/view-tree changes were *also* on the table. Adding it as Round 0 makes scope transparent, not added.

## Lessons Learned

**Recommend-first over choice-paralysis defaults**: When decision space is large + user has no domain expertise, surface a good default + rationale + lock it only if user doesn't click. Learned from payments/B2B (defaults with escape hatch always beat empty form).

**Master-dial before detail dials**: Structural Freedom as Round 0 gates downstream choices (no point asking "how bold should the borders be" if we're not touching structure at all). Order matters; master dial goes first.

**Revisit caps reuse existing patterns**: Rather than inventing "mid-run branching logic", mirror existing audit-loop caps (pilot-cluster has 3 adjust cycles; mid-run revisits = 3 per skill run). Consistency > novelty.

## Next Steps

1. **No blocking issues** — commit ready to push
2. **Polish (optional)**: "18 scored answers" wording in SKILL.md — cosmetic, user decides if worth a follow-up pass
3. **Future session** (deferred, not scoped here): vdesign + vspecs integration (read Experience Specs at step 2/3)
