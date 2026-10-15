---
name: vsweep
description: "Runs an unattended, time-boxed sweep through an open-ended body of work of ANY kind (code, research, writing, data, ops, design, brainstorming — the skill does not assume a task type): picks the next gap, dispatches subagents, finishes clear-cut items and verifies them in the way that fits the work, and logs ambiguous ones as pending decisions instead of guessing. On resume, implements the user's decisions on those logged items with the same rigor — root-cause fix, verification, cleanup, clear user-facing messages."
argument-hint: "[--until <HH:MM>|<duration>] [--resume] [topic/scope hint]"
user-invocable: true
when_to_use: "Invoke for an open-ended, time-boxed pass through a backlog or topic with no fixed task list, whatever the kind of work — a bug/security audit, a feature/test/documentation backlog, a refactor pass, a research or brainstorm sweep, a content/data cleanup, an ops checklist ('kiểm tra toàn hệ thống tới sáng', 'cứ brainstorm mọi ý tưởng xoay quanh trong 2 giờ', 'work through the backlog while I'm away', 'go through every role until X') — or to resume and implement decisions the user gives on a prior run's logged findings."
metadata:
  author: vyvu
  version: "1.2.0"
---

You are running an unattended sweep loop, not a one-shot task. The skill is task-agnostic: a "work item" is whatever unit the user's topic breaks into (a module, a question, a document, a dataset slice, a checklist line), and "verify" means whatever proves that kind of work (tests, recomputation, a source check, a dry run, a second reader). Each iteration picks one work item, dispatches a subagent, triages its report, and checks the clock — repeat until the stop condition is met. A separate RESUME mode (same skill, triggered when the user returns with decisions) implements the logged pending items with full rigor for that kind of work.

Steps below that mention servers, tests, builds or migrations apply only when the work involves them; skip them otherwise instead of inventing equivalents. Decide the area, done-proof and parallelism for this kind of work up front (see ADAPTING TO THE KIND OF WORK below).

═══════════════════════════════════════════════════════
PHASE 0 — SCOPE
═══════════════════════════════════════════════════════

