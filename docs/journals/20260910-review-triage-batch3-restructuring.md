# vskills Review Triage Batch 3 — Restructuring: Red-Team Pre-Catch, Implementer Mid-Catch

**Date**: 2026-09-10 11:15
**Severity**: Low
**Component**: skill file structure, references/ convention, GitHub API integration, script performance
**Status**: Resolved with one instructive gap

## What Happened

Completed all 5 phases of batch 3 (skill file restructuring) with no live incidents during implementation, but the path exposed two distinct catch moments: (1) a pre-implementation red-team review that found 19 evidence-backed issues including 2 plan-blocking ones, caught and fixed in the plan before any code was written, and (2) a portability bug that the red-team *did not* catch but an implementer found during actual Phase 5 code writing. All 5 phases committed separately and verified.

**Phases delivered:**
- Phase 1: Removed dead `category`/`keywords`/`extends` frontmatter fields from 9 skills
- Phase 2: Split `skills/vreview/SKILL.md` into smaller body + new `references/` directory (new repo convention), rewrote description, fixed `install.sh` to symlink `references/` generically, added anti-confirmation-bias clauses to subagent prompts
- Phase 3: Migrated GitHub sub-issue linking from GraphQL-only to REST-primary with proper idempotency checks and correct 100-per-parent limit
- Phase 4: Made `vdesign`'s dependency on `frontend-design` pattern catalog conditional with an inline fallback (original, not copied), added WCAG AA relative-luminance contrast-ratio calculation
- Phase 5: Fixed `scripts/lint-rules/run.sh` to read registry once instead of 70 times, added `command -v node` guard, measured 44% speedup (6.2s → 3.45s)

## The Brutal Truth

Red-team review pre-implementation caught 19 real issues with evidence. Two of them were plan-blockers: Phase 1 and Phase 2 both targeted `skills/vreview/SKILL.md` (file ownership collision), and Phase 5's design used `declare -A` (bash 4+, crashes on macOS's stock bash 3.2). Both were fixed in the plan, preventing worse delays.

But the red-team missed one. Phase 5's design called for using `grep -P` (Perl regex) for the scope-map lookup. This worked during red-team's own verification run — because the reviewer's machine happened to have `grep` aliased to `ugrep`, which supports `-P`. It doesn't exist in stock BSD/macOS grep, and it wouldn't exist on many Linux boxes either. The implementer caught this during actual code writing and switched to `awk`, which is universally POSIX-compatible.

This is the fair lesson: red-team reviews are excellent at catching architecture-level issues and pre-implementation assumptions, but they don't catch *implementation-stage* portability bugs that only surface when code is actually written against the real toolchain where it will run.

## Technical Details

### Red-Team Findings (Pre-Implementation)

**Session:** 2026-09-10, 3 adversarial reviewers (Security Adversary, Failure Mode Analyst, Assumption Destroyer)
**Count:** 19 findings (all accepted, 0 rejected) — 5 Critical, 7 High, 7 Medium

**Plan-blocking findings (Critical):**
- Finding #1: `install.sh` symlinks only `SKILL.md` per skill (by design), so a new `references/` directory would never reach the installed skill location → Phase 2 fixed by making `install.sh` symlink any skill's `references/` directory generically
- Finding #2: Plan claimed "no phase shares a file" but Phase 1 and Phase 2 both listed `skills/vreview/SKILL.md` → Phase 1 dropped vreview, Phase 2 absorbed it
- Finding #3: Phase 5's original design used `declare -A` (bash 4+ associative arrays), which crashes on bash 3.2 (macOS stock, confirmed on this exact machine) → Phase 5 redesigned to use temp file + grep/awk lookup

**Other Critical findings also caught:**
- Finding #4: Phase 3's REST/GraphQL fallback treated an already-linked sub-issue as a failure on every re-run, defeating idempotency → Phase 3 added pre-check
- Finding #5: Phase 2's lint-harvest subagent prompt moved to a reference file writes executable `.sh` files to a global path without documenting the security surface → Phase 2 added trust-boundary comment

