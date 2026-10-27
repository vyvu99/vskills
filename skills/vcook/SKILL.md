---
name: vcook
description: "Implements a feature or fix end to end from a plan path or a short description: creates the branch, writes tests first, codes backend and frontend, reviews against CLAUDE.md, runs the tests, commits and opens a PR. Run it explicitly as /vcook."
argument-hint: "[plan-path | task description] [--issue <number>]"
user-invocable: true
disable-model-invocation: true
when_to_use: "Use when the user wants a task or a vplan plan implemented and expects commits and a pull request, not only code edits."
metadata:
  author: vyvu
  version: "2.0.0"
---

You are a senior engineer implementing the task end to end in the 9 steps below. Track the steps in a checklist (TodoWrite or the session's task tool) and mark a step done only when its work is done; Step 1 is a standing rule, so keep it open until Step 9 ends.

**Precedence:** running /vcook is the user's explicit request to create a branch, commit, push and open a PR, so those actions need no extra confirmation. If a project or user `CLAUDE.md` forbids any of them (for example "never create branches or PRs without asking"), that rule wins and you ask first.

**Scope:** implement only what the plan or description asks. Propose any extra improvement instead of adding it, and do not add tests, docs or refactors that were not requested.

After an interruption, rebuild progress from `git status`, `git diff` against the Step 2 branch and (Mode A) the plan file. The repo state is the truth, not an old checklist status.

## Step 1 - Delegate read-only work

Delegate to subagents when read-only work is independent and broad: reading a plan plus many code areas, researching library docs, or reviewing many separate files against CLAUDE.md. Do the work yourself for a lookup of one or two files, because a subagent starts with no context and costs a brief and a summary.

- Independent subagents go in the same message so they run in parallel; batch them per `_vskills-shared/repo-profile.md` §10.
- The brief states the objective, the files or areas in scope, that the agent is read-only, and the report file `{work_context}/plans/reports/<agent-type>-<HHMMSS>-<slug>.md` it writes before replying (§6). Read that file back instead of relying on the reply.
- Write the implementation code yourself, in this session, one step at a time: a single writer keeps the edits coherent.
- Truly independent writers on different files each get their own git worktree so working trees do not collide.

## Step 2 - Determine the branch

1. The current branch already matches the task (the user continues on purpose) -> keep it.
2. Otherwise resolve the default branch (`repo-profile.md` §9). If `git status --porcelain` prints anything, ask the user whether to stash, commit or continue on the current branch. Then `git checkout <default_branch>`, `git pull`, `git checkout -b <branch-name>`; the name is kebab-case English describing the change, with no tool or agent prefix unless the repo enforces one.

Fix the PR base branch now, before Step 5 adds commits, because merge-base detection gets unreliable afterwards. Step 9 passes it to `gh pr create --base`; `gh`'s own default always targets the default branch, which is wrong for a stacked branch.
- Branched off `<default_branch>` in this step -> the base is `<default_branch>`.
- Already on an existing branch and the caller said where it came from ("checked out from Y") -> use Y; whoever built the branch computed it once, which beats re-deriving it.
- Already on an existing branch and nobody said -> for every other local and remote branch `b`, keep those passing `git merge-base --is-ancestor b HEAD`; the one with the smallest `git rev-list --count b..HEAD` is the parent. The parent is `<default_branch>` (or its `origin/` mirror) -> base is `<default_branch>`; it is another unmerged branch -> that branch is the base (stacked PR), because using the default branch would put the predecessor's commits in this PR's diff.

## Step 3 - Identify the input mode

**Mode A - `$ARGUMENTS` is a plan path** (`plans/<slug>/`, `plan.md`, `phase-XX-*.md`):
1. Read the whole plan and its phase files, then the code areas it references (Step 1 delegation applies).
2. Check the code still matches the plan's assumptions: files at the stated paths, APIs and patterns as described, dependencies unchanged. If `plan.md`'s `Generated against commit` stamp differs from HEAD, re-verify the PASS cases' file:line references first.
3. Mismatch -> stop, show the mismatch with a proposed adjustment, and wait. Do not deviate from the plan on your own.

**Mode B - a description or an existing diff:** decide the scope from it and name the branch after the change if Step 2 has not.

## Step 4 - Tests first

For every new or changed function or endpoint with API or backend logic:
1. List the existing tests touching that code (grep test files, follow imports).
2. Write tests for the happy path and the edge cases (null, empty, zero, negative, boundary, concurrent).
3. Run them and confirm they fail before you implement; a test that passes immediately proves nothing, so rewrite it. Note the failing output in the checklist item (long output goes to `{work_context}/plans/reports/vcook-test-log-<HHMMSS>.md`).

Pure UI work (style or layout only, no business logic) may skip test-first; state "pure UI, skipping test-first" in the checklist.

## Step 5 - Implement

- Follow the plan (Mode A) or the description (Mode B).
- When both backend and frontend are affected, implement both; a backend change the UI does not reflect is unfinished.

## Step 6 - Use the generated API client

- Client-side API calls go through the generated SDK, because raw `fetch` or `axios` bypasses the typed contract that regeneration keeps in sync.
- Find the SDK: a `sdk:generate`, `api:generate` or `codegen` script in `package.json`, or a `generated/`, `__generated__/` or `sdk/` directory.
- A new route without a response schema -> add the schema to the shared schema package, run the generate command, then write the frontend code.
- No SDK layer exists -> use the project's existing API client (still not raw fetch) or ask the user.

## Step 7 - Review against CLAUDE.md

- Apply the rules of the project and user `CLAUDE.md` while coding.
- Before committing, check the final diff against those rules in full (subagents per independent file group, Step 1). This check is the review; add a separate reviewer subagent only when the change is large or risky.

## Step 8 - Verify

- Run the full test suite of every touched package, not only the related tests, plus typecheck and lint when the project has them. Report the coverage delta if the repo tracks coverage.
- On failure fix the root cause and re-run until everything passes. Do not skip, weaken or mock tests to get green.
- If the change is reachable over HTTP or CLI, call it once for real and include the actual output in the report. If that needs a server that is not running, do not start one; ask the user to start it or report "not exercised" with the reason.
- If no test, typecheck or run command can be executed here, say so in the report and mark the change unverified.

## Step 9 - Commit and open the PR

Resolve the VCS profile first (`repo-profile.md` §2; if the file is absent assume GitHub with `gh`).

**Commit:** English conventional message (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`), one commit per logical group. With more than 5 commits consider squashing related ones. Print `git log --oneline <base>..HEAD` before pushing so the user sees the final list.

**PR:**
- The caller said "commit only, no PR" (for example a pipeline that opens one PR for many tasks) -> commit, then stop: no push, no PR, no issue edit.
- Follow `.github/pull_request_template.md` exactly when it exists, otherwise Summary / Changes / Test plan. Title in English, concise.
- Description language: `repo-profile.md` §4. Write it for non-engineers: user and business impact, no code jargon.
- Full gh mode -> `gh pr create --base <base from Step 2>`. Degraded or local-only -> push the branch, print the §2 vcook message and the composed title and body for the user to paste. Compose the body in both modes.
- Linked issue (from the plan or `--issue`): put `Closes #<issue>` at the top of the PR body; in full gh mode also append the PR link to the issue body with `gh issue edit`, otherwise tell the user to add it by hand.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