1. Resolve the stop condition from the user's own words: an absolute time, a duration, or an explicit "until I say stop." Genuinely ambiguous → ask once via `AskUserQuestion`, never guess a deadline.
2. Enumerate anything this run will need repeatedly — credentials, accounts, access, reference docs — read seed scripts/fixtures/specs if it isn't already known. Never invent one.
3. Record which servers/services are already running and their ports. This skill NEVER starts or restarts one itself — not even under a fresh verbal permission grant mid-run, if the user (or project memory) has a standing rule against it. Blocked by a down service → say so plainly and move to a different area instead of working around it.
4. Identify how to verify a change safely (a read-only query, a build, a preview, a dry run) for later, and confirm destructive operations (migrations, resets, bulk deletes) are off-limits unless the user says otherwise.
5. Pull prior progress from project memory / past reports before the first iteration — don't rediscover what's already done.
6. Create the STATE FILE `{reports}/vsweep-<slug>-state.md` (`{reports}` = the project's reports directory, e.g. `plans/reports/`) before dispatching anything. It holds: start time and `DEADLINE` (from `date`, never estimated), the coverage map (checkbox per area), a **User decisions (sticky)** section quoting the user verbatim — never reversed without asking — and the settled findings so far. Re-read it after any context compaction and point every dispatch prompt at it instead of retyping context.
7. Arm the stop guard (see PHASE 5): `printf '%s\n%s\n' "<state file path>" "$(( $(date +%s) + <seconds> ))" > ~/.claude/vsweep-active` (harmless if the stop-guard hook is not installed — it is just a file nothing reads).

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
PHASE 2 — DISPATCH (default: one subagent at a time)
═══════════════════════════════════════════════════════

- Exactly one agent in flight whenever the task touches a resource this session also drives directly — browser automation is the common case: two agents driving the same browser collide on tabs/sessions and can crash a shared dev server under the combined load. A pure static-reading task may run without this constraint, but default to one-at-a-time unless the work is clearly independent.
- Every dispatch prompt is self-contained — a fresh agent remembers nothing from this conversation. Always include:
  - Any credentials/accounts/reference material it needs for this task, if applicable.
  - A short "already confirmed, don't rediscover" list pulled from prior iterations.
  - The hard constraints verbatim: never start/restart a server, never run a migration or destructive data command, stop (don't retry blindly) if a service crashes mid-task.
  - The exact report file path + naming pattern to write to, and the required closing contract: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` plus a one-line `Summary`.
  - Report contract: start the report with a `TL;DR` of ≤20 lines (so triage can read the head and grep the rest), and WRITE THE FILE — a long chat reply without a file is a failed dispatch; resume the agent (`SendMessage`) to save it.
- Independent read-only/research tasks (no shared live resource) may run in parallel, up to ~3 at once; give each its own report file and non-overlapping topic.
- Don't poll a dispatched agent with repeated short waits — a dispatch already resumes this session automatically when it finishes. Only wait deliberately when nothing is in flight and the only thing left is for the clock itself to reach the stop condition.

═══════════════════════════════════════════════════════
PHASE 3 — TRIAGE (after each report lands)
═══════════════════════════════════════════════════════

Read the agent's actual written report file — an inline chat reply alone is sometimes too compressed to carry a real finding, and it isn't what persists. Sort every finding into exactly one bucket:

- **Do now** — safe, root-cause, matches a pattern already established elsewhere in the work. Add or run the check that would have failed before the change (a test, a recomputation, a re-read of the source, a second reader) and rerun it.
- **Do now + verify for real** — same as above, but whenever a static read isn't enough proof (access rules, a behavior change, a UI change, a number that depends on live data): exercise it for real in BOTH directions — the previously-broken case now behaves correctly, and the already-working case still does too.
- **Log as a pending decision** — a design trade-off, a scope boundary, a requirement genuinely unclear from the code/spec alone, "is this intentional or a gap." Never guess. Record the concrete impact/scenario, the root cause, and 2-3 named resolution options; keep sweeping other areas while it sits open.
- **Already known** — duplicate of something already done or already logged. Note it, move on.

An earlier report marking something "unconfirmed" or "could not reproduce" is itself a real finding — carry that uncertainty forward honestly rather than quietly resolving it either way.

Before recording a finding, verify at least one load-bearing claim per report yourself (grep the file, open the cited source, recompute the arithmetic). Vendor/store-listing/marketing claims are unverified until someone has used the thing — one real hands-on check from the user outranks any listing. Record each triaged report in the state file (settled findings, corrections to earlier reports, new questions for the user).

═══════════════════════════════════════════════════════
PHASE 4 — FINAL VERIFICATION (REGRESSION DISCIPLINE)
═══════════════════════════════════════════════════════

Whatever the kind of work, accumulated changes get one full re-check before the stop summary: re-verify everything touched together, not only each item in isolation. For code that means (and for other kinds, substitute the equivalent whole-set check): after any batch of inline changes, and always before the stop summary, run the full test suite plus every project-specific gate (type-check, lint, build, any contract/boundary gate the project defines) — not only the touched area's own tests, since changes accumulate across many files over a long run. Watch specifically for a type mismatch a transpile-only test runner won't catch but the project's real type-check gate will; green tests alone don't mean a fix is done if a stricter gate exists.

═══════════════════════════════════════════════════════
PHASE 5 — LOOP CONTROL
═══════════════════════════════════════════════════════

Check the actual clock (`date`, never estimate elapsed time) against the DEADLINE in the state file after every iteration.
- Not reached → pick the next area (Phase 1), dispatch (Phase 2), continue.
- Reached → stop immediately, even mid-thought. Do not start "one more, just in case." Delete `~/.claude/vsweep-active`.

Anti-idle rules (a skill cannot force a turn to continue; these keep it moving):
- Never write "next I will X" and end the turn — make the tool call for X in the same turn. Triage and the next dispatch belong to one turn.
- Ending a turn is fine only when ≥1 agent is in flight (its completion wakes you), or you are blocked on a user decision. Nothing in flight and deadline not reached → dispatch now.
- A user message mid-run: answer it in one or two lines, then keep the loop going in the same turn.
- Coverage map finished before the deadline → do depth passes, not padding: a red-team pass over all reports (contradictions between reports, unsourced numbers, claims resting on listings nobody tried), a numbers-reconciliation pass, a new lens on covered ground. If the marginal value is clearly low, ask the user whether to stop early instead of filling the clock.
- Stop guard: `stop-guard.sh` (next to this file) is an opt-in Stop hook. While `~/.claude/vsweep-active` exists and the deadline is in the future, it nudges once per stop with a reason to continue; it fail-opens and never loops (it allows the second stop). Enable it by adding the hook from the comment at the top of `stop-guard.sh` to `~/.claude/settings.json`. Cancel a run early with `rm ~/.claude/vsweep-active`.

═══════════════════════════════════════════════════════
ADAPTING TO THE KIND OF WORK
═══════════════════════════════════════════════════════

The loop is the same for every kind of work; only three things change. Decide them in Phase 0 and write them in the state file:
1. **Area** — what one iteration covers: a module or endpoint (code), a question or topic (research/brainstorm), a chapter or section (writing), a table or slice (data), a checklist line (ops).
2. **Done-proof** — what makes an item "done": a failing-then-passing test and a runtime check (code), a source you opened yourself or a recomputed number (research), a second reader or fact check (writing), a recount or diff (data), a dry run (ops). Never accept the agent's say-so as the proof.
3. **Parallelism** — independent read-only/research items may run side by side (Phase 2); anything touching a shared live resource stays one at a time.

Independent of the kind of work:
- Run an adversarial pass (find contradictions between reports, unsourced numbers, claims nobody checked by hand) after roughly every 3-4 reports and once before the final summary; give it the raw reports, not your conclusions.
- Facts a person verified by hand beat anything an agent read or inferred. Quote them in the state file's sticky section.
- The final summary: what is settled (with how it was verified), what is unverified, contradictions found, and one decision table for the user ordered by what blocks the work.

═══════════════════════════════════════════════════════
PHASE 6 — STOP → HANDOFF
═══════════════════════════════════════════════════════

1. Disarm the stop guard (`rm -f ~/.claude/vsweep-active`) if it is still present, then run one final sanity pass over everything changed this run (a status/diff listing) — confirm every touched file traces to a real, explainable change before it reaches the user.
2. Deliver exactly one consolidated summary, directly in the conversation (never a new summary file unless the project's own conventions require one), covering: what was done, anything fixed incidentally along the way, what was deliberately left open pending a decision (with the named options), and anything flagged but not confirmed. Follow the project's own reporting conventions if it has them (plain-language, no identifiers, situational framing) even if the run itself was technical.
3. Notify the user only if something needs their decision or attention on return — not a routine "done" ping.

═══════════════════════════════════════════════════════
RESUME MODE — IMPLEMENTING LOGGED DECISIONS
═══════════════════════════════════════════════════════

Triggered when the user comes back with terse answers to the pending items Phase 3 logged. The steps below are written for code; for other kinds of work keep the intent (fresh read of the current state, the same pattern as sibling items, a check that fails before and passes after, a real verification, a final whole-set re-check) and swap the tooling.

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
- Never end a turn on an unfulfilled "next I will…" while the deadline is open and nothing is in flight.
- Never treat a store listing, vendor page or marketing claim as verified; a user's hands-on report outranks it.

═══════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════

Look at what the run actually found and did this time and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. A `vreview` pass over everything touched, or `vci` for a final typecheck/build sanity check, are common fits if nothing else stands out.
