---
name: vsweep
description: "Runs an unattended, time-boxed sweep through an open-ended body of work in a codebase: picks the next gap, dispatches one subagent at a time, finishes clear-cut items with tests and runtime verification, and logs ambiguous ones as pending decisions instead of guessing. On resume, implements the user's decisions on those logged items with the same rigor — root-cause fix, tests, live verification, cleanup, clear user-facing messages."
argument-hint: "[--until <HH:MM>|<duration>] [--resume] [area/scope hint]"
user-invocable: true
when_to_use: "Invoke for an open-ended, time-boxed pass through a backlog with no fixed task list — a bug/security audit, a feature/test/documentation backlog, a refactor pass ('kiểm tra toàn hệ thống tới sáng', 'work through the backlog while I'm away', 'go through every role until X') — or to resume and implement decisions the user gives on a prior run's logged findings."
metadata:
  author: vyvu
  version: "1.1.0"
---

You are running an unattended sweep loop, not a one-shot task. Each iteration picks one work item, dispatches exactly one subagent, triages its report, and checks the clock — repeat until the stop condition is met. A separate RESUME mode (same skill, triggered when the user returns with decisions) implements the logged pending items with full engineering rigor.

═══════════════════════════════════════════════════════
PHASE 0 — SCOPE
═══════════════════════════════════════════════════════

1. Resolve the stop condition from the user's own words: an absolute time, a duration, or an explicit "until I say stop." Genuinely ambiguous → ask once via `AskUserQuestion`, never guess a deadline.
2. Enumerate anything this run will need repeatedly — credentials, accounts, access, reference docs — read seed scripts/fixtures/specs if it isn't already known. Never invent one.
3. Record which servers/services are already running and their ports. This skill NEVER starts or restarts one itself — not even under a fresh verbal permission grant mid-run, if the user (or project memory) has a standing rule against it. Blocked by a down service → say so plainly and move to a different area instead of working around it.
4. Identify how to verify a change safely (a read-only query, a build, a preview, a dry run) for later, and confirm destructive operations (migrations, resets, bulk deletes) are off-limits unless the user says otherwise.
5. Pull prior progress from project memory / past reports before the first iteration — don't rediscover what's already done.

═══════════════════════════════════════════════════════
PHASE 1 — PICK THE NEXT AREA (every iteration)
═══════════════════════════════════════════════════════

Rank candidates, highest value first:
1. Areas never touched at all, or only looked at on paper — no subagent actually dispatched into it yet.
2. Areas not revisited since the most recent change nearby (a fix, a dependency bump, a schema/spec change).
3. A different systemic LENS applied to already-"covered" ground — e.g. "does this component follow the same pattern its siblings do," "does the doc still match what the code actually does now" — not just another pass with the same lens.
4. Anything a previous report explicitly flagged as unconfirmed or cut short for time.

Genuinely unsure which area is highest value → spend one quick fork purely to compile the coverage map (what's done, what's open) before picking. Cheaper than guessing wrong and duplicating work.

═══════════════════════════════════════════════════════
PHASE 2 — DISPATCH (one subagent at a time)
═══════════════════════════════════════════════════════

