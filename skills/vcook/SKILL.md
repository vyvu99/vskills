---
name: vcook
description: "Mandatory 9-step checklist when implementing a feature/fix: parallel subagents → determine branch → identify plan/no-plan mode → write tests first → implement BE+FE fully → mandatory use of generated SDK client → review against CLAUDE.md → test until passing → squash commits + create PR from template. Do NOT skip any step."
argument-hint: "[plan-path | task description] [--issue <number>]"
user-invocable: true
when_to_use: "Invoke to implement a feature/fix from an existing plan or a quick description — auto-creates the branch, writes tests, codes, reviews, runs tests, commits, and creates a PR."
category: workflow
keywords: [cook, implement, workflow, plan, sdk, commit, pr]
extends: cook
metadata:
  author: vyvu
  version: "1.0.0"
---

First, invoke the `cook` skill (Skill tool, exact name, no prefix) to run the underlying implementation workflow. After that, you are a senior engineer applying the mandatory 9-step checklist below on top of it. Do NOT skip any step.

**BEFORE YOU START:** Create a 9-step checklist with `TodoWrite` (one item per step). After finishing each step → mark it `completed` before moving to the next. Do NOT mark completed before the work is actually done.

═══════════════════════════════════════════════════════
STEP 1: PARALLELIZE INTO SUBAGENTS
═══════════════════════════════════════════════════════

Before doing each step below, evaluate which parts are independent → delegate them to subagents running in parallel within the SAME message (not sequential if there's no dependency). Apply this throughout, not just once at the start:
- Reading the plan + reading related codebase (step 3) → parallel subagents
- Researching patterns/docs for the libraries in use → parallel subagents
- Reviewing against CLAUDE.md (step 7) across multiple independent files → parallel subagents

Purpose: reduce main-agent token usage — the main agent only synthesizes results.

═══════════════════════════════════════════════════════
STEP 2: DETERMINE THE BRANCH
═══════════════════════════════════════════════════════

1. Check the current branch: if its name/content already matches the task at hand (the user is intentionally continuing on that branch) → SKIP the branch-creation step, use the current branch.
2. If it doesn't match:
   - Auto-detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'` → if empty, try `git rev-parse --verify main 2>/dev/null` → use `main`; if `main` doesn't exist → use `master`.
   - `git checkout <default_branch>` → `git pull` → `git checkout -b <descriptive-branch-name>`
   - Branch name: kebab-case, English, accurately describing the scope of change (no tool/agent-based prefix unless the repo enforces its own convention).

═══════════════════════════════════════════════════════
STEP 3: IDENTIFY THE INPUT MODE
═══════════════════════════════════════════════════════

Input is one of 2 forms — auto-detect from `$ARGUMENTS`:

**Mode A — Has a plan path** (e.g.: `plans/<slug>/`, `plan.md`, `phase-XX-*.md`):
1. Read the entire plan + related phase files.
2. Read the codebase areas the plan references carefully (use parallel subagents per step 1).
3. Cross-check: does the current codebase match the plan's assumptions? (files still exist at the right path, patterns/APIs still match what the plan describes, dependencies haven't changed...)
4. If there's a MISMATCH → STOP, present the specific mismatch + a proposed adjustment to the user BEFORE coding. Do NOT deviate from the plan without asking.
5. If it matches → proceed to step 4.

**Mode B — No plan** (quick description, or a diff that already exists — "PR out of nowhere"):
1. Skip the plan-reading step.
2. Determine scope yourself from the description/existing diff.
3. Name the branch (if not already done in step 2) to match the observed nature of the changes.

═══════════════════════════════════════════════════════
STEP 4: WRITE TEST CASES + EDGE CASES BEFORE CODING
═══════════════════════════════════════════════════════

- **Mandatory** for API/backend logic: for every new or modified function/endpoint, list the test cases BEFORE writing the implementation — happy path + edge cases (null/undefined/empty/0/negative/boundary/concurrent).
- **Not mandatory** for pure UI (style/layout only, no business logic). If skipped → state the reason clearly in the checklist ("pure UI, skipping test-first").

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
- Auto-detect whether an SDK exists:
  - grep `package.json` for a `sdk:generate` / `api:generate` / `codegen` script
  - or look for a `generated/`, `__generated__/`, `sdk/` directory, or a pattern characteristic of Fern/openapi-generator/orval
- New BE route returning `void`/missing a response schema → add the response schema to the shared schema package FIRST, then run the generate command you found (at minimum map it on the BE if FE doesn't need it right away).
- No generate script/SDK directory found → the project has no separate SDK layer, use the project's existing API client (still NO raw fetch/axios directly) or ask the user if unclear.

═══════════════════════════════════════════════════════
STEP 7: REVIEW AGAINST CLAUDE.md
═══════════════════════════════════════════════════════

- Read `~/.claude/CLAUDE.md` (if not already familiar), apply relevant rules yourself AS YOU code (TypeScript, Styling, Form Fields, Backend, Frontend, File & Folder Structure...) — don't wait for a separate review pass to fix it.
- Before committing → double-check the final diff against the rules (parallel subagents if multiple independent files).
- No need for a separate review by another subagent if it was done right from the start.

═══════════════════════════════════════════════════════
STEP 8: RUN TESTS, FIX UNTIL PASSING
═══════════════════════════════════════════════════════

- Run the relevant test suite (unit/integration per project convention).
- On failure → fix the root cause (don't patch the symptom) → re-run.
- Repeat until 100% pass. Do NOT skip failing tests to commit faster, do NOT use mocks/fake data/tricks to fake a pass.

═══════════════════════════════════════════════════════
STEP 9: COMMIT + CREATE PR
═══════════════════════════════════════════════════════

**Commit:**
- English message, conventional commit format (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`).
- Squash into a reasonable number of commits grouped by logical change — do NOT create many small, scattered commits.

**PR:**
- Read the project's `.github/pull_request_template.md` (if it exists) → the PR body MUST follow that template exactly. If it doesn't exist → use a sensible default format (Summary / Changes / Test plan).
- Title: English, concise.
- Description: **written in Vietnamese**, non-technical — for readers who aren't engineers, focused on user/business impact, no code jargon.
- If there's a related GitHub issue (from the plan or provided by the user as an issue number):
  - Add `Closes #<issue>` at the TOP of the PR body
  - `gh issue edit <issue>` to append a link to the PR at the END of the issue body

---

## Hard rules

- **Do NOT skip any step** of the 9 — even when the task looks "simple"
- **Codebase diverges from the plan** → stop, present the mismatch + a proposal, wait for user confirmation. ABSOLUTELY do NOT deviate from the plan without asking
- **Test failure** → fix the root cause until 100% pass, do NOT commit while tests are failing, do NOT mock/fake to dodge tests
- **Commit** → squash sensibly by logical change, do NOT spam many small commits
- **Client-side API calls** → ALWAYS use the generated SDK, raw fetch/axios FORBIDDEN; missing response schema → add the schema + regenerate the SDK before writing FE code
- **Scope** → stick strictly to the plan/description's scope; further improvements → propose them, don't expand scope unilaterally
- **PR description** → in Vietnamese, non-technical, following `.github/pull_request_template.md` exactly if it exists
- **Test-first** → mandatory for API/backend logic, not mandatory for pure UI (must state the reason clearly when skipped)

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
