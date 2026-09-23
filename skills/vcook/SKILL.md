---
name: vcook
description: "Mandatory 9-step checklist when implementing a feature/fix: parallel subagents → determine branch → identify plan/no-plan mode → write tests first → implement BE+FE fully → mandatory use of generated SDK client → review against CLAUDE.md → test until passing → squash commits + create PR from template. Do NOT skip any step."
argument-hint: "[plan-path | task description] [--issue <number>]"
user-invocable: true
disable-model-invocation: true
when_to_use: "Invoke to implement a feature/fix from an existing plan or a quick description — auto-creates the branch, writes tests, codes, reviews, runs tests, commits, and creates a PR."
metadata:
  author: vyvu
  version: "1.1.0"
---

You are a senior engineer implementing this task end-to-end via the mandatory 9-step checklist below. Do NOT skip any step.

**BEFORE YOU START:** Create a 9-step checklist with `TodoWrite` (one item per step). After finishing each step → mark it `completed` before moving to the next. Do NOT mark completed before the work is actually done. Exception: Step 1 is a standing rule applied across every other step, not a one-time task — keep it `in_progress` until Step 9 completes.

If this session is interrupted, resume by reading TodoWrite's step statuses + `git status`/`git diff` against the branch created in Step 2 + (Mode A) the plan file — reconstruct which of steps 2-9 are actually done from real repo state; code state is the source of truth, not a stale TodoWrite status.

═══════════════════════════════════════════════════════
STEP 1: PARALLELIZE READ-ONLY WORK INTO SUBAGENTS
═══════════════════════════════════════════════════════

Before each step below, evaluate which parts are independent → delegate to subagents running in parallel within the SAME message (not sequential if there's no dependency). Apply throughout, not just once at the start:
- Reading the plan + related codebase (step 3) → parallel subagents
- Researching patterns/docs for the libraries in use → parallel subagents
- Reviewing against CLAUDE.md (step 7) across multiple independent files → parallel subagents

Scope: subagents here are READ-ONLY (research, reading plan/codebase, reviewing against CLAUDE.md). Implementation code-writing (step 5) is NOT delegated — write the actual code yourself, sequentially, in this session. Purpose: reduce main-agent token usage — the main agent only synthesizes results.

Every subagent spawned under this step must write its findings to `{work_context}/plans/reports/<agent-type>-<HHMMSS>-<slug>.md` before replying, per `_vskills-shared/repo-profile.md` §6 — the orchestrator reads that file back to synthesize, not just the conversational reply. This keeps Step 1's repeated spawns safe across a long Step 1→9 session.

Genuinely parallel *implementation* work (multiple independent writers touching different files/features at once, not just parallel read-only research) → each writer uses its own git worktree to avoid working-tree collisions.

═══════════════════════════════════════════════════════
STEP 2: DETERMINE THE BRANCH
═══════════════════════════════════════════════════════

1. Check the current branch: name/content already matches the task at hand (user intentionally continuing on it) → SKIP branch creation, use the current branch.
2. Otherwise:
   - Auto-detect the default branch per `_vskills-shared/repo-profile.md` §9.
   - Run `git status --porcelain`; anything printed (working tree dirty) → STOP, ask the user (stash / commit / continue on the current branch) before proceeding.
   - `git checkout <default_branch>` → `git pull` → `git checkout -b <descriptive-branch-name>`
   - Branch name: kebab-case, English, accurately describing the scope of change (no tool/agent-based prefix unless the repo enforces its own convention).

═══════════════════════════════════════════════════════
STEP 3: IDENTIFY THE INPUT MODE
═══════════════════════════════════════════════════════

Input is one of 2 forms — auto-detect from `$ARGUMENTS`:

**Mode A — Has a plan path** (e.g.: `plans/<slug>/`, `plan.md`, `phase-XX-*.md`):
1. Read the entire plan + related phase files.
2. Read the codebase areas the plan references carefully (parallel subagents per step 1).
3. Cross-check: does the current codebase match the plan's assumptions (files still exist at the right path, patterns/APIs still match what the plan describes, dependencies haven't changed)?
4. MISMATCH → STOP, present the specific mismatch + a proposed adjustment BEFORE coding. Do NOT deviate from the plan without asking.
5. Matches → proceed to step 4.

**Mode B — No plan** (quick description, or an existing diff — "PR out of nowhere"):
1. Skip the plan-reading step.
2. Determine scope yourself from the description/existing diff.
3. Name the branch (if not already done in step 2) to match the observed nature of the changes.

═══════════════════════════════════════════════════════
STEP 4: WRITE TEST CASES + EDGE CASES BEFORE CODING
═══════════════════════════════════════════════════════

- **Mandatory** for API/backend logic: for every new or modified function/endpoint —
  1. List existing tests that touch the code about to change (grep test files / follow the import graph for the module).
  2. Write the new test covering happy path + edge cases (null/undefined/empty/0/negative/boundary/concurrent).
  3. Run it and confirm it FAILS before writing the implementation — paste the failing output into the TodoWrite item's note for Step 4 (long output → append to `{work_context}/plans/reports/vcook-test-log-<HHMMSS>.md`, link it from the note). A test that passes immediately is invalid — rewrite it.
- **Not mandatory** for pure UI (style/layout only, no business logic). Skipped → state the reason clearly in the checklist ("pure UI, skipping test-first").

