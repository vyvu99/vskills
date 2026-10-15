# Fix mode (`vreview --fix`)

Loaded ONLY when the user explicitly passed `--fix`. A plain review never reads this file and never edits code.

You are now a senior engineer fixing issues from an existing report. For EACH issue/batch, invoke the `fix` skill (via the Skill tool) for root-cause diagnosis + verify + prevention — but processing order, batch grouping, and whether to stop and ask the user are all decided here, NOT left for `fix` to choose.

═══════════════════════════════════════════════════════
INPUT
═══════════════════════════════════════════════════════

- Read from the report directory in use: `.code-review/` by default (the review that just finished in this run), or the directory the user passed as a positional argument (an existing directory containing `REPORT.md`):
  - `SCRIPT_SCAN.json` — violations already confirmed by lint rules
  - `REPORT.md` — CRITICAL / WARNING / SUGGESTION / CROSS-GROUP ISSUES
  - `ADVERSARIAL.txt` — adversarial-pass issues; already merged into REPORT.md, so treat CRITICAL/WARNING items here as equivalent to REPORT.md
- Missing file → skip that step, no error. Every `.code-review/` mentioned below means whichever directory is in use.
- No report exists (no `.code-review/`, no valid path) → ask the user: a specific issue to fix, or invoke `fix` directly from a verbal bug description.

═══════════════════════════════════════════════════════
PROCESSING ORDER (MANDATORY — do NOT skip steps, do NOT parallelize BETWEEN steps)
═══════════════════════════════════════════════════════

Within EACH step, sub-groups may be parallelized (e.g. multiple subagents fixing multiple independent files at once — each folds its root-cause rationale into the commit message body), but the next step only starts once the previous is fully done + committed (if a commit applies).

──────────────────────────────────────────────────────
STEP 1 — SCRIPT_SCAN.json
──────────────────────────────────────────────────────
Goes first: already confirmed by lint rules, grep-detectable, clearest, lowest risk of misreading business logic.

1. Read `SCRIPT_SCAN.json`. Empty/`{"error":...}` → skip this step.
2. Group violations by `rule_id`.
3. For EACH rule_id: read the rule script (`~/.claude/scripts/lint-rules/rules/{rule_id}.sh` — `## PROBLEM` + `## FIX` sections) to understand the rule's intent before fixing. Rule script missing → infer intent from the `message` field for that `rule_id` in `~/.claude/scripts/lint-rules/config/rule-registry.json`; also absent → skip the rule_id, note it in the report, don't fail the whole step.
4. BEFORE fixing a rule_id, check the STOP-GATE for the files it touches.
5. Fix EACH violation exactly as the rule script's `## FIX` section suggests — don't invent a different approach if it already spells one out. If applying `## FIX` exactly causes a test/typecheck failure, don't invent a different fix either — stop, report "rule `<rule_id>`'s FIX guidance appears wrong for this case," suggest running `vreview --harvest` to tighten that rule, rather than silently patching around it.
6. After fixing all violations for 1 rule_id → re-run that rule against the fixed files to confirm none remain, then move to the next rule_id.
7. STEP 1 done → commit once: `fix: resolve {N} script-detected lint violations`.

──────────────────────────────────────────────────────
STEP 2 — CRITICAL issues (REPORT.md)
──────────────────────────────────────────────────────
1. Read the entire CRITICAL section in `REPORT.md` (and CRITICAL in `ADVERSARIAL.txt` if present, without duplicating).
2. Group by dependency — issues sharing a flow/file/type go in the same batch (don't split A from B if fixing A alone would leave the code half-fixed).
3. For EACH batch: invoke the `fix` skill (Scout+Diagnose can be shortened — use file:line + the problem already documented in REPORT.md as the baseline instead of scouting from scratch; Fix+Verify still done in full).
4. BEFORE fixing, check the STOP-GATE (see below) for each issue in the batch.
5. After finishing a batch → verify (relevant test/build) → commit once for the whole batch: `fix: {short batch description}` — never commit interdependent issues individually.
6. Batch changes a shared schema or API route → run SDK/codegen (see "SDK GENERATE") BEFORE the commit so generated output lands in the batch's own commit.
7. As you decide each item's outcome, note it (fix / reject / defer) but don't write `Status:` yet. Immediately after **each batch's own** commit (not once for the whole step), pass over every item just handled and update its `Status:` line in `.code-review/REPORT.md` to `FIXED (commit <sha>)` (that batch's real sha) / `REJECTED (<one-line reason>)` / `DEFERRED (<one-line reason>)`.

