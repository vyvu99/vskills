# Fix mode (`vreview --fix`)

Read this only when the user typed `--fix`. A plain review never reads this file and never edits code.

You are now a senior engineer fixing the issues in an existing report. For each issue or batch, use the `fix` skill (Skill tool) for root-cause diagnosis, verification, and prevention. If the `fix` skill is not installed, diagnose and fix directly with the same rigor. This file, not `fix`, decides the order, the batching, and when to stop and ask the user.

## Input

Read from the report directory in use: `.code-review/` by default, or the directory the user passed as the positional argument (an existing directory containing `REPORT.md`). Everywhere below, `.code-review/` means that directory.
- `SCRIPT_SCAN.json`: violations already confirmed by lint rules.
- `REPORT.md`: CRITICAL, WARNING, SUGGESTION, CROSS-GROUP ISSUES.
- `ADVERSARIAL.txt`: already merged into `REPORT.md`; treat its CRITICAL/WARNING items as equivalent.

A missing file means skip that step. No report at all: ask the user for a specific issue to fix, or use `fix` directly from a verbal bug description.

## Scope and verification (applies to every step)

- Fix the reported root cause and nothing else: no refactors, extra tests, or docs "while you're there", so each commit stays reviewable against the report.
- Verify each batch before committing: run the project's tests and typecheck for the packages the batch touched (package.json scripts, or `vci` for typecheck and build). Never commit a batch that fails verification; fix it or undo your own uncommitted edits for that batch and mark the items `DEFERRED (<reason>)`.
- If no test or typecheck can run for the touched code, say so in the item's `Status:` line and in the final summary instead of reporting it as verified.

## Processing order

Run the steps in this order and finish (and commit) one before starting the next, because later steps are riskier or need a human. Within a step, independent files may be fixed in parallel by subagents; brief each with the exact items, file:line, the batch's verification command, and the rule that it must not touch other files. An empty step is reported as "skip — no issues".

### Step 1 — SCRIPT_SCAN.json
Confirmed by lint rules and grep-detectable, so the lowest risk of misreading business logic.
1. Empty or `{"error":...}`: skip.
2. Group violations by `rule_id`. For each, read `~/.claude/scripts/lint-rules/rules/{rule_id}.sh` (`## PROBLEM` and `## FIX`). If the script is missing, infer intent from the `message` in `~/.claude/scripts/lint-rules/config/rule-registry.json`; if that is absent too, skip the rule_id and note it.
3. Check the stop-gate for the touched files, then apply the rule's `## FIX` as written. If applying it breaks a test or typecheck, stop and report "rule `<rule_id>`'s FIX guidance appears wrong for this case" and suggest `vreview --harvest`; do not invent a different fix.
4. After each rule_id, re-run that rule on the fixed files to confirm none remain.
5. Commit once: `fix: resolve {N} script-detected lint violations`.

