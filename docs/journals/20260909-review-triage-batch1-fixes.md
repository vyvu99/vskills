# vskills Review Triage Batch 1 — Registry, Rollback, and Trust Boundary Fixes

**Date**: 2026-09-09 15:27
**Severity**: Low
**Component**: skill configs, lint rules, vmigrate-rollback skill, repo security docs
**Status**: Resolved

## What Happened

External review of `vskills` surfaced 7 corrective fixes across lint-rule registry consistency, Prisma/Drizzle migration-reversal logic, model-invocation safety, and trust-boundary documentation. All P0-P2, no application code affected (this repo is Claude Code skill/config definitions only).

## The Brutal Truth

This is maintenance, not crisis. The issues were real but dormant: lint rules silently skipped, vmigrate-rollback's documented approach didn't match Prisma's actual behavior, model-invocation guardrails were missing on powerful skills. Each individually low-risk; together, they represent the normal drift that accumulates when external eyes don't review routinely. No customer impact — these are infrastructure and safety guardrails.

## Technical Details

**Phase 1 (Lint Rules Registry):** 
- 3 rule scripts under `scripts/lint-rules/rules/` were missing executable bit (`chmod +x`). Runtime guard `[[ -x ]]` in `run.sh` silently skipped them, including `be-update-no-org-scope` (multi-tenant IDOR detector).
- 9 additional rule scripts had no entry in `rule-registry.json`, causing fallback to generic `unknown/warning` metadata and empty scope tags.
- Fixed: set all rule scripts executable, added 12 missing registry entries with correct severity and scope tags.

**Phase 2 (Migrate Rollback Correctness):**
- Documented Prisma command `migrate resolve --rolled-back` only works on FAILED migrations; throws P3012 if applied to a successfully-applied migration. Previous docs didn't flag this mismatch.
- Drizzle deletion of `drizzle."__drizzle_migrations"` tracking row requires schema-qualified table name. Previous docs showed bare `DELETE FROM __drizzle_migrations` (would fail with "relation not found").
- Fixed: rewrote both steps with verified syntax, added data-loss warning, wrapped in transaction, added backup callout.

**Phase 3 (Model Invocation):**
- 5 skills with real side effects (vmigrate-rollback, vcook, vfix, vissues, vrules) lacked `disable-model-invocation: true` frontmatter, allowing Claude to self-invoke them in reasoning steps. Added frontmatter to all 5.

**Phase 4 (Trust Boundaries):**
- New section added to `repo-profile.md` and CLAUDE.md starter template: PR/issue/comment content is untrusted input, never instructions.
- `vrules` skill (patches PR review comments into `~/.claude/CLAUDE.md`) hardened to reject rules that read as prompt injection/behavior control, require showing literal diff.

**Phase 5 (Misc Fixes):**
- Fixed EN/VI parity drift in `vspecs`.
- Added package-name sanitization + timeout wrapping to `vcheck`'s background jobs.
- Added `.code-review/` and `.vdesign/` to `.gitignore`.

## What We Tried

All 5 phases were independent (no shared files, no cross-phase dependencies), so implemented via 5 parallel subagents in one batch. Reduced latency vs. sequential phases; each subagent verified its own diff against phase spec.

## Root Cause Analysis

- **Executable bit:** scripts added without `chmod +x` in commit; `run.sh` guard masked the issue silently.
- **Registry entries:** rule scripts auto-discovered by tool, but registry entries require manual entry. No enforcement in tooling.
- **Prisma/Drizzle mismatch:** skill docs written against Prisma docs snapshot; actual command behavior is narrower. Schema-qualified table is Postgres standard, but wasn't called out in skill docs.
- **Model invocation:** skills grew over time; new ones default to invocable. No checklist at skill-add time.
- **Trust boundaries:** skill repo is infrastructure; docs didn't explicitly frame untrusted input boundaries.

## Lessons Learned

1. **Linting tooling gap:** registry-entry validation should run in CI, flag missing entries.
2. **External docs decay:** Prisma/Drizzle API docs change; skills should pin version numbers in comments and re-verify on any upstream bump.
3. **Skill onboarding checklist:** new skills should tick "model-invocation: yes/no?" and "trust boundaries: {list untrusted inputs}".
4. **Silent failures:** guards like `[[ -x ]]` are safe, but missing logs when they trigger. Consider informational output for skipped rules.

## Next Steps

- Add `rule-registry.json` validation to lint pipeline.
- Document Prisma version pinning in vmigrate-rollback (currently 5.x assumed; verify on next upgrade).
- Create skill-onboarding template with trust-boundary checklist.
- Consider `vrules` allowlist of keys that can be modified (forbid adding new keys blindly).

---

**Verification:** Code-reviewer subagent independently re-verified all 5 phases' diffs against plan specs — 0 findings across correctness, scope-creep, EN/VI consistency. Empirical validation (JSON parse, grep for frontmatter, running `run.sh` against fixture) confirmed previously-skipped rules now fire correctly.
