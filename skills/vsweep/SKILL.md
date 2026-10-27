---
name: vsweep
description: "Runs an unattended, time-boxed sweep through an open-ended body of work of any kind (code audit, backlog, research, writing, data cleanup, ops checklist, brainstorming): picks the next gap, dispatches subagents, finishes clear-cut items and verifies them in the way that fits the work, and logs ambiguous ones as pending decisions instead of guessing. On resume it implements the user's decisions on those logged items."
argument-hint: "[--until <HH:MM>|<duration>] [--resume] [topic/scope hint]"
user-invocable: true
when_to_use: "Use for an open-ended pass with a deadline and no fixed task list: 'audit the whole system until morning', 'brainstorm every angle for 2 hours', 'work through the backlog while I'm away', 'kiểm tra toàn hệ thống tới sáng', or to implement the user's decisions on a previous sweep's logged findings (--resume). Not for a single well-defined task."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vsweep

This is a loop, not a one-shot task. The skill assumes no task type: a work item is whatever unit the topic breaks into (a module, a question, a document, a data slice, a checklist line), and "verified" means whatever proves that kind of work (a test, a recomputation, a source check, a dry run, a second reader). Each iteration picks one item, dispatches a subagent, triages its report and checks the clock, until the stop condition. Steps that mention servers, tests, builds or migrations apply only when the work involves them. Scope is the user's topic: no unrequested features, tests or docs.

```
$ARGUMENTS
```

`--resume` or decisions on logged findings: read `references/resume-mode.md` and follow it instead of the sweep below.

## Standing rules

- Never start, restart or auto-recover a server or service. If a down service blocks an area, say so and sweep elsewhere. A standing user rule beats any mid-run permission.
- Never run a migration, reset or bulk delete unless the user asked for it by name.
- Never run two agents against the same shared live resource (a browser session, an exclusive lock): they collide and can crash a shared dev server.
- Never close a logged pending decision yourself; only the user's answer does.
- Open the subagent's written report before trusting a finding. A chat reply is compressed and does not persist.
- A fact the user verified by hand beats anything an agent read or inferred. A vendor page, store listing or marketing claim stays unverified until someone has used the thing.

## Phase 0 — Scope