### Step 2 — CRITICAL issues
1. Read the CRITICAL section (and CRITICAL in `ADVERSARIAL.txt`, without duplicating).
2. Batch by dependency: issues sharing a flow, file, or type go together, since fixing one alone would leave the code half-fixed.
3. For each batch: check the stop-gate, then use `fix` with file:line and the documented problem as the baseline (shorten scouting; keep fix and verify in full).
4. If the batch changes a shared schema or API route, run SDK generation (below) before the commit so generated output lands in the same commit.
5. Verify, then commit once per batch: `fix: {short batch description}`.
6. Immediately after each batch's own commit, update every item's `Status:` in `.code-review/REPORT.md` to `FIXED (commit <sha>)` (that batch's real sha), `REJECTED (<one-line reason>)`, or `DEFERRED (<one-line reason>)`.

### Step 3 — WARNING issues
Same process as Step 2.

### Step 4 — CROSS-GROUP ISSUES
Each cross-group issue is its own batch. Check the stop-gate, fix, verify files on both sides, run SDK generation if either side touches a shared schema or API route, commit separately (`fix: {description}`), then write `Status:` as in Step 2.

### Step 5 — SUGGESTION issues
Suggestions are optional improvements, so each needs the user's decision; never apply them in bulk.
1. Ask once with `AskUserQuestion` which review mode to use (wording per `~/.claude/skills/_vskills-shared/webapp-templates.md` §(c)): webapp, or one at a time.
   - One at a time: for each suggestion, present the issue and proposed fix with `AskUserQuestion` and ask apply or skip.
   - Webapp: build one `diff-review-list` field with every suggestion per webapp-templates §(a): `id` = `SUGGESTION-{n}`, `before` = the `Issue:` text plus the current code read fresh from `File:line`, `after` = the `Fix:`, `actions: ["apply","skip"]`, `allowFreeText: true`. Health-check and start the webapp per §(b), `POST /api/step` (Bash `run_in_background: true`), then walk the returned decisions in order.
2. Apply: check the stop-gate, fix, verify, write `Status: FIXED (pending commit)`. Skip: write `Status: REJECTED (<one-line reason>)` and never ask again.
3. Webapp item with `freeText` (whatever the action): treat it as an extra instruction and call `fix` with it instead of applying `Fix:` verbatim; stop-gate and verify as usual.
4. HTTP `400` (invalid template): fix the JSON per `details` and retry. Timeout or connection error: tell the user briefly and fall back to one at a time for the rest.
5. If at least one was applied: run SDK generation if needed, commit together `fix: apply {N} accepted suggestions`, then replace every `FIXED (pending commit)` with the real sha.

## Stop-gate

Before fixing any item (lint violation, CRITICAL, WARNING, cross-group, or an accepted SUGGESTION), check these four conditions. If any matches, stop and ask with `AskUserQuestion`; the user's "apply" on a suggestion consents to the change, not to a migration, shared-package edit, or data write. These are the irreversible or cross-team changes where a wrong guess is expensive.

- a. The report says "verify with product" or "needs business-logic confirmation", or the fix depends on an unclear business decision.
- b. The fix needs a database migration (add, change, or remove a column, constraint, or enum value).
- c. The fix touches a shared package (imported by 2 or more apps under `apps/`).
- d. The fix runs `UPDATE` or `DELETE` on existing data, which carries the same weight as a migration.

## SDK generation

After any batch that changes a shared schema or API route, before that batch's commit: find the script in `package.json` (root and the affected package) in the order `sdk:generate`, `api:generate`, `codegen`, and run it with the project's package manager (detected from the lockfile). None found: skip; do not create one.

## Wrap-up

1. Run the project's format command (`package.json` scripts, in the order `format`, `format:fix`, `lint:fix`); none found: skip.
2. Run `vci` (typecheck and build) on the packages touched in this run, since many batches easily leave a stray type error. Fix failures and show any such fix in the summary.
3. If format, generation, or `vci` fixes changed tracked files, commit them together as one commit: `chore: apply format and generated output after review fixes`. Otherwise no commit; say so in the summary. Never fold them into an issue commit or leave them uncommitted unmentioned.
4. Append one line per `REPORT.md` item to `.code-review-history.jsonl` at the repo root (create if absent): `{date, rule_or_source, file, status}` from the item's final `Status:`. Do not commit it unless the repo already tracks it. This record survives whether or not the report directory is deleted.
5. Ask for confirmation before deleting `.code-review/` (or the report directory used), since the user may not have finished reading it. Confirmed: delete. Otherwise leave it.
6. If a `rule_or_source` has several `REJECTED` entries across runs in `.code-review-history.jsonl`, mention it in the summary as a candidate for tightening or retiring (`vreview --harvest` or edit the rule).

Fix mode commits to the current branch and never pushes.

## Next steps

Look at what was fixed in this run and suggest one fitting next action in 1-2 sentences, per `_vskills-shared/repo-profile.md` §7. If nothing further is needed, say so.
