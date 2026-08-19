# Full-Repo Skill Audit: 20 Findings Across 7 Skills, All Fixed

**Date**: 2026-08-19
**Severity**: Medium (1 Critical logic bug, rest doc/consistency defects — no data-loss risk)
**Component**: `skills/vcook`, `skills/vmigrate-rollback`, `skills/vissues`, `skills/vreview`, `skills/vfix`, `skills/vspecs`, `skills/vcheck`, `README.md`/`README.vi.md`
**Status**: Resolved

## What Happened

User asked to check all skills for problems ("check các skill khác xem có vấn đề gì ko"), after the vdesign domain-research fix earlier this session. Dispatched 9 parallel `code-reviewer` subagents (one per skill, `vplan`/`vrules` came back clean) to audit `SKILL.md`+`SKILL.vi.md` pairs for: internal contradictions, broken cross-references, EN/VI drift, README consistency, frontmatter sanity. Reported 20 concrete findings back to the user grouped by severity. User's follow-up: fix `vcook`'s Critical finding by decoupling from the `cook` base skill (not by reconciling the sequencing), and fix everything else.

## Findings & Fixes

**Critical — vcook (`SKILL.md:15`, `extends: cook`)**: instructed "invoke `cook` skill first, then apply 9 steps on top" — but `cook`'s own gates (branch-agnostic implement, its own test/review/commit) ran *before* vcook's Step 2 (branch) / Step 4 (test-first) / Step 9 (commit+PR), causing wrong-branch implementation and duplicate test/review/commit work. On inspection, vcook's own 9 steps were already a complete, self-sufficient workflow (branch → input mode → test-first → implement → SDK → review → test → commit/PR) — the `cook` invocation was pure redundancy, not a missing piece. Fix: deleted the invoke-`cook` line and `extends: cook` entirely. Also fixed two Medium/Low findings surfaced in the same skill: Step 1 (parallelize) was framed as a one-time TodoWrite item despite its own text saying "apply throughout" — now explicitly kept `in_progress` until Step 9; and the PR-language fallback falsely attributed an "if absent → Vietnamese" rule to `repo-profile.md` §4 (which doesn't say that) — reworded to do the 3-step resolution directly without requiring the file to exist.

**High — vissues idempotency bug (`SKILL.md` Step 3.4-3.5)**: "skip `addSubIssue` for already-linked sub-issues" had no detection mechanism — no query ever checked link state. Fix: added `parent{id}` to the existing node-ID GraphQL query, compare against the epic's node ID to decide skip-vs-link. This is the one fix in the batch that adds new query logic rather than just clarifying prose — worth flagging because a `code-reviewer` catching "the described mechanism doesn't exist" (not just "is worded ambiguously") is the higher-value class of finding from this kind of audit.

**High — vissues "first sub-issue" ambiguity**: migration-consolidation rule assumed "first sub-issue created" == "sub-issue containing phase 1", but sub-issues group by area-of-work, not phase order. Reworded to "the sub-issue containing phase 1's content" everywhere it appeared (Step 5, Hard rules, frontmatter description).

**High — vmigrate-rollback SQLite/native-DB gap**: Steps 4/5 hardcoded `docker exec` with no fallback, despite frontmatter/README claiming SQLite support (which has no container concept). Fix: added a native/no-container branch to Step 1.3, threaded "via docker exec (if Docker) or directly (if native/SQLite)" through Steps 4/5. Also narrowed "Generic across any project" → "any JS/TS project" (Step 1.1 detection is JS/TS-only; the broader claim wasn't backed by the detection logic).

**Medium — vmigrate-rollback safety-check placement**: the local-only host check existed only in Hard rules, not wired into Step 1.2 (the only step reading the connection string) — an agent could complete Step 1 without ever checking host. Wired it in explicitly. Also broadened the no-skip-confirmation rule to cover a user explicitly asking to skip it, not just pre-supplying the migration name.

**Medium — vreview incremental-mode threshold ambiguity**: the `<5 files`/`>20 files` grouping thresholds (predate incremental mode) didn't say whether they count the total diff or just `[NEW-SINCE-LAST-REVIEW]` files — a literal reading could re-review carried-forward files on a small incremental diff, defeating the feature. Clarified both thresholds apply to the new-since-last-review count in incremental mode. Also fixed a stale README path (`.code-review/staged-lint-rules/` — Phase 5 hasn't written there since an earlier commit, writes directly to `~/.claude/scripts/lint-rules/rules/` now) and reconciled a 3-way self-contradiction ("4-phase" in frontmatter vs "6 phases" in body vs 7 actual banner sections) into one consistent framing across `SKILL.md`, `SKILL.vi.md`, `README.md`, `README.vi.md`.

