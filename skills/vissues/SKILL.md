---
name: vissues
description: "Create/update a GitHub epic issue + sub-issues from 1 plan directory, using gh CLI + GraphQL addSubIssue. Issue content is non-technical, migrations are consolidated into sub-issue 1. Idempotent — re-running does not create duplicates."
argument-hint: "<plan-path>"
user-invocable: true
when_to_use: "Invoke when you need to create or sync a GitHub epic + sub-issues from an existing plan (plan.md + phase-XX-*.md)."
category: workflow
keywords: [github, issues, epic, sub-issues, graphql]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vissues

Create or sync a GitHub epic issue + sub-issues from a plan directory, using the `gh` CLI. Idempotent — running it a second time updates instead of creating duplicates.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — ask the user for the path to the plan directory (e.g. `plans/<slug>/`).

---

## Step 0 — Resolve the VCS profile

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (if present; if absent, assume GitHub + gh — today's default). Full gh mode → continue as written below. Degraded/local-only → print the §2 vissues message (`addSubIssue` is GitHub's own GraphQL mutation, no equivalent elsewhere), then still do Step 1 (read the plan) and Step 4 (compose issue content), and print the epic + sub-issue bodies ready to paste — marking which sub-issue holds the migrations per Step 5. Never abort the run because `gh` is unavailable.

## Step 1 — Read the plan

- Read `<plan-path>/plan.md` + ALL relevant `<plan-path>/phase-XX-*.md` files
- Understand the full scope: feature name, the phases, and which phase touches database/migration

## Step 2 — Find/create the Epic issue

These commands assume full gh mode from Step 0; in degraded mode, follow the manual path from Step 0 instead.

1. Search for an existing issue matching this plan:
   ```
   gh issue list --search "<keyword from plan name>" --state all --json number,title,url,labels
   ```
2. If a highly similar issue title is found → use it as the epic, **DO NOT create a new one**
3. If not found → check whether the `epic` label already exists in the repo:
   ```
   gh label list
   ```
   - Label `epic` exists → create the issue with `--label epic`
   - Doesn't exist → **STOP, ask the user** whether to create the new label (never create a label without confirmation)
4. Create the new epic:
   ```
   gh issue create --title "<feature name, in English>" --body "<epic description, see Step 4>" --label epic
   ```
5. Get the epic's node ID (required before linking sub-issues in Step 3; `<owner>`/`<repo>` resolved per §2):
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<epic_number>
   ```

## Step 3 — Create/update sub-issues

1. Group the plan's phases into sub-issues by area of work — **DO NOT** create one sub-issue per small phase; related phases (same layer, same feature slice) should be merged into a single sub-issue. Avoid creating too many issues.
2. For EACH sub-issue you plan to create — search first to avoid duplicates when the skill is re-run (update mode):
   ```
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
3. If it already exists → update its content according to the matching phase:
   ```
   gh issue edit <number> --body "<new content>"
   ```
   If it doesn't exist → create a new one:
   ```
   gh issue create --title "<title, in English>" --body "<content, see Step 4>"
   ```
4. Get the sub-issue's node ID (GraphQL query similar to Step 2, swap in `<number>`; `<owner>`/`<repo>` per §2)
5. Link it to the epic — **IMPORTANT: only call addSubIssue for NEWLY CREATED sub-issues or ones NOT YET linked**, skip this step for sub-issues already linked from a previous run:
   ```
   gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id>
   ```

## Step 4 — Issue content (both epic and sub-issues follow this format)

Plain, non-technical language — no file names, function names, DB table names, or variable names. Focus on the problem the end user faces + the desired outcome.

```md
## Current problem
<description of the problem/gap the user is experiencing>

## Desired outcome
<after this is done, what can the user do / what experience do they get>

## Scope
<brief — what's in, what's out>
```

## Step 5 — Migration constraint

If the plan includes database changes → put ALL migration-related content into the **first sub-issue** (corresponding to phase 1 of the plan). DO NOT scatter migration content across multiple sub-issues.

---

## Hard rules

- Always search before creating (`gh issue list --search`) — avoid duplicate epic/sub-issues when re-running the skill
- Always get the node ID via a GraphQL query BEFORE calling `addSubIssue` — the mutation needs a global ID (base64 string), not the issue number
- Issue language must always be non-technical — no code jargon, no file/function/DB table names
- Migrations always go into sub-issue 1, never scattered across multiple sub-issues
- Never create a new label (`epic` or otherwise) without confirming with the user first
- Merge related small phases into 1 sub-issue — don't create one issue per phase
- Never abort because `gh` is unavailable or the remote isn't GitHub — degrade per §2 and still deliver the issue bodies

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
