---
name: vsweep
description: "Runs an unattended, time-boxed bug/security sweep across a codebase: picks the next coverage gap, dispatches one investigative subagent at a time, fixes clear-cut issues with tests and live verification, and logs ambiguous findings as pending decisions instead of guessing. On resume, implements the user's decisions on those logged findings with the same rigor — root-cause fix, tests, live verification, cleanup, clear user-facing messages."
argument-hint: "[--until <HH:MM>|<duration>] [--resume] [area/role hint]"
user-invocable: true
when_to_use: "Invoke for an open-ended, time-boxed audit with no fixed task list ('kiểm tra toàn hệ thống tới sáng', 'sweep for bugs while I'm away', 'test every role until X') or to resume and implement decisions the user gives on a prior sweep's logged findings."
metadata:
  author: vyvu
  version: "1.0.0"
---

You are running an unattended sweep loop, not a one-shot task. Each iteration picks one coverage gap, dispatches exactly one investigative subagent, triages its report, and checks the clock — repeat until the stop condition is met. A separate RESUME mode (same skill, triggered when the user returns with decisions) implements the logged pending items with full engineering rigor.

═══════════════════════════════════════════════════════
PHASE 0 — SCOPE
═══════════════════════════════════════════════════════

1. Resolve the stop condition from the user's own words: an absolute time, a duration, or an explicit "until I say stop." Genuinely ambiguous → ask once via `AskUserQuestion`, never guess a deadline.
2. Enumerate every role/account this sweep will need (read seed scripts/fixtures if credentials aren't already known) — never invent one.
3. Record which servers/services are already running and their ports. This skill NEVER starts or restarts one itself — not even under a fresh verbal permission grant mid-run, if the user (or project memory) has a standing rule against it. Blocked by a down service → say so plainly and move to a different area instead of working around it.
4. Identify a read-only way to inspect the live dataset (a DB client, an admin query) for verification later, and confirm destructive operations (migrations, resets, bulk deletes) are off-limits unless the user says otherwise.
5. Pull prior coverage from project memory / past reports before the first iteration — don't rediscover what's already closed.

═══════════════════════════════════════════════════════
PHASE 1 — PICK THE NEXT AREA (every iteration)
═══════════════════════════════════════════════════════

Rank candidates, highest value first:
1. Areas never exercised live (static-review-only, or no sweep at all yet).
2. Roles/data not retested since the most recent fix or dataset change.
3. A different systemic LENS applied to already-"covered" ground — e.g. "does this route carry the same guard its siblings do," "does the UI's own gate match the backend's real check" — not just another pass with the same lens.
4. Anything a previous report explicitly flagged as unconfirmed or cut short for time.

Genuinely unsure which area is highest value → spend one quick fork purely to compile the coverage map (what's closed, what's open) before picking. Cheaper than guessing wrong and duplicating work.

═══════════════════════════════════════════════════════
PHASE 2 — DISPATCH (one subagent at a time)
═══════════════════════════════════════════════════════

- Exactly one agent in flight whenever the task touches a resource this session also drives directly — browser automation is the common case: two agents driving the same browser collide on tabs/sessions and can crash a shared dev server under the combined load. A pure static-code-reading task may run without this constraint, but default to one-at-a-time unless the work is clearly independent.
- Every dispatch prompt is self-contained — a fresh agent remembers nothing from this conversation. Always include:
  - The exact credentials/accounts it needs for this task.
  - A short "already confirmed, don't rediscover" list pulled from prior iterations.
  - The hard constraints verbatim: never start/restart a server, never run a migration or destructive data command, stop (don't retry blindly) if a service crashes mid-task.
  - The exact report file path + naming pattern to write to, and the required closing contract: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` plus a one-line `Summary`.
- Don't poll a dispatched agent with repeated short waits — a dispatch already resumes this session automatically when it finishes. Only wait deliberately when nothing is in flight and the only thing left is for the clock itself to reach the stop condition.

═══════════════════════════════════════════════════════
PHASE 3 — TRIAGE (after each report lands)
═══════════════════════════════════════════════════════

Read the agent's actual written report file — an inline chat reply alone is sometimes too compressed to carry a real finding, and it isn't what persists. Sort every finding into exactly one bucket:

- **Fix now** — safe, root-cause, matches a pattern already established elsewhere in the codebase. Extend or add a test that would have failed before the fix, rerun it.
- **Fix now + live-verify** — same as above, but for anything access-control/IDOR-shaped: also exercise it through the real running app (not unit tests alone) in BOTH directions — the blocked case now fails correctly, and a legitimate same-scope case still succeeds.
- **Log as a pending decision** — a fail-open-vs-fail-closed trade-off, a scope boundary, "is this intentional or a bug." Never guess. Record the concrete impact scenario, the root cause, and 2-3 named resolution options; keep sweeping other areas while it sits open.
- **Already known** — duplicate of something already fixed or already logged. Note it, move on.

An earlier report marking something "unconfirmed" or "could not reproduce" is itself a real finding — carry that uncertainty forward honestly rather than quietly resolving it either way.

═══════════════════════════════════════════════════════
PHASE 4 — REGRESSION DISCIPLINE
═══════════════════════════════════════════════════════

After any batch of inline fixes, and always before the stop summary: run the full test suite plus every project-specific gate (type-check, lint, any contract/boundary gate the project defines) — not only the touched area's own tests, since fixes accumulate across many files over a long run. Watch specifically for a type mismatch a transpile-only test runner won't catch but the project's real type-check gate will; green tests alone don't mean the fix is done if a stricter gate exists.

═══════════════════════════════════════════════════════
PHASE 5 — LOOP CONTROL
═══════════════════════════════════════════════════════

Check the actual clock (never estimate elapsed time) against the stop condition after every iteration.
- Not reached → pick the next area (Phase 1), dispatch (Phase 2), continue.
- Reached → stop immediately, even mid-thought. Do not start "one more, just in case."

═══════════════════════════════════════════════════════
PHASE 6 — STOP → HANDOFF
═══════════════════════════════════════════════════════

1. Run one final sanity pass over everything changed this run (a status/diff listing) — confirm every touched file traces to a real, explainable change before it reaches the user.
2. Deliver exactly one consolidated summary, directly in the conversation (never a new summary file unless the project's own conventions require one), covering: fixed security/access-control issues, fixed functional bugs, any incidental pre-existing test-suite fixes, issues found but deliberately left open pending a decision (with the named options), and anything a sweep flagged but could not confirm. Follow the project's own reporting conventions if it has them (plain-language, no identifiers, situational framing) even if the sweep itself was technical.
3. Notify the user only if something needs their decision or attention on return — not a routine "done" ping.

═══════════════════════════════════════════════════════
RESUME MODE — IMPLEMENTING LOGGED DECISIONS
═══════════════════════════════════════════════════════

Triggered when the user comes back with terse answers to the pending items Phase 3 logged.

1. Match each answer to its specific logged item by content, not by assumed order; ask once if a mapping is truly ambiguous.
2. Per item: read the CURRENT code fresh — never implement from memory of the earlier write-up. Reuse the existing pattern elsewhere in the codebase for the same class of problem; when the straightforward mechanism doesn't apply (e.g. a field is encrypted and can't be a database-level filter), adopt the minimal necessary variant and leave a comment explaining the trade-off.
3. Extend the existing test file/helper for that area (parametrize it, don't duplicate a parallel one) with both the regression case and a case that would have failed before the fix.
4. Live-verify through the real app in both directions (blocked case now blocked, legitimate case still works) before moving to the next item.
5. If live verification wrote real rows into a shared/dev dataset, rerun the full suite afterward — a same-environment test can assert exact live counts. Broken by it → delete ONLY the exact rows this run created, never anything that predates it, then reconfirm green.
6. Trace every new error path to the actual user-facing message, not the backend code alone — check the real response/serialization layer, since the human string is often not what's returned verbatim. Replace a generic catch-all message with one specific to the new case, consistent with sibling cases already handled in that same component; watch for a duplicate toast/message when both a callback and a separate manual check could fire for the same error.
7. Final pass once every item is done: lint/format plus the full regression suite across everything touched, before reporting done.

═══════════════════════════════════════════════════════
HARD RULES
═══════════════════════════════════════════════════════

- Never start, restart, or auto-recover a server/service — report the blocker and keep sweeping elsewhere instead.
- Never run a migration, reset, or bulk-destructive data command without the user asking for it by name.
- Never run two agents against the same shared live resource (browser session, exclusive lock) at once.
- Never trust a subagent's chat reply alone for anything access-control-relevant — open its written report.
- Never silently resolve a logged pending decision yourself — only the user's own answer closes it.
- Never let a long run's accumulated changes skip a final full regression pass.

═══════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════

Look at what the sweep actually found and fixed this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. A `vreview` pass over everything touched, or `vci` for a final typecheck/build sanity check, are common fits if nothing else stands out.
