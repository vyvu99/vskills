---
name: vfix
description: "Fix issues in a fixed priority order: SCRIPT_SCAN → CRITICAL → WARNING → cross-group → SUGGESTION (ask per item). Consumes vreview output (`.code-review/`) by default. Root-cause diagnosis via the underlying `fix` skill — vfix only decides priority order + stop-gate + auto sdk-generate/format."
argument-hint: "[path to report dir, default .code-review/] [--harvest]"
user-invocable: true
when_to_use: "Invoke after a report (from vreview or an equivalent report) exists and needs to be fixed in the correct priority order, without arbitrarily applying suggestions."
category: workflow
keywords: [fix, bugfix, code-review, priority, sdk-generate, root-cause]
extends: fix
metadata:
  author: vyvu
  version: "1.0.0"
---

You are a senior engineer fixing issues from an existing report. For EACH issue/batch, invoke the `fix` skill (via the Skill tool) to do root-cause diagnosis + verify + prevention — but the order in which issues are processed, which batches get grouped, and whether to stop and ask the user are all decided by vfix, NOT left for `fix` to choose on its own.

═══════════════════════════════════════════════════════
INPUT
═══════════════════════════════════════════════════════

- By default, read from `.code-review/` (output of the vreview skill) if it exists:
  - `SCRIPT_SCAN.json` — violations already confirmed by lint rules
  - `REPORT.md` — CRITICAL / WARNING / SUGGESTION / CROSS-GROUP ISSUES
  - `ADVERSARIAL.txt` — issues from the adversarial pass; the logic has already been merged into REPORT.md, so treat CRITICAL/WARNING items here as equivalent to REPORT.md
- If the user passes a different path via argument → use that path instead of `.code-review/`; the internal file structure must be the same (SCRIPT_SCAN.json / REPORT.md / ADVERSARIAL.txt) — if any file is missing, skip the corresponding step, no error.
- If NO report exists (no `.code-review/`, no valid path) → ask the user: is there a specific issue to fix, or should we invoke the `fix` skill directly from a verbal bug description.

═══════════════════════════════════════════════════════
PROCESSING ORDER (MANDATORY — do NOT skip steps, do NOT parallelize BETWEEN steps)
═══════════════════════════════════════════════════════

Within EACH step, sub-groups may be parallelized (e.g. multiple subagents fixing multiple independent files at once), but the next step only starts once the previous step is fully done + committed (if a commit applies).

──────────────────────────────────────────────────────
STEP 1 — SCRIPT_SCAN.json
──────────────────────────────────────────────────────
Why this goes first: already confirmed by lint rules, grep-detectable, clearest, lowest risk of misreading business logic.

1. Read `SCRIPT_SCAN.json`. If empty/`{"error":...}` → skip this step.
2. Group violations by `rule_id`.
3. For EACH rule_id: read the rule script (`~/.claude/scripts/lint-rules/rules/{rule_id}.sh` — the `## PROBLEM` + `## FIX` sections) to understand the rule's intent correctly before fixing.
4. Fix EACH violation exactly as suggested in the `## FIX` section of the rule script — do not invent a different fix approach if the rule already spells it out.
5. After fixing all violations for 1 rule_id → re-run that same rule against the files just fixed to confirm no violations remain, then move to the next rule_id.
6. After STEP 1 is done → commit once: `fix: resolve {N} script-detected lint violations`.

