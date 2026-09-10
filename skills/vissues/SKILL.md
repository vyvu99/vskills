---
name: vissues
description: "Create/update a GitHub epic issue + sub-issues from 1 plan directory, using gh CLI + REST sub_issues API (GraphQL addSubIssue as fallback). Issue content is non-technical, migrations are consolidated into the sub-issue containing phase 1's content. Idempotent — re-running does not create duplicates."
argument-hint: "<plan-path>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Invoke when you need to create or sync a GitHub epic + sub-issues from an existing plan (plan.md + phase-XX-*.md)."
metadata:
  author: vyvu
  version: "1.1.0"
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

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (if present; if absent, assume GitHub + gh — today's default). Full gh mode → continue as written below. Degraded/local-only → print the §2 vissues message (sub-issue linking — REST `sub_issues` and its GraphQL `addSubIssue` fallback alike — is GitHub's own API, no equivalent elsewhere), then still do Step 1 (read the plan) and Step 4 (compose issue content), and print the epic + sub-issue bodies ready to paste — marking which sub-issue holds the migrations per Step 5. Never abort the run because `gh` is unavailable.

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
5. Get the epic's node ID — only needed for the GraphQL fallback in Step 3, not for the REST path (`<owner>`/`<repo>` resolved per §2):
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<epic_number>
   ```

## Step 3 — Create/update sub-issues

1. Group the plan's phases into sub-issues by area of work — **DO NOT** create one sub-issue per small phase; related phases (same layer, same feature slice) should be merged into a single sub-issue. Avoid creating too many issues. Derive each sub-issue's title **deterministically** from the phase numbers/area it covers (e.g. a fixed template such as `<Area name> (Phase N-M)`) — not free-form phrasing that can vary between runs, so the dedupe search in step 2 reliably matches the same title on a re-run.
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
4. Before linking any sub-issue, fetch the epic's current sub-issues **once per skill invocation** (REST, `<owner>`/`<repo>` per §2) — cache this list and reuse it for every sub-issue's already-linked check below AND for the count check, don't re-fetch per sub-issue:
   ```
   gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues --paginate --jq '.[].id'
   ```
   - If this call fails outright → do not assume the epic has 0 sub-issues. Warn the user explicitly that the current count/links couldn't be verified, and ask whether to proceed before linking anything.
   - If it succeeds → count check: if the list already has 100 or more entries (GitHub's documented per-parent limit — reconfirm live if this skill is revisited later, don't trust a stale number), **STOP** and tell the user the epic is at GitHub's sub-issue limit; they must close/reorganize existing sub-issues before adding more. Do this once for the whole run, not per sub-issue.
5. For each sub-issue to link (found or newly created in step 3):
   a. Fetch its numeric `id` — **NOT** `number`, **NOT** node ID:
      ```
      gh api repos/<owner>/<repo>/issues/<sub_issue_number> --jq .id
      ```
   b. If that numeric id is already in the cached list from step 4 → already linked to this epic from a previous run, **skip silently** — this is the expected, common outcome on every re-run, not an error.
   c. Otherwise, attempt REST linking (this also covers moving a sub-issue that currently belongs to a different parent, via `replace_parent`):
      ```
      gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues -F sub_issue_id=<numeric_id> -F replace_parent=true
      ```
      - **201** → linked, done for this sub-issue.
      - **401/403** (permission/auth error) → **STOP** and report the exact error to the user directly — do **NOT** fall back to GraphQL; the same token/permission problem will very likely also break the GraphQL mutation, so a silent fallback would mask a token-scope misconfiguration instead of surfacing it.
      - **Any other failure** (404, 410, 422, network error, etc.) → fall back to GraphQL: look up both node IDs, then call `addSubIssue` with `replaceParent: true`:
        ```
        gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<sub_issue_number>
        ```
        ```
        gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!,$replaceParent:Boolean){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId,replaceParent:$replaceParent}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id> -F replaceParent=true
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

If the plan includes database changes → put ALL migration-related content into **the sub-issue containing phase 1's content** (not necessarily the first sub-issue created — Step 3.1 groups by area of work, not phase order). DO NOT scatter migration content across multiple sub-issues.

---

## Hard rules

- Always search before creating (`gh issue list --search`) — avoid duplicate epic/sub-issues when re-running the skill
- REST `sub_issues` is the primary linking path; fetch the epic's sub-issues list once per run (cached) and skip linking a sub-issue whose numeric `id` is already in that list — this is the idempotent no-op, never a REST failure requiring fallback
- Only fall back to the GraphQL `addSubIssue` mutation (with `replaceParent: true`) on a genuine non-permission REST failure; on a 401/403 from REST, stop and report it to the user directly — never silently fall back
- Never link a sub-issue when the epic's cached sub-issue count is already ≥ 100 (GitHub's per-parent limit) — stop and tell the user to close/reorganize existing sub-issues first; if the count-fetch itself fails, warn the user and ask before proceeding, don't assume 0
- Issue language must always be non-technical — no code jargon, no file/function/DB table names
- Migrations always go into the sub-issue containing phase 1's content, never scattered across multiple sub-issues
- Never create a new label (`epic` or otherwise) without confirming with the user first
- Merge related small phases into 1 sub-issue — don't create one issue per phase
- Never abort because `gh` is unavailable or the remote isn't GitHub — degrade per §2 and still deliver the issue bodies

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