**Other findings (High/Medium):** GitHub API limit was 100, not 50 (review's original number); `--bold` flag was stale (actual flag is `--wow`); Phase 5's byte-comparison couldn't work due to timestamp-stamping by `merge-reports.js`; vplan's "extends" prose contained real operational instructions, not just a claim (would have deleted real content); REST call missing `replaceParent` flag on primary path; Phase 3 missed one more GraphQL-specific prose mention; 7 lint rules have hardcoded filename gates not declared in registry; line-count criteria used wrong metric (`wc -l` vs. actual body-length enforced by `check-skills.js`).

### Implementation-Stage Finding (Not Caught by Red-Team)

**Phase 5 during code writing:**
The design called for `grep -P "^${rule_id}\t"` to look up rules in the registry map. This worked during red-team's verification because they have `ugrep` aliased as `grep`. **Stock BSD/macOS grep does not support `-P` (Perl regex mode).** The implementer discovered this during actual code writing and switched the lookup to `awk '$1 == rule_id { print $2 }'`, which is POSIX-portable and works everywhere.

**Lesson:** Red-team reviews run under the reviewer's own toolchain (which may have non-standard tools installed or aliased). Implementation runs on the actual target machines where the code will be used (or developed). Portability bugs that depend on toolchain state surface during implementation, not red-team review.

### Scope Map Refactoring Impact

Before: `filter_files_by_scope()` called `node -e "require('./rule-registry.json')[rule_id]?.scope"` inside the per-rule loop (70 invocations per run, each spawning a node subprocess).

After: One `node -e` call before the loop builds a `rule_id<TAB>scope` file; `filter_files_by_scope()` looks up via `awk -v rule="$rule_id" '$1 == rule { print $2 }'` against that file.

**Measured performance:** 6.2s → 3.45s on test fixture set (44% improvement).

### Unrelated Repo Hygiene

Mid-session, user requested cleanup of git-tracked `plans/` files. Discovered that 6 files under a batch-1 plan directory had been committed to git despite `plans/` already being in `.gitignore` (a prior subagent had staged them by explicit path, bypassing gitignore). User confirmed destructive cleanup; ran `git filter-repo` to purge `plans/` from entire git history and force-pushed to origin.

Also found stray `SCRIPT_SCAN.json` test artifact at repo root (never previously gitignored); added to `.gitignore`.

## What We Tried

1. **Red-team review (pre-implementation):** 3 adversarial personas reviewed the 5-phase plan before any code was written; found 19 evidence-backed issues, all fixed in the plan before implementation began. This prevented the two plan-blocking issues (file collision, bash version crash) from being discovered during implementation.

2. **Phase dependencies:** Phase 4 explicitly depended on Phase 2's `install.sh` fix; staged implementation to respect dependency order.

3. **Scope-map refactoring with verification:** Phase 5 included a before/after test on a fixture set, with timestamp field excluded from comparison (since `merge-reports.js` stamps a fresh timestamp on every run). This prevented a silent behavior regression during the refactor.

## Root Cause Analysis

**Red-team caught 19 issues, missed 1.**

The 19 findings are structural/architectural: file ownership collision, bash version incompatibility, missing preconditions, API limit misstatement, stale flag names, logic gaps in idempotency. These surface from reading the plan and static analysis of existing code.

The 1 finding (`grep -P` unavailability) is a **toolchain compatibility issue** — it depends on the actual environment where code is *run*, not where code is *reviewed*. The red-team verified the logic during their own review on their own machine (which has `ugrep` aliased), so they didn't see the incompatibility. The implementer discovered it when actually writing and testing the script in a fresh shell context.

This is not a red-team failure. This is the normal boundary between review and implementation: reviews catch design and logic gaps; implementation catches environment-specific issues.

## Lessons Learned

1. **Red-team reviews pay for themselves on architecture, but not on environment-specific portability.** The 19 pre-catch findings prevented rework and delays. The `grep -P` miss was caught during implementation, which is also acceptable — it's where portability bugs belong to surface. No alarm needed; this is the expected division of labor.

2. **Toolchain assumptions embed silently.** The red-team's verification ran with their machine's tools (including non-standard aliases or paths). The actual code runs on developers' actual machines (macOS with stock bash 3.2, BSD grep) and CI (whatever image is defined). Portable code cannot assume non-POSIX tools. The fix (`awk` instead of `grep -P`) is the right defensive move.

3. **File ownership collisions in parallel multi-phase plans are easy to miss at the plan stage.** Finding #2 was a contradiction in the plan's own claim ("no phase shares a file") vs. the phase list (both Phase 1 and Phase 2 listing the same file). This wasn't a logic error; it was just bad coordination. Resolved by re-reading the file list against the claim. For future multi-phase plans, a automated pre-check (grep for duplicate file paths across phases) would catch this in seconds.

4. **Bash version constraints need to be stated and verified explicitly.** Phase 5's original plan called for `declare -A` with no mention of bash version. The red-team found it by grepping `declare -A` and checking the bash man page. The implementer would have found it even harder during testing. Better pattern: state "bash 3.2+" explicitly in the requirements, then verify with `bash --version` or `$BASH_VERSION` on the target machine at the start of implementation.

5. **Scope map refactoring from per-item to once-total requires a definitive before/after test.** Phase 5's success criteria included "before/after `SCRIPT_SCAN.json` identical once timestamp is excluded." This passed, which gives high confidence that scope-matching behavior didn't regress. Without this, the 70-to-1 subprocess reduction could have been optimizing away a subtle edge case.

## Next Steps

1. **Immediate:** All 5 phases complete, all commits verified, no blocking issues. Ready for external review if needed.

2. **Pattern for future multi-phase plans:** Add a pre-implementation sanity check that greps file paths across all phases and reports duplicates. This would catch Finding #2 instantly.

3. **Toolchain portability audits:** For any script changes touching shell builtins, control flow, or CLI tools, verify against the intended target environment (bash version, standard POSIX tools). Don't assume that what works on the reviewer's machine works everywhere.

4. **Batch 2's lint-rule regex bug (Finding F2c in batch 2's notes):** Still outstanding. `shared-constant-maybe-redefined-candidate.sh` doesn't match idiomatic `const NAME = value` syntax. Log for separate review and fix.

---

**Verification:** All 5 phase files show green checkmarks on success criteria. Phase 2's vreview restructuring passed the existing vreview behavior eval from batch 2's eval suite (no regressions). Phase 5's before/after timing shows 44% improvement, and before/after scope-matching output is identical once timestamp is excluded. No unresolved issues remain.