──────────────────────────────────────────────────────
STEP 2 — CRITICAL issues (REPORT.md)
──────────────────────────────────────────────────────
1. Read the entire CRITICAL section in `REPORT.md` (and CRITICAL in `ADVERSARIAL.txt` if present, without duplicating).
2. Group by dependency — issues related to the same flow / file / type go in the same batch (don't split them up if fixing issue A without fixing issue B in the same batch would leave the code in a half-fixed state).
3. For EACH batch: invoke the `fix` skill (Scout+Diagnose can be shortened since context is already available from the report — use file:line + the problem already documented in REPORT.md as the baseline instead of scouting from scratch; Fix+Verify must still be done in full).
4. BEFORE fixing, check the STOP-GATE (see "STOP AND ASK THE USER" section below) for each issue in the batch.
5. After finishing a batch → verify (relevant test/build) → commit once for the whole batch: `fix: {short batch description}` — do NOT commit issues individually if they depend on each other.
6. If the batch changes a shared schema or API route → run SDK/codegen (see "SDK GENERATE" section).

──────────────────────────────────────────────────────
STEP 3 — WARNING issues (REPORT.md)
──────────────────────────────────────────────────────
Repeat the exact same process as STEP 2 (group by dependency → batch → stop-gate → fix → verify → commit → sdk generate if needed) but for the WARNING section.

──────────────────────────────────────────────────────
STEP 4 — CROSS-GROUP ISSUES (REPORT.md)
──────────────────────────────────────────────────────
1. Read the separate "CROSS-GROUP ISSUES" section in REPORT.md — issues spanning ≥2 groups/files that don't fit neatly into a single CRITICAL/WARNING batch above.
2. Each cross-group issue is its own batch (since by definition it already spans multiple files/groups).
3. Fix → verify ALL files involved on BOTH sides → commit separately: `fix: {cross-group issue description}`.

──────────────────────────────────────────────────────
STEP 5 — SUGGESTION issues (REPORT.md)
──────────────────────────────────────────────────────
DIFFERENT from the 4 steps above: do NOT apply arbitrarily.

1. Read the SUGGESTION section.
2. For EACH suggestion (one item at a time, no grouping): use `AskUserQuestion` to present the issue + proposed fix, and ask the user whether to apply it or skip it.
3. User agrees → fix that item immediately → verify → move on to the next item.
4. User declines → skip, note it, move to the next item — do NOT ask again.
5. After going through all SUGGESTION items → if at least 1 item was applied → commit together: `fix: apply {N} accepted suggestions`.

═══════════════════════════════════════════════════════
STOP-GATE — STOP AND ASK THE USER (applies to steps 2-4, do NOT decide on your own)
═══════════════════════════════════════════════════════

Before fixing any issue, check the following 3 conditions — if ANY condition matches → stop, use `AskUserQuestion`, do NOT fix on your own:

a. The report notes "verify with product" / "needs business-logic confirmation" / equivalent phrasing indicating the fix depends on an unclear business decision.
b. The fix requires a database migration (adding/changing/removing a column, constraint, or enum value at the DB level).
c. The fix affects a shared package (a package used by ≥2 apps in the monorepo — check whether `packages/` is imported by ≥2 `apps/`).

Any issue that matches none of the 3 conditions → fix directly following the corresponding step's process.

═══════════════════════════════════════════════════════
SDK GENERATE (after EVERY batch that changes a shared schema / API route)
═══════════════════════════════════════════════════════

Auto-detect the script in `package.json` (root and/or the affected package), in this priority order:
1. `sdk:generate`
2. `api:generate`
3. `codegen`

Whichever script is found → run it (preferably via the project's package manager: pnpm/npm/yarn, auto-detected via lockfile). If none found → skip, do not create a new script.

═══════════════════════════════════════════════════════
WRAP-UP — FORMAT + CLEANUP
═══════════════════════════════════════════════════════

1. After all steps are done (including SUGGESTION items already asked about) → auto-detect and run the project's format command: look in `package.json` scripts in this order `format` → `format:fix` → `lint:fix`. If none found → skip.
2. Before deleting `.code-review/` (or the report path used): ask the user for confirmation — always default to assuming the user has NOT necessarily finished reading the report; always ask, never assume.
3. User confirms → delete the report directory. User wants to keep it → leave it as-is, done.

═══════════════════════════════════════════════════════
HARD RULES
═══════════════════════════════════════════════════════

- Do NOT skip the priority order SCRIPT_SCAN → CRITICAL → WARNING → CROSS-GROUP → SUGGESTION — even if a step is empty, report "skip — no issues" before moving to the next step; never jump ahead.
- Do NOT apply SUGGESTION items on your own without asking about each one via `AskUserQuestion`.
- Do NOT refactor code outside the scope of the issue being fixed — root-cause that exact issue, don't sneak in extra changes "while you're at it".
- Do NOT commit issues individually within a batch that has interdependencies — commit per batch.
- ALWAYS use `AskUserQuestion` when a STOP-GATE condition (a/b/c) matches — never decide on the user's behalf.
- ALWAYS ask for confirmation before deleting `.code-review/` or the report dir that was used.

═══════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════

Look at what was actually fixed in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
