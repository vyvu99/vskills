---
name: vautocook
description: "Autonomously implements every sub-issue of a GitHub epic in sequence, each as an isolated headless /vcook run with its own branch + PR, ordered by dependency, resumable, fail-fast. Wraps 2 bundled scripts (plan_tasks.py, run_tasks.py) that shell out to `claude -p --dangerously-skip-permissions` per task — high blast radius, the plan is always shown to the user for confirmation before it runs."
argument-hint: "<epic_url>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Invoke after an epic + sub-issues already exist (e.g. created by vtickets) and you want them implemented unattended, one by one, without babysitting each /vcook run."
metadata:
  author: vyvu
  version: "1.0.0"
---

Auto-implement every sub-issue under a GitHub epic, sequentially, unattended. Each sub-issue runs as its own isolated `/vcook` session in headless mode (`claude -p --dangerously-skip-permissions`) — its own branch, its own PR, no back-and-forth with anyone mid-task. Built on 2 bundled scripts in this skill's `scripts/` folder; this file is the instructions for *when and how* to run them, not a script itself.

Read input from the user:

```
$ARGUMENTS
```

`$ARGUMENTS` is empty — ask the user for the epic issue URL (e.g. one `vtickets` just created).

---

## Step 0 — Resolve the VCS profile + prerequisites

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (absent → assume GitHub + gh). Not full gh mode → **STOP** — this skill's entire mechanism (fetching sub-issues, opening PRs) is GitHub-native with no fallback; tell the user to fix `gh` auth first.

Also verify `claude` is on PATH and logged in (the scripts shell out to it once per task): `which claude` fails → STOP, tell the user to install/log in the Claude Code CLI first.

## Step 1 — Generate the task plan (read-only, safe)

```bash
python3 ~/.claude/skills/vautocook/scripts/plan_tasks.py <epic_url>
```

- Fetches the epic's sub-issues via the GitHub GraphQL API.
- Runs ONE headless `claude -p` call asking it to order the sub-issues into a sequential chain (each task depends only on the one right before it) and derive a branch name per task.
- Detects sub-issues already done (issue closed + a PR merged into the repo's default branch) and marks them `status: "done"` so step 3 skips them.
- Writes `tasks.json` next to the script — local scratch state for this pipeline run, not a plan artifact; don't commit it or reference it from code/PR comments.

This step makes no code changes and opens nothing — safe to run without asking first.

## Step 2 — Show the plan, get explicit confirmation

Read the generated `tasks.json`, print the ordered task list (number, title, branch name, dependency chain) to the user. **STOP and get explicit go-ahead before Step 3 — this is a hard gate, not optional:** Step 3 runs fully autonomous coding sessions with `--dangerously-skip-permissions` that push branches and open real PRs, one right after another, with no per-task confirmation once started. Point out:
- How many tasks are pending vs. already done.
- That it's fail-fast — one task failing stops the whole pipeline; already-done tasks stay done.
- That `tasks.json` can be hand-edited (reorder, fix a bad dependency, fix a wrong branch name) before Step 3 — that's exactly why the two scripts are separate.

## Step 3 — Run the pipeline

Only after the user confirms:

```bash
python3 ~/.claude/skills/vautocook/scripts/run_tasks.py
```

- For each pending task, in order: checks out its branch (from the default branch, or from its dependency's branch if that dependency isn't merged yet — a stacked-PR chain), fills `scripts/prompt.md` with the task's context, and runs `claude -p <prompt> --dangerously-skip-permissions --output-format stream-json --verbose`. That inner session runs `/vcook` on the issue in headless mode (never stops to ask; resolves ambiguity itself per root-cause/KISS/DRY, documents the decision in the PR body) and is expected to create its own commit + PR via `/vcook`'s own Step 9.
- After the inner session exits, verifies a PR now exists for the branch; `/vcook` didn't manage to open one → falls back to pushing the branch and opening a minimal PR itself (no extra AI call for that fallback).
- **Resume:** Ctrl+C or a crash mid-run leaves that task `status: "running"` in `tasks.json` — re-running `run_tasks.py` resets it to `pending` and continues from there.
- **Fail-fast:** a task ending without a PR stops the whole run; fix it (or edit `tasks.json`) and re-run to continue.
- On completion, prints the **merge order** — later tasks stack on earlier ones' branches, so PRs must be merged top-down, one level at a time, with a rebase between levels.

## Step 4 — Report

Summarize what ran: tasks completed this run and their PR URLs, any task left `pending`/`failed`, and the merge order from Step 3's output. Do not silently stop mid-epic without saying which task blocked it.

---

## Hard rules

- **Never** run Step 3 without the user explicitly confirming the Step 2 task list first — `--dangerously-skip-permissions` per task means zero human-in-the-loop once it starts.
- **Never** hand-edit `tasks.json`'s `status` field yourself to force a task as done/skipped — if a task needs skipping, tell the user to edit the file themselves; which task is safe to skip is their call, not this skill's.
- Each inner `/vcook` run is a **fresh, isolated session** — it does not see this conversation. Its only inputs are `prompt.md`'s filled template (issue URL, epic URL, branch, parent branch, issue number) — nothing else from this conversation transfers.
- The pipeline is GitHub-only (GraphQL sub-issues, `gh pr create`) — no degraded/non-GitHub mode; the §2 STOP applies at Step 0, not mid-run.
- `tasks.json` is scratch state for this pipeline run, not a plan artifact.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