**Low-severity, mechanical fixes**: vfix Step 4 (cross-group) was missing the STOP-GATE/SDK-generate checks the surrounding text claimed applied to it; a dead `--harvest` flag (copy-pasted from vreview, never implemented) removed from vfix's argument-hint. vspecs had a hardcoded "plain Vietnamese" output-language rule in *both* language variants of the skill, contradicting the repo's dual-language install design (fixed to resolve dynamically, matching vcook's pattern) — plus a missing Case ID column in the Decisions table that `vplan` needs, and a wording bug ("at the end" vs. the template's actual section order). vcheck: frontmatter description omitted the always-runs Format step, `--test` had no defined trigger syntax, added a tsconfig.json edge-case note.

## Fix Method

Fixes delegated to 6 parallel `general-purpose` subagents (one per remaining skill; vcook fixed directly since the decoupling required design judgment, not mechanical instruction-following). Each agent got the exact finding + proposed fix from the audit — no re-discovery needed. Post-fix, ran a repo-wide grep sweep for stale terms (`6-phase`, `staged-lint-rules`, `harvest` in vfix, `Generic across any project`) — caught that the `README.vi.md` mirror of two README.md fixes (phase-count wording, lint-rules path) had been missed by the vreview-fix agent, since it was only told to touch `README.md`. Fixed directly. Version bumped 1.0.0→1.1.0 for the 5 skills with behavioral fixes, 1.1.0→1.2.0 for vreview (already-bumped for the unversioned incremental-mode feature from `ae77bff`), matching the repo's existing convention (vdesign bumped 4.0.0→5.x.0 across its own recent design churn).

## Lessons Learned

**1. "Fix the finding" sometimes means "delete the broken integration," not "make it correct."** vcook's fix wasn't reconciling `cook` and vcook's 9 steps into a working sequence — it was recognizing the 9 steps never needed `cook` at all. The user's instruction ("vcook không cần base trên cook đâu") was the correct call; the audit had only flagged *that the integration was broken*, not prescribed the fix shape. Worth defaulting to "does this dependency add anything the self-contained version lacks?" before trying to fix an integration's sequencing.

**2. A grep sweep after fan-out fixes catches the seams between agents, not just leftover bugs.** The `README.vi.md` gap wasn't a wrong fix — it was a fix correctly scoped to what one agent was told to touch, with no agent responsible for the VI mirror of a file two other agents also touched pieces of. Post-fix verification needs to check the union of "what should be true" across all touched files, not just what each individual agent's diff claims.

**3. Distinguish "no detection mechanism exists" findings from "wording is ambiguous" findings when prioritizing.** vissues' idempotency bug (no query ever checks link state) is categorically worse than vreview's phase-count self-contradiction (wording says three different numbers but the workflow itself is not actually broken) — both got flagged in the same audit pass, but only one produces silently-wrong runtime behavior (duplicate/missing GraphQL calls) vs. a reader being confused by inconsistent prose.

## Next Steps

None required — all 20 findings resolved, cross-file consistency verified, committed (`5567c62`, not pushed). Natural follow-up only if/when any of these skills gets its next real-world test run and surfaces something the audit missed (same pattern as the vdesign domain-research fix earlier today).

---

**Related**: `docs/journals/20260819-vdesign-bold-domain-research-4-aspects.md` (same-session prior fix), commit `5567c62`.
