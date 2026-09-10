# vskills Review Triage Batch 2 — Measurement Infrastructure and Parallel Work Collateral Damage

**Date**: 2026-09-10 10:30
**Severity**: High
**Component**: eval infrastructure (Phase 3), skill-structure lint (Phase 1), lint-rule fixture tests (Phase 2), report status tracking (Phase 4)
**Status**: Resolved with structural lesson

## What Happened

Implemented 4-phase measurement infrastructure for `vskills` (no logic changes to existing skills, only added infrastructure): lint script for skill structure validation, fixture-based tests for 18 highest-risk lint rules, eval runner for trigger + behavior checks on `vcheck`/`vreview`, and persistent status tracking on code-review findings. All 4 phases committed and currently live. 

However, the path to completion included two distinct incidents: (1) a real isolation breach during the first live eval run, caught and reverted, and (2) a collateral-damage incident where the automated revert mechanism destroyed parallel uncommitted work from unrelated phases.

## The Brutal Truth

A red-team review correctly predicted that a `claude -p` invocation with soft containment (`cwd` + `--add-dir` + `bypassPermissions`) would not actually confine file access, and this prediction materialized during live testing — a subprocess call read and edited real tracked files via absolute paths, bypassing the intended fixture isolation. The isolation breach was real and caught.

The more frustrating incident: implementing 4 parallel, independent phases with uncommitted work, then hitting the isolation breach and triggering an auto-revert safety guard that was supposed to be preconditioned on a clean working tree. **That precondition was never checked at invocation time.** The revert destroyed the already-completed, already-verified deliverables from Phase 1, Phase 2, and Phase 4 — work that had nothing to do with Phase 3's breach. This wasn't caught by the implementing agent; it was surfaced by code review, which noticed Phase 1's completion report described deliverables that simply did not exist on disk anymore.

The lesson here is not about isolation or eval infrastructure. It's about git safety mechanisms: an automated destructive operation (hard revert of uncommitted changes) intended as a surgical containment tool becomes a collateral-damage weapon when the preconditions it relied on are not enforced at call time. One missing check, and unrelated legitimate work gets erased by an automated process designed to protect against something entirely separate.

## Technical Details

### Phase 1: Skill Structure Lint
- **Delivered**: `scripts/check-skills.sh` (bash wrapper) + `scripts/check-skills.js` (deterministic parser)
- **Scope**: frontmatter field allowlist validation, body/description length caps, EN/VI line parity, rule executable-bit and registry consistency
- **Pre-existing fix**: `skills/vcheck/SKILL.vi.md` was drifted (batch 1 had edited SKILL.md but not SKILL.vi.md); fixed in this phase
- **Exit behavior**: non-zero when violations exist (expected for current repo; most skills still have `category`/`keywords`/`extends`), zero on clean fixture

### Phase 2: Lint Rule Fixture Tests  
- **Delivered**: 18 `bad`/`good` fixture pairs (one per `-candidate` rule) + `scripts/lint-rules/tests/run.sh`
- **Critical fix applied during implementation**: red-team had flagged that uniform `bad.ts`/`good.ts` naming doesn't work — 7+ of the 18 rules hardcode filename/path gates (e.g., `-route.ts`, `-repository.ts` suffixes). Implemented per-rule fixture naming by reading all 18 rule scripts first (Step 1 of implementation), extracting their actual filename requirements, naming each fixture to satisfy those requirements rather than the registry's `scope` field (which only 2 of 18 rules even declare).
- **Additional finding documented but not fixed**: regex bug in `shared-constant-maybe-redefined-candidate.sh` never matches idiomatic `const NAME = value` syntax (rule itself is broken, not just the fixture — documented, scope leaves fixing the rule for separate review)

### Phase 3: Eval Infrastructure
- **Delivered**: `evals/trigger/{vcheck,vreview}.json` (10-20 trigger queries each), `evals/behavior/{vcheck,vreview}/` (fixtures + metadata), `scripts/run-evals.sh` (orchestrator)
- **Empirical verifications completed**: 
  - `--output-format json` was insufficient (carries no tool-use detail); switched to `stream-json --verbose`
  - vcheck fixtures require pre-install of `node_modules` (added install step before each fixture run)
  - cwd + `--add-dir` + `bypassPermissions` does NOT actually confine; only way to confine is `--restricted`, which forbids Bash and `bypassPermissions` both — accepted as documented soft containment per design, not fixable