──────────────────────────────────────────────────────
STEP 3 — WARNING issues (REPORT.md)
──────────────────────────────────────────────────────
Repeat STEP 2's exact process (group by dependency → batch → stop-gate → fix → verify → commit → sdk generate if needed → write `Status:` immediately after each batch's own commit) for the WARNING section.

──────────────────────────────────────────────────────
STEP 4 — CROSS-GROUP ISSUES (REPORT.md)
──────────────────────────────────────────────────────
0. Before fixing, check STOP-GATE.
1. Read the separate "CROSS-GROUP ISSUES" section — issues spanning ≥2 groups/files that don't fit a single CRITICAL/WARNING batch above.
2. Each cross-group issue is its own batch (it already spans multiple files/groups by definition).
3. Fix → verify ALL files on BOTH sides → commit separately: `fix: {cross-group issue description}`.
4. Either side touches a shared schema or API route → run SDK/codegen (see "SDK GENERATE") before the commit.
5. Same `Status:` write-back rule as Step 2 point 7 — note the outcome, then update `.code-review/REPORT.md` immediately after each batch's own commit.

──────────────────────────────────────────────────────
STEP 5 — SUGGESTION issues (REPORT.md)
──────────────────────────────────────────────────────
DIFFERENT from the 4 steps above: never apply arbitrarily.

1. Read the SUGGESTION section.
2. Ask 1 `AskUserQuestion` to pick the review mode (wording per `~/.claude/skills/_vskills-shared/webapp-templates.md` §(c)): **webapp** or **one at a time** (the existing flow).
   - **One at a time (existing flow)** — for EACH suggestion (one item at a time, no grouping): use `AskUserQuestion` to present the issue + proposed fix, ask whether to apply or skip.
   - **Webapp** — build 1 `diff-review-list` field with every SUGGESTION item at once per `~/.claude/skills/_vskills-shared/webapp-templates.md` §(a): `id` = `SUGGESTION-{n}` (`n` = the item's number in the SUGGESTIONS section), `before` = the `Issue:` text plus the actual current code read fresh from `File:line` (REPORT.md doesn't inline a "current code" block the way it does for `Fix:` — read the file), `after` = the `Fix:` text/code, `actions: ["apply","skip"]`, `allowFreeText: true`. Health-check + start the webapp per §(b) if not already running, `POST /api/step` (Bash `run_in_background: true`), then walk the returned decisions array in order.
3. User agrees (one-at-a-time: answers apply; webapp: `action: "apply"` with no `freeText`) → check the STOP-GATE for that item → fix immediately → verify → write `Status: FIXED (pending commit)` → next item.
4. User declines (one-at-a-time: answers skip; webapp: `action: "skip"`) → write `Status: REJECTED (<one-line reason>)` immediately (no commit dependency) → next item — never ask again.
5. Webapp mode only, item has `freeText` set (regardless of `action`) → treat the free text as an extra instruction and call the `fix` skill for that item with it, instead of applying the suggestion's own `Fix:` verbatim → check the STOP-GATE → verify → write `Status: FIXED (pending commit)` per the outcome.
6. `400` (invalid template — see webapp-templates.md §(b)) → fix the JSON per `details` and retry `/api/step`, still in webapp mode. Timeout/connection error while waiting on the webapp → tell the user briefly and fall back to one-at-a-time for the remaining items instead of retrying or aborting.
7. After all SUGGESTION items → ≥1 applied → run SDK/codegen if needed, then commit together: `fix: apply {N} accepted suggestions` → final pass replacing every `FIXED (pending commit)` with `FIXED (commit <sha>)` using the real sha.

═══════════════════════════════════════════════════════
STOP-GATE — STOP AND ASK THE USER (applies to EVERY fix in steps 1-5, do NOT decide on your own)
═══════════════════════════════════════════════════════

