---
title: Generalize vskills compatibility via repo-profile detection
description: >-
  Add a shared repo-profile detection doc so skills adapt to any package manager
  / VCS host / framework instead of hardcoding pnpm + GitHub + Next.js +
  Vietnamese.
status: completed
priority: P2
effort: 5h
branch: main
tags:
  - skills
  - portability
  - detection
  - install
blockedBy: []
blocks: []
created: '2026-08-18T07:45:35.506Z'
createdBy: 'ck:plan'
source: skill
---

# Generalize vskills compatibility via repo-profile detection

## Overview

**Problem.** 6 of 10 skills hardcode the author's stack: `pnpm --filter` (`skills/vcheck/SKILL.md:40,54`), `gh` CLI as if it always exists (`skills/vissues/SKILL.md:37-74`, `skills/vrules/SKILL.md:36-40`, `skills/vdesign/SKILL.md:39,68`, `skills/vreview/SKILL.md:88`), `next/image` (`skills/vdesign/SKILL.md:216`), PR description forced to Vietnamese (`skills/vcook/SKILL.md:111,126`). On any other stack the skill either emits a wrong command or hard-fails mid-run.

**Solution.** One shared reference doc `skills/_vskills-shared/repo-profile.md` with 4 detection sections (§1 package manager + workspace, §2 VCS host + CLI, §3 language/framework, §4 PR language). Each affected skill replaces its hardcoded assumption with a one-line pointer to the section. No logic duplicated per skill.

**Non-goal (explicit).** No GitLab/`glab` support — non-GitHub hosts only get *graceful degradation*: one clear `⚠️` line + manual instructions, then the skill continues. YAGNI until a real pain point shows up.

**Hard invariant.** On the author's own repos (pnpm + GitHub + `gh` installed + TypeScript + Vietnamese CLAUDE.md), every detection path must resolve to the exact command that runs today. Detection is additive; nothing about the current default changes.

**Cross-cutting rule for every skill edit (applies to phases 2 and 3):** the pointer line must be *soft* — "read `~/.claude/skills/_vskills-shared/repo-profile.md` §N if present; if missing, assume `<current hardcoded default>`". A user who copied a single SKILL.md without running `install.sh` must still get today's behavior, never a dead reference that stalls the run.

**Scope.** Markdown only — 1 new file, 2 doc files, 1 shell script, 6 skills × 2 language variants. No application code, no tests to run (repo has no test suite); validation is `./install.sh --dry-run` plus a read-back tabletop walkthrough of Case A / Case B (below).

**Validation cases used in every phase's success criteria:**
- **Case A (must not change):** pnpm monorepo + GitHub remote + `gh` authed + `.ts/.tsx` + Vietnamese CLAUDE.md → skill emits the identical commands it emits today.
- **Case B (must degrade, not crash):** npm single-package + self-hosted git remote + no `gh` + `.py` files + no language section anywhere → `npm exec -- <cmd>` (no `--filter`), `⚠️` + manual PR/issue instructions, skill continues, English PR text.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Shared repo-profile foundation](./phase-01-shared-repo-profile-foundation.md) | Completed |
| 2 | [Wire mechanical skills](./phase-02-wire-mechanical-skills.md) | Completed |
| 3 | [Wire content-heavy skills](./phase-03-wire-content-heavy-skills.md) | Completed |

## Dependencies

- **Phase 1 blocks phases 2 and 3** — both only add pointers to `skills/_vskills-shared/repo-profile.md`; the section numbering (§1–§4) must be frozen before any skill cites it.
- **Phase 2 ∥ Phase 3** — disjoint file ownership (P2: vcheck, vissues, vrules, vdesign; P3: vcook, vreview), can run in parallel after phase 1.
- No external dependencies. `install.sh` is the only executable touched.

## File ownership

| Phase | Owns |
|-------|------|
| 1 | `skills/_vskills-shared/repo-profile.md`, `install.sh`, `README.md`, `README.vi.md` |
| 2 | `skills/vcheck/*`, `skills/vissues/*`, `skills/vrules/*`, `skills/vdesign/*` |
| 3 | `skills/vcook/*`, `skills/vreview/*` |

No file is touched by two phases. Exception: phase 2 makes a 2-word wording fix in `README.md`/`README.vi.md` (vcheck row) — do it *after* phase 1 lands to avoid a conflict, or fold it into phase 1 if both run in the same session.

## Rollback

Every phase is markdown-only and independently revertable with `git revert <phase-commit>`. Phase 1 revert additionally requires re-running `./install.sh` to drop the now-dangling `~/.claude/skills/_vskills-shared` symlink (or `rm ~/.claude/skills/_vskills-shared`). Reverting phase 1 while 2/3 are live leaves skills pointing at a missing file — safe by design, because every pointer carries its own inline fallback (see cross-cutting rule above).