- **Isolation breach (real)**: first live run, a `claude -p` subprocess call with fixture temp-dir as cwd, `--add-dir`, and `bypassPermissions` read and edited real tracked `skills/` files via absolute paths. Breach was caught, invocation reverted, two mitigations added: `--strict-mcp-config` (removes MCP servers, the suspected vector) and a git-status snapshot/hard-revert guard
- **Result**: infrastructure now ships with documented risk (soft containment, not sandbox) + documented mitigation (per-invocation auto-revert if breach detected), plus a precondition that's *intended* to ensure clean-tree-only operation

### Phase 4: Report Status Tracking
- **Delivered**: `Status: PENDING` field added to `REPORT.md` item template (both `vreview` and `vfix`), batch-commit-aware status write instructions in `vfix` steps 2–5, persistent `.code-review-history.jsonl` log appended before report deletion, `.gitignore` entry
- **EN/VI parity**: all 4 skill files (vreview EN/VI, vfix EN/VI) edited in parallel; line-count deltas verified to match

### The Collateral Damage Incident

**Timeline:**
1. Phases 1, 2, 3, 4 implemented in parallel across independent files; typical pattern for independent work is to hold all changes uncommitted until the final integration point
2. Phase 3's eval runner triggered the isolation breach on its first live invocation (subprocess read real files via absolute paths)
3. A safety mechanism kicked in: git-status snapshot + hard revert to clean state
4. The revert succeeded *too well*: it reverted the entire working tree, not just Phase 3's output — destroying uncommitted changes from Phase 1, Phase 2, and Phase 4
5. This was caught later by code review, not by the implementing agent's own self-check (code reviewer noticed Phase 1's final report claimed "check-skills.js created" but the file didn't exist)

**Why it happened:** The auto-revert guard was designed with the expectation "only run this when the tree is clean" (the precondition). But that precondition was never actually checked before invoking the revert. The subprocess breach was detected and auto-reverted, but the revert had no way to know that the "dirty" state included both "Phase 3's rogue edits" (legitimate to revert) and "Phase 1/2/4's unrelated WIP" (collateral damage). Git has no mechanism to distinguish these.