1. Resolve the stop condition from the user's words: a clock time, a duration, or "until I say stop". If it is truly ambiguous, ask once with `AskUserQuestion` rather than guessing a deadline.
2. Decide and write down three things for this kind of work: the **area** one iteration covers (a module, a question, a chapter, a table, a checklist line); the **done-proof** (a failing-then-passing test plus a runtime check, a source you opened yourself, a second reader, a recount, a dry run; the agent's say-so never counts); the **parallelism** (independent read-only items may run side by side, anything touching a shared live resource goes one at a time).
3. Note which services are already running and their ports, how to verify a change safely (read-only query, build, preview, dry run), and that destructive operations are off-limits unless the user says otherwise. Collect credentials or reference docs the work needs from seed scripts, fixtures or specs, and never invent them.
4. Pull prior progress from project memory and past reports, so finished work is not rediscovered.
5. Create the state file `{reports}/vsweep-<slug>-state.md` (`{reports}` is the project's reports directory, e.g. `plans/reports/`) before dispatching. It holds the start time and `DEADLINE` (from `date`, never estimated), the coverage map (a checkbox per area), the three decisions from step 2, a **User decisions (sticky)** section quoting the user verbatim (never reversed without asking), and the settled findings. Re-read it after any context compaction, and point dispatch prompts at it instead of retyping context.
6. Arm the stop guard: `printf '%s\n%s\n' "<state file path>" "$(( $(date +%s) + <seconds> ))" > ~/.claude/vsweep-active`. This is harmless if the hook is not installed, because it is only a file. `stop-guard.sh` reads exactly these two lines (state path, deadline epoch).

## Phase 1 — Pick the next area

Highest value first:
1. Areas never touched, or only looked at on paper.
2. Areas not revisited since a nearby change (a fix, a dependency bump, a spec change).
3. A different systemic lens on covered ground (for example "does this follow the pattern its siblings use", "does the doc still match the code"), not another pass with the same lens.
4. Anything a previous report flagged as unconfirmed or cut short.

If it is unclear which area is highest value, run one cheap subagent just to compile the coverage map before choosing; that costs less than duplicating work.

## Phase 2 — Dispatch

Default to one subagent in flight. Independent read-only items with no shared live resource may run in parallel, up to 3 at once (more makes triage the bottleneck and raises load), each with its own report file and a non-overlapping topic. A fresh agent knows nothing of this conversation, so every brief contains:
- The objective and the single area.
- Credentials or reference material it needs, and a short "already confirmed, do not rediscover" list from earlier iterations.
- The standing rules above, verbatim, and: stop rather than retry blindly if a service crashes.
- The exact report path and naming pattern, a `TL;DR` of at most 20 lines at the top (so triage reads the head and greps the rest), and the closing contract `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` plus a one-line `Summary`.
- That the report file must be written; a long chat reply without a file is a failed dispatch, so resume the agent (`SendMessage`) to save it.

Do not poll a running agent with short waits: its completion resumes this session. Wait deliberately only when nothing is in flight and the clock is the only thing left.

## Phase 3 — Triage

Read the written report, then put each finding in exactly one bucket:
- **Do now**: safe, root-cause, matches a pattern already established elsewhere. Add or run the check that would have failed before the change, and rerun it.
- **Do now and verify for real**: as above, but a static read is not proof (access rules, a behavior or UI change, a number that depends on live data). Exercise it in both directions: the broken case now works and the working case still does.
- **Log as pending decision**: a trade-off, a scope boundary, a requirement unclear from the code or spec, "intentional or a gap". Record the concrete scenario, the root cause and 2-3 named options, and keep sweeping.
- **Already known**: a duplicate. Note it and move on.

A report that says "unconfirmed" or "could not reproduce" is a finding in itself; carry the uncertainty forward. Before recording anything, verify one load-bearing claim per report yourself (grep the file, open the cited source, recompute the figure). Then update the state file: settled findings, corrections to earlier reports, new questions for the user.

Run an adversarial pass (find contradictions between reports, unsourced numbers, claims nobody checked by hand) about every 3-4 reports and once before the final summary, giving it the raw reports, not your conclusions.

## Phase 4 — Loop control

After every iteration check the real clock (`date`, never estimate) against `DEADLINE`. Not reached: go to Phase 1. Reached: stop at once, even mid-thought, and delete `~/.claude/vsweep-active`.

A skill cannot force a turn to continue, so keep it moving:
- Make the tool call for the next step in the same turn instead of writing "next I will X" and ending the turn.
- Ending a turn is fine only when at least one agent is in flight (its completion wakes you) or you wait on a user decision. Nothing in flight and deadline open means dispatch now.
- A user message mid-run gets a one or two line answer, then the loop continues in the same turn.
- Coverage finished early: do depth passes, not padding (red-team all reports, reconcile numbers, a new lens on covered ground). If the marginal value is clearly low, ask whether to stop early.
- Stop guard: `stop-guard.sh` next to this file is an opt-in Stop hook. While `~/.claude/vsweep-active` exists and the deadline is ahead, it nudges once per stop, fails open, and allows the second stop so it never loops. Enable it by adding the hook from the comment at the top of the script to `~/.claude/settings.json`. Cancel a run with `rm ~/.claude/vsweep-active`.

## Phase 5 — Final verification

Before the stop summary, re-verify everything touched together, not each item alone, because changes accumulate across a long run. For code: the full test suite and every project gate (typecheck, lint, build, any boundary check). A transpile-only test runner can miss a type error the real typecheck catches, so green tests alone do not mean done. For other kinds of work, run the equivalent whole-set check. If a gate cannot run, say so in the summary.

## Phase 6 — Stop and hand off

1. Remove `~/.claude/vsweep-active` if still present, then run one sanity pass over everything changed (a status or diff listing) and confirm each touched file traces to an explainable change.
2. Give one consolidated summary in the conversation, not a new file unless the project requires one: what is settled and how it was verified, what is unverified, contradictions found, anything fixed incidentally, and one decision table for the user ordered by what blocks the work (each with its named options). Follow the project's reporting conventions if it has them.
3. Notify the user only if something needs their decision on return, not for a routine "done".

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