- Exactly one agent in flight whenever the task touches a resource this session also drives directly — browser automation is the common case: two agents driving the same browser collide on tabs/sessions and can crash a shared dev server under the combined load. A pure static-reading task may run without this constraint, but default to one-at-a-time unless the work is clearly independent.
- Every dispatch prompt is self-contained — a fresh agent remembers nothing from this conversation. Always include:
  - Any credentials/accounts/reference material it needs for this task, if applicable.
  - A short "already confirmed, don't rediscover" list pulled from prior iterations.
  - The hard constraints verbatim: never start/restart a server, never run a migration or destructive data command, stop (don't retry blindly) if a service crashes mid-task.
  - The exact report file path + naming pattern to write to, and the required closing contract: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` plus a one-line `Summary`.
- Don't poll a dispatched agent with repeated short waits — a dispatch already resumes this session automatically when it finishes. Only wait deliberately when nothing is in flight and the only thing left is for the clock itself to reach the stop condition.

═══════════════════════════════════════════════════════
PHASE 3 — TRIAGE (after each report lands)
═══════════════════════════════════════════════════════

Read the agent's actual written report file — an inline chat reply alone is sometimes too compressed to carry a real finding, and it isn't what persists. Sort every finding into exactly one bucket:

- **Do now** — safe, root-cause, matches a pattern already established elsewhere in the codebase. Extend or add a test that would have failed before the fix, rerun it.
- **Do now + verify at runtime** — same as above, but whenever a static read isn't enough proof (access rules, a behavior change, a UI change): exercise it through the real running app in BOTH directions — the previously-broken case now behaves correctly, and the already-working case still does too.
- **Log as a pending decision** — a design trade-off, a scope boundary, a requirement genuinely unclear from the code/spec alone, "is this intentional or a gap." Never guess. Record the concrete impact/scenario, the root cause, and 2-3 named resolution options; keep sweeping other areas while it sits open.
- **Already known** — duplicate of something already done or already logged. Note it, move on.

An earlier report marking something "unconfirmed" or "could not reproduce" is itself a real finding — carry that uncertainty forward honestly rather than quietly resolving it either way.

═══════════════════════════════════════════════════════
PHASE 4 — REGRESSION DISCIPLINE
═══════════════════════════════════════════════════════

After any batch of inline changes, and always before the stop summary: run the full test suite plus every project-specific gate (type-check, lint, build, any contract/boundary gate the project defines) — not only the touched area's own tests, since changes accumulate across many files over a long run. Watch specifically for a type mismatch a transpile-only test runner won't catch but the project's real type-check gate will; green tests alone don't mean a fix is done if a stricter gate exists.

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
2. Deliver exactly one consolidated summary, directly in the conversation (never a new summary file unless the project's own conventions require one), covering: what was done, anything fixed incidentally along the way, what was deliberately left open pending a decision (with the named options), and anything flagged but not confirmed. Follow the project's own reporting conventions if it has them (plain-language, no identifiers, situational framing) even if the run itself was technical.
3. Notify the user only if something needs their decision or attention on return — not a routine "done" ping.

═══════════════════════════════════════════════════════
RESUME MODE — IMPLEMENTING LOGGED DECISIONS
═══════════════════════════════════════════════════════

Triggered when the user comes back with terse answers to the pending items Phase 3 logged.

1. Match each answer to its specific logged item by content, not by assumed order; ask once if a mapping is truly ambiguous.
2. Per item: read the CURRENT code fresh — never implement from memory of the earlier write-up. Reuse the existing pattern elsewhere in the codebase for the same class of problem; when the straightforward mechanism doesn't apply (e.g. a field is encrypted and can't be a database-level filter), adopt the minimal necessary variant and leave a comment explaining the trade-off.
3. Extend the existing test file/helper for that area (parametrize it, don't duplicate a parallel one) with both the regression case and a case that would have failed before the change.
4. Verify end-to-end (the real app, a build, a preview — whatever actually proves it) in both directions before moving to the next item.
5. If verification wrote real rows into a shared/dev dataset, rerun the full suite afterward — a same-environment test can assert exact live counts. Broken by it → delete ONLY the exact rows this run created, never anything that predates it, then reconfirm green.
6. Trace every new error path to the actual user-facing message, not the backend code alone — check the real response/serialization layer, since the human string is often not what's returned verbatim. Replace a generic catch-all message with one specific to the new case, consistent with sibling cases already handled in that same component; watch for a duplicate toast/message when both a callback and a separate manual check could fire for the same error.
7. Final pass once every item is done: lint/format plus the full regression suite across everything touched, before reporting done.

═══════════════════════════════════════════════════════
HARD RULES
═══════════════════════════════════════════════════════

- Never start, restart, or auto-recover a server/service — report the blocker and keep sweeping elsewhere instead.
- Never run a migration, reset, or bulk-destructive data command without the user asking for it by name.
- Never run two agents against the same shared live resource (browser session, exclusive lock) at once.
- Never trust a subagent's chat reply alone for anything whose correctness matters — open its written report.
- Never silently resolve a logged pending decision yourself — only the user's own answer closes it.
- Never let a long run's accumulated changes skip a final full regression pass.

═══════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════

Look at what the run actually found and did this time and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. A `vreview` pass over everything touched, or `vci` for a final typecheck/build sanity check, are common fits if nothing else stands out.