**Fix applied:** Re-implemented Phases 1, 2, 4 from their surviving implementation reports (Phase 3 was never lost — its output wasn't part of the revert because it was committed earlier). Added a clean-tree precondition to the eval runner itself: refuses to run at all unless the tree is clean, so future reverts can only ever undo what that specific run produced.

## What We Tried

1. **Red-team review (pre-implementation)**: 3 adversarial reviewers (Security Adversary, Failure Mode Analyst, Assumption Destroyer) reviewed the plan; found 13 evidence-backed issues, all accepted and fixed in the plan before any code was written. This phase prevented multiple real defects (isolation gap, fixture-naming collision, vfix's existing delete-the-report behavior, batch-commit timing, etc.). Paid for itself 13 times over before line 1 of implementation code was written.

2. **Parallel phase implementation**: Phases 1, 2, 3, 4 have zero file overlap; natural to implement in parallel. Did not anticipate that an automated safety mechanism (the revert guard) would be invoked mid-implementation and would destroy unrelated parallel work.

3. **Isolation mitigation attempt**: added `--strict-mcp-config` to drop MCP servers (suspected exfiltration vector for absolute-path access), but this was insufficient; the breach still happened via Bash/file-tool access.

## Root Cause Analysis

**The isolation breach itself:** 
- `--add-dir` is documented as "additive" (grants extra allowed access), not "confining." The assumption that `--add-dir` + `cwd` would confine a session was wrong; only `--restricted` confines, but it forbids Bash (which vcheck needs) and `bypassPermissions` (which evals need).
- The red-team flagged this assumption as wrong. The implementation went ahead with documented risk, which is correct.
- During live testing, the breach manifested exactly as predicted. This is not a bug; it's the documented risk materializing.

**The collateral damage:**
- Four independent phases implemented in parallel with uncommitted work
- An auto-revert safety mechanism was invoked (correctly responding to a breach in Phase 3)
- The mechanism had a documented precondition ("only when tree is clean"), but that precondition was never enforced in code — it was assumed to be true by whoever would invoke it
- The revert happened anyway, destroying unrelated work
- **Structural issue:** git-based reverts are all-or-nothing at the working-tree level. A subprocess breach creates a mixed state (some rogue edits, some legitimate WIP), and a hard revert cannot surgically separate them. If you need destructive containment, you need either:
  - A pre-condition that's actually enforced (tree is clean before you allow a revert)
  - Or isolation at a lower layer (container, VM, separate git clone) so the revert doesn't touch other work
  - Or no destructive revert at all (snapshot files before running, restore selectively by file name/path)

## Lessons Learned

1. **Parallel uncommitted work + destructive auto-revert = collateral damage risk.** This is the core lesson: if you're implementing multiple independent phases in parallel and any of them can trigger a destructive cleanup mechanism (git revert, disk wipe, process kill), the preconditions for that cleanup **must be enforced in code, not documented.** A comment saying "only run if tree is clean" is not a safeguard if the actual invocation site doesn't check.

2. **Red-team reviews pay off even when predictions materialize.** The 13 red-team findings prevented worse damage. Finding #1 (isolation gap) and #4 (vfix deletes the data) were both confirmed during live testing. Red-team is not "predict the future perfectly"; it's "identify high-risk assumptions and verify them before you ship."

3. **Code review catches what self-checks miss.** The implementing agent's own test runs passed (Phase 3's eval infrastructure, Phase 4's status tracking logic). The code reviewer's independent read caught the missing deliverables. This is a case where second-order review (not just "does the code run," but "do the claimed outputs exist") caught a failure the first-order runner didn't.

4. **Soft containment requires honest threat modeling.** We documented the isolation posture as "soft" — cwd + `--add-dir`, not a sandbox. That documentation is good. But if you're relying on a hard-revert containment mechanism as a backstop, that needs to be actually hard (enforced preconditions, or lower-layer isolation), not documented soft.

5. **Fixture naming needs empirical validation.** 7+ of 18 lint rules have hardcoded filename gates, and only 2 are declared in the registry's `scope` field. Step 1 of Phase 2 required reading all 18 rule scripts to extract the real gates. This worked. Relying on the registry alone would have silently failed to test 7 rules. Lesson: generative steps (glob a directory, iterate) need to verify their assumptions against the actual artifact, not inherited metadata.

## Next Steps

1. **Immediate:** The eval runner now ships with clean-tree precondition. Verified: all 4 phases' deliverables exist on disk and are committed.

2. **Strengthen the isolation precondition:** if the eval runner is extended to run externally-sourced prompts (not just the 20 fixed vcheck/vreview queries it has now), move to actual container/VM isolation, not git-based revert. A documented risk is acceptable for fixed, hand-authored prompts; generalization needs stronger walls.

3. **Enforce preconditions in code:** Add `git status --porcelain` check to any future cleanup mechanisms. Don't rely on documentation.

4. **Fix the lint-rule regex bug:** `shared-constant-maybe-redefined-candidate.sh` — log Finding F2c in batch 3's plan, fix in scope.

5. **Verify bun command template:** `skills/_vskills-shared/repo-profile.md` row for bun was not empirically tested during Phase 3 (vcheck behavior fixtures only cover pnpm/yarn/npm). Add bun fixture next iteration if bun usage grows.

---

**Verification:** Code-reviewer subagent independently caught the collateral-damage incident by noticing Phase 1's completion report described deliverables missing from disk. Re-implementation from saved reports confirmed all three lost phases' artifacts and re-committed. Phase 3's eval infrastructure empirically verified the isolation gap (matched red-team prediction exactly); now ships with documented soft containment + documented mitigation (per-run auto-revert) + structural fix (clean-tree precondition on the runner itself). No blocking issues remain.