═══════════════════════════════════════════════════════
STEP 5: IMPLEMENT
═══════════════════════════════════════════════════════

- Follow the plan exactly (Mode A) or the description (Mode B).
- If both BE and FE are affected → implement BOTH fully, don't leave BE done while the UI doesn't reflect it (FE/BE Balance).
- If you spot a fitting improvement while coding → propose it to the user, do NOT expand scope beyond the plan/description on your own.

═══════════════════════════════════════════════════════
STEP 6: GENERATED SDK/API CLIENT IS MANDATORY
═══════════════════════════════════════════════════════

- Every client/web-app-side API call → MUST use the generated SDK. Raw `fetch`/`axios` is FORBIDDEN.
- Auto-detect whether an SDK exists: grep `package.json` for a `sdk:generate` / `api:generate` / `codegen` script, or look for a `generated/`, `__generated__/`, `sdk/` directory, or a pattern characteristic of Fern/openapi-generator/orval.
- New BE route returning `void`/missing a response schema → add the response schema to the shared schema package FIRST, then run the generate command found (at minimum map it on the BE if FE doesn't need it right away).
- No generate script/SDK directory found → the project has no separate SDK layer; use the project's existing API client (still NO raw fetch/axios) or ask the user if unclear.

═══════════════════════════════════════════════════════
STEP 7: REVIEW AGAINST CLAUDE.md
═══════════════════════════════════════════════════════

- Read `~/.claude/CLAUDE.md` (if not already familiar), apply relevant rules yourself AS YOU code (TypeScript, Styling, Form Fields, Backend, Frontend, File & Folder Structure...) — reduces what the double-check below needs to catch, doesn't replace it.
- Before committing → always double-check the final diff against the rules in full (parallel subagents for multiple independent files) — mandatory regardless of how carefully you coded.
- That double-check is the review; skip only the EXTRA layer of a separate review subagent on top of it, when the code was done right from the start.

═══════════════════════════════════════════════════════
STEP 8: RUN TESTS, FIX UNTIL PASSING
═══════════════════════════════════════════════════════

- Run the FULL test suite of the package(s) touched (unit/integration per project convention) — not just tests "relevant" to the change. Repo tracks coverage → report the coverage delta.
- On failure → fix the root cause (don't patch the symptom) → re-run.
- Repeat until 100% pass. Do NOT skip failing tests to commit faster, do NOT use mocks/fake data/tricks to fake a pass.
- Once tests pass, if the change is reachable via HTTP/CLI → actually call it once (curl the new/changed endpoint, run the new/changed CLI command) and include the real output in the completion report — "tests pass" alone isn't sufficient verification.

═══════════════════════════════════════════════════════
STEP 9: COMMIT + CREATE PR
═══════════════════════════════════════════════════════

Resolve the VCS profile first: read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (fallback if the file is absent: assume GitHub + gh).

**Commit:**
- English message, conventional commit format (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`).
- One commit per logical group of changes. More than 5 commits → consider squashing related ones. Always print `git log --oneline <base>..HEAD` before pushing so the user sees the final commit list.

**PR:**
- Read the project's `.github/pull_request_template.md` (if it exists) → PR body MUST follow it exactly. Absent → sensible default format (Summary / Changes / Test plan).
- Title: English, concise.
- Description: in the project's communication language — `## Ngôn ngữ`/`## Language` section in the project's `CLAUDE.md`, then `~/.claude/CLAUDE.md`, else English (same resolution `repo-profile.md` §4 documents, doesn't require the file itself to be present) — non-technical, for readers who aren't engineers, focused on user/business impact, no code jargon.
- Full gh mode (per §2) → create the PR with `gh` as usual. Degraded/local-only → push the branch, print the §2 vcook message plus the fully composed title and body so the user pastes it into their host's UI — compose the body in both modes, never skip it.
- Related GitHub issue (from the plan or an issue number the user gave):
  - Add `Closes #<issue>` at the TOP of the PR body (plain text, works in both modes)
  - Full gh mode → `gh issue edit <issue>` to append a link to the PR at the END of the issue body. Degraded mode → print "add a link to the PR in issue #N manually" and continue.

---

## Hard rules

- **Do NOT skip any step** of the 9 — even when the task looks "simple"
- **Codebase diverges from the plan** → stop, present the mismatch + a proposal, wait for user confirmation. ABSOLUTELY do NOT deviate from the plan without asking
- **Test failure** → fix the root cause until 100% pass, do NOT commit while tests are failing, do NOT mock/fake to dodge tests
- **Commit** → one commit per logical group of changes; more than 5 → consider squashing related ones; always print `git log --oneline <base>..HEAD` before pushing
- **Client-side API calls** → ALWAYS use the generated SDK, raw fetch/axios FORBIDDEN; missing response schema → add the schema + regenerate the SDK before writing FE code
- **Scope** → stick strictly to the plan/description's scope; further improvements → propose them, don't expand scope unilaterally
- **PR description** → in the resolved language (project CLAUDE.md → global CLAUDE.md → English, per `repo-profile.md` §4), non-technical, following `.github/pull_request_template.md` exactly if it exists
- **Test-first** → mandatory for API/backend logic, not for pure UI (must state the reason clearly when skipped)

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
