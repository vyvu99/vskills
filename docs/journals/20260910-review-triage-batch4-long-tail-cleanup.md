# vskills Review Triage Batch 4 — Long-Tail Cleanup: 47 Scattered P1/P2 Findings, One Honest Self-Correction

**Date**: 2026-09-10 23:50  
**Severity**: Low  
**Component**: vspecs, vplan, vcook, vfix, vcheck, vissues, vdesign, vreview, vrules, repo-profile.md, lint-rules/install.sh  
**Status**: Resolved with one self-correcting moment

## What Happened

Completed all 11 phases of batch 4 (long-tail cleanup of ~47 P1/P2 findings scattered across the original external review's per-skill sections). Each phase touched exactly one skill's own file with zero overlap — intentionally disjoint design to avoid the file-collision incidents that plagued batch 2 and batch 3. All 11 phases committed separately and verified. No live incidents. One implementer had a self-correcting moment worth documenting.

**Phases delivered:**
- Phase 1 (vspecs): EARS-format acceptance criteria field, Out of Scope template section, 1-3 page length rule, source-citation requirement for web comparisons, pre-finalize self-check pass, untrusted-web-result pointer
- Phase 2 (vplan): final cross-check step tracing every case to a phase, red/green test discipline in Validate entries, softened absolute "all migrations to Phase 1" rule, Risks/Rollback section, Effort column
- Phase 3 (vcook): test-first now requires proving a failing test before implementation, full-package regression testing instead of "relevant" only, tightened read-only subagent wording, git-status check before branching, concrete commit-count rule, verify-by-running step, worktree guidance
- Phase 4 (vfix): 4th STOP-GATE for data-mutating fixes, fallback for missing lint-rule script, vcheck pass before wrap-up, escape hatch when a rule's own suggested fix is itself wrong, violation-history.jsonl to flag noisy rules
- Phase 5 (vcheck): lint step, --changed flag to scope by git diff, turbo/nx cache awareness, format-tool fallback chain (prettier/biome/eslint), allowed-tools frontmatter
- Phase 6 (vissues): issue-creation dedup now checks the epic's own sub_issues list first (closing residual gap from batch 3), optional milestone/label assignment, final issue-links table, note about live GitHub UI bug
- Phase 7 (vdesign): 3 new WCAG 2.2 checklist criteria, axe-core verification step with manual fallback, ARIA-discipline hard rule, generalized screenshot-tool wording
- Phase 8 (vreview): extended trust-boundary reference to main review flow (batch 3 only added to lint-harvest prompt), migrations get explicit "not semantically reviewed" report section, spot-check now covers 100% of CRITICAL findings from every pass, grouping by changed-line-count instead of file-count, subagents receive only language/framework-relevant plus universal-security rules
- Phase 9 (vrules): --last N cross-PR analysis mode with stricter repetition threshold, 5-step prompt, violation-history.jsonl cross-reference to flag rules that never catch anything, requiring citation of existing rule when rejecting duplicates
- Phase 10 (repo-profile.md): standardized multi-lockfile question into explicit AskUserQuestion shape, preferring package.json dependencies over file-extension counting, test-runner watch-mode table
- Phase 11 (lint-rules/install.sh): ISO-8601 date formatting replacing hardcoded vi-VN/Asia locale formatting in merge-reports.js, documented rule-registry's Vietnamese-only messages as known limitation, added post-install health-check summary table

## The Brutal Truth

This batch was mercifully routine. No red-team pre-review (by design — each phase had zero file overlap and no destructive ops), no isolation breaches, no collateral damage. The codebase made this possible by being scoped tight enough that we could avoid the orchestration disasters that characterized batch 2 and the architectural red-teaming that batch 3 needed.

The one real moment was honest and self-correcting, not a failure.

## Technical Details

### Process Decision: No Pre-Implementation Red-Team

Batch 2 and batch 3 ran formal red-team reviews before any implementation (batch 2 found 13 findings; batch 3 found 19). Batch 4 did not.

**Why:** Each phase touches exactly one skill's file with zero overlap — no file-ownership collisions, no architectural dependencies between phases. Combined with "no destructive ops, no external API changes, no recursive claude calls," the plan surface area is small enough that mandatory post-implementation code review is the right gate, not pre-implementation red-team. Red-team excels at architecture and ownership collisions; code review excels at implementation detail. Batch 4's scoping made red-team a luxury, not a necessity.

**Verification:** Code review found 0 blocking issues. One low-priority observation (install.sh's health-check sed pattern assumes single-line descriptions; not a blocker, flagged for future tightening).

### Pre-Planning Cross-Check Pass

Before committing to the 11-phase plan, a separate pass verified which of the ~50 candidate items from the original review were still actually open against current file state (given batches 1-3 had incidentally fixed a few during refactoring).

**Result:** 47 confirmed open, 1 already mostly fixed by batch 3 (vissues idempotency, with small residual gap closed in this batch Phase 6), 1 no longer applicable (vdesign's cache TTL concern from v5.x era, now moot with v6.0.0's collapse), 1 near-moot.

This pass prevented false-positive "already done" claims and scoped batch 4's real work accurately.

### Phase 11 Self-Correction: Rule-Registry `_meta` Key Attempt

Phase 11's first pass attempted to document the rule-registry's Vietnamese-only messages as a known limitation by adding a new `_meta` field to `rule-registry.json`:

```json
{
  "rule_name": { "script": "...", "scope": "...", "_meta": { "i18n": "vi-only" } }
}
```

This broke the `check-skills.js` registry↔script consistency invariant added in batch 2 (which verifies every registry entry's shape exactly). The implementer caught this during verification, recognized the collision with batch 2's contract, and reverted the approach. Instead, documented the limitation in the install.sh source code itself as a plain comment:

```bash
# Known limitation: rule-registry messages are Vietnamese-only.
# Fixing this would require i18n infrastructure (deferred).
```

**Lesson:** Schema mutations need to propagate through *all* consumers, not just one. The registry is read by 4+ places (vcheck, check-skills.js, vrules, install.sh). A one-off `_meta` field in JSON looks like a clean localized solution but breaks downstream invariants. The comment-based approach is boring but correct — it documents the limitation where it matters (at the tool that has to work around it) without schema expansion.

This was reported honestly to code review, not silently redone. The moment itself showed good instincts (recognize the schema collision, revert immediately) and good reporting (flag the moment as an honest attempt, not hide it).

## What We Tried

1. **Pre-planning cross-check**: Verified 47 of ~50 candidate items from original review were still open, eliminating uncertainty about scope.

2. **No pre-implementation red-team**: Relied on post-implementation code review as the gate, which was sufficient for zero-overlap, non-destructive phases.

3. **Phase 11 schema approach**: Attempted `_meta` JSON field as a clean localization for known limitation → caught the batch 2 invariant collision → reverted to comment → verified → reported.

## Root Cause Analysis

**Why this batch succeeded:** Each phase was small, independently deliverable, touching one file only. This meant: (a) no file-ownership disputes, (b) no need for dependency ordering, (c) no risk of one phase's changes cascading into another's tests, and (d) no plausible route to large-scope incidents. The "scoped tight enough that red-team isn't necessary" design proved itself.

**Phase 11's `_meta` attempt:** A well-intentioned impulse to make the limitation machine-readable (a `_meta` field in JSON) collided with batch 2's invariant. This wasn't a logic error; it was a schema-contract violation. The self-correction happened during the implementer's own verification (not discovered later), which is the right place for this kind of catch.

## Lessons Learned

1. **Small, non-overlapping phases avoid the orchestration problems that plagued earlier batches.** Batch 4 had 11 independent phases with zero file overlap. This meant zero file-ownership collisions, zero need for phase sequencing, and zero risk of one phase's safety mechanisms (like batch 2's revert guard) harming another's work. Design for independence first; then risk drops naturally.

2. **Code review is sufficient for non-architectural changes.** Batch 4 had no pre-implementation red-team. Code review (post-implementation) found 0 blockers. Red-team excels at architecture, assumptions, and ownership; code review excels at implementation detail and local correctness. When the plan has neither architectural risk nor ownership collisions, red-team is a nice-to-have, not required.

3. **Schema changes need all consumers in mind.** Phase 11's `_meta` field looked like a clean, localized fix (one field in one file). But the registry is consumed by 4+ tools, and batch 2 had added a shape invariant on top of the registry. A schema change needs to verify itself against *all* downstream consumers, not just one. The revert to a code comment was the right call — boring, but correct.

4. **Pre-planning cross-checks close uncertainty loops.** Before batch 4 started, a pass verified which of the ~50 candidate items were still open. This sounds like overhead, but it eliminated the "did we already fix this?" uncertainty that would have emerged mid-phase. 47 items confirmed → scope is real.

5. **Honest reporting of self-corrections builds credibility.** Phase 11 had a moment: tried an approach, hit an invariant, reverted, and reported it. Not hiding this moment as "oh, I just changed my mind" but documenting the actual collision and the fix means the next implementer who reads this journal sees a case study in "how to spot a schema collision" rather than a mysterious decision.

## Next Steps

1. **Immediate:** All 11 phases complete, all commits verified, code review found 0 blockers. This batch closes the original external review's ~47 actionable findings.

2. **Deferred (explicitly out of scope, per user confirmation):** Original review's "Đợt 4" (5 new skills) and larger efforts (Semgrep migration for lint rules, dual rule-script+prose output mode for vrules, deeper vreview eval benchmarking).

3. **Future pattern:** Batch 4's "scoped tight, zero overlap, post-implementation review sufficient" design is a useful playbook for cleanup passes. Document as a template for future maintenance batches.

---

**Verification:** All 11 phase files in `plans/260910-1146-vskills-review-triage-batch4/` show complete deliverables. All 11 commits are live on main. Code review returned 0 blockers. This batch closes out the original review's scattered long-tail findings.