## Open questions

None blocking. One deferred decision: whether `repo-profile.md` deserves a `SKILL.vi.md`-style translation — decided **no** (it is a technical reference read by the model, not the user; both language variants of every skill point at the same English file).

## Validation Log

### Session 1 — 2026-08-18
**Trigger:** `/ck:plan validate` after initial plan authored by `planner` subagent.
**Questions asked:** 4

#### Verification Results
- **Tier:** Standard (3 phases → Fact Checker + Contract Verifier, 10 claims/phase budget)
- **Claims checked:** ~30 file:line citations sampled across all 3 phases via direct `sed`/`grep` against source
- **Verified:** 28 | **Failed:** 2 | **Unverified:** 0

#### Failures
1. [Fact Checker] `skills/vreview/SKILL.md` — phase-03 Step 3 cited line 45 for `1.1 Determine the changes`; actual line is 53 (line 45 is a blank line inside the Phase 0 header block).
2. [Contract Verifier] `skills/vissues/SKILL.md` — phase-02 Step 2 validate criterion said "the same 6 gh commands"; grep found 9 distinct `gh` invocations (2× `gh issue list --search`, `gh label list`, 2× `gh issue create`, `gh issue edit`, 3× `gh api graphql`).

#### Questions & Answers

1. **[Fact-check]** Fix the wrong vreview line citation (45 → 53)?
   - Options: Fix to line 53 (Recommended) | Leave as-is, implementer will re-grep
   - **Answer:** Fix to line 53
   - **Rationale:** Cheap, unambiguous correction — avoids sending the implementer to the wrong spot in a 698-line file.

2. **[Fact-check]** Fix the wrong vissues gh-command count (6 → actual)?
   - Options: Rephrase criterion as "unchanged in content" instead of counting (Recommended) | Fix to exact number (9)
   - **Answer:** Rephrase as "unchanged in content"
   - **Rationale:** The real invariant is "commands don't change," not a specific count — a hardcoded number is fragile if a future edit adds/removes a `gh` call for an unrelated reason.

3. **[Risk/Assumption]** §1 command templates for yarn/npm/bun are derived from docs, not exercised against a real repo (only the pnpm case is battle-tested via Case A). How to handle?
   - Options: Accept, document as best-effort in repo-profile.md (Recommended) | Add a pre-merge verification step against real yarn/npm/bun repos
   - **Answer:** Accept, document as best-effort
   - **Rationale:** YAGNI — the author's daily case (pnpm) must be exact; the other three are correctness-on-first-use, not correctness-guaranteed, and get fixed against a real case when one appears rather than speculatively hardened now.

4. **[Scope/Tradeoff]** Phase 2 and 3 have disjoint file ownership and could cook in parallel. Sequential or `--parallel`?
   - Options: Sequential `/ck:cook plan.md` (Recommended) | `/ck:cook --parallel plan.md`
   - **Answer:** Sequential
   - **Rationale:** Plan is small (12 files, ~5h estimate); parallel-cook coordination overhead isn't worth it, and the plan wasn't authored with the `--parallel` mode's explicit ownership-matrix format.

#### Confirmed Decisions
- vreview profile-resolution block lands after line 53 (not 45) in phase-03.
- vissues Case A criterion is qualitative ("commands unchanged"), not a specific count.
- yarn/npm/bun templates ship as best-effort with an inline `<!-- best-effort, unverified -->` marker in `repo-profile.md`; no separate verification step added.
- Implementation will run via sequential `/ck:cook {plan-dir}/plan.md`, not `--parallel`.

#### Action Items
- [x] phase-03: line 45 → 53 (done — this session)
- [x] phase-02: "6 gh commands" → "unchanged in content" in both Validate line and Success Criteria (done — this session)
- [x] phase-01: added best-effort/unverified note for §1 yarn/npm/bun rows (done — this session)

#### Impact on Phases
- Phase 1: `repo-profile.md` §1 spec now carries an explicit best-effort caveat for non-pnpm rows.
- Phase 2: vissues validate/success-criteria wording de-numbered.
- Phase 3: vreview profile-block insertion point corrected.

### Whole-Plan Consistency Sweep
- Files reread: plan.md, phase-01-shared-repo-profile-foundation.md, phase-02-wire-mechanical-skills.md, phase-03-wire-content-heavy-skills.md
- Decision deltas checked: 4 (line-number fix, count-wording fix, best-effort caveat, cook-mode choice)
- Reconciled stale references: 3 (phase-03 line cite, phase-02 Validate line, phase-02 Success Criteria line) — grepped `"line 45"` and `"6 gh"`/`"all 6"` across all phase files after edits, zero remaining stale hits
- Unresolved contradictions: 0