Before fixing any issue (lint violation, CRITICAL, WARNING, cross-group, or an accepted SUGGESTION), check these 4 conditions — ANY match → stop, use `AskUserQuestion`, do NOT fix on your own. A user's "apply" on a SUGGESTION does not waive the gate — it consents to the change, not to a migration, a shared-package edit, or a data write.

a. The report notes "verify with product" / "needs business-logic confirmation" / equivalent — fix depends on an unclear business decision.
b. The fix requires a database migration (adding/changing/removing a column, constraint, or enum value).
c. The fix affects a shared package (used by ≥2 apps in the monorepo — check whether `packages/` is imported by ≥2 `apps/`).
d. The fix requires `UPDATE`/`DELETE` on existing data (not just a schema change) — same stop-and-ask weight as a migration, equally risky.

None match → fix directly following the corresponding step's process.

═══════════════════════════════════════════════════════
SDK GENERATE (after EVERY batch that changes a shared schema / API route, before that batch's commit)
═══════════════════════════════════════════════════════

Auto-detect the script in `package.json` (root and/or affected package), priority order: `sdk:generate` → `api:generate` → `codegen`. Found → run it (preferably via the project's package manager, auto-detected via lockfile). None found → skip, don't create a new script.

═══════════════════════════════════════════════════════
WRAP-UP — FORMAT + CLEANUP
═══════════════════════════════════════════════════════

1. All steps done (including SUGGESTION items) → auto-detect and run the project's format command: `package.json` scripts, order `format` → `format:fix` → `lint:fix`. None found → skip.
2. Run `vci` (typecheck + build) on the package(s) touched this run — fixing many violations across multiple batches easily leaves a stray type error. Failures → fix before moving on (a fix for a vci failure is its own change: show it to the user in the summary).
3. Steps 1-2 changed any tracked file (formatter rewrites, regenerated output, vci fixes) → commit them together as ONE separate commit: `chore: apply format and generated output after review fixes`. Nothing changed → no commit; say so in the final summary. Never fold these into an earlier issue commit, and never leave them uncommitted without saying so.
4. Append one line per `.code-review/REPORT.md` item to `.code-review-history.jsonl` at the repo root (create if absent) — JSON per line: `{date, rule_or_source, file, status}`, from each item's final `Status:` value. Do this regardless of whether the user later confirms or declines deletion — it's the persistent record that survives either way. (Do not commit this file unless the repo already tracks it.)
5. Before deleting `.code-review/` (or the report path used): ask for confirmation — never assume the user has finished reading the report.
6. Confirmed → delete the report directory. Wants to keep it → leave as-is, done.
7. Rule-tuning hint: in `.code-review-history.jsonl`, a `rule_or_source` with several `REJECTED` entries across runs → note it in the final summary as a candidate for tightening/retiring (via `vreview --harvest` or editing the rule directly). Do NOT read `~/.claude/scripts/lint-rules/violation-history.jsonl` for this — it only stores per-scan violation counts (total, top rules), not reject/skip outcomes.

═══════════════════════════════════════════════════════
HARD RULES
═══════════════════════════════════════════════════════

- Do NOT skip the priority order SCRIPT_SCAN → CRITICAL → WARNING → CROSS-GROUP → SUGGESTION — even an empty step reports "skip — no issues" before moving on; never jump ahead.
- Do NOT apply SUGGESTION items without an explicit per-item decision from the user — via `AskUserQuestion` (one-at-a-time mode) or the webapp's `diff-review-list` (webapp mode); never bulk-apply without either.
- Do NOT refactor outside the scope of the issue being fixed — root-cause that exact issue, don't sneak in extra changes "while you're at it".
- Do NOT commit interdependent issues within a batch individually — commit per batch.
- ALWAYS use `AskUserQuestion` when a STOP-GATE condition (a/b/c/d) matches — never decide on the user's behalf.
- ALWAYS confirm before deleting `.code-review/` or the report dir used.

═══════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════

Look at what was actually fixed in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vci, vtickets, vdesign, vrollback) only if one genuinely fits; if nothing further is needed, say so plainly. (See the shared convention in `_vskills-shared/repo-profile.md` §7.)
