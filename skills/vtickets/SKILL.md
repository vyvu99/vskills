---
name: vtickets
description: "Create/update a GitHub epic issue + sub-issues from 1 plan directory, using gh CLI + REST sub_issues API (GraphQL addSubIssue as fallback). Issue content is non-technical, migrations are consolidated into the sub-issue containing phase 1's content. Idempotent — re-running does not create duplicates."
argument-hint: "<plan-path>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Invoke when you need to create or sync a GitHub epic + sub-issues from an existing plan (plan.md + phase-XX-*.md)."
metadata:
  author: vyvu
  version: "1.2.0"
---

# vtickets

Create or sync a GitHub epic issue + sub-issues from a plan directory, using the `gh` CLI. Idempotent — re-running updates instead of duplicating.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — ask the user for the path to the plan directory (e.g. `plans/<slug>/`).

---

## Step 0 — Resolve the VCS profile

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (absent → assume GitHub + gh, today's default). Full gh mode → continue as written below. Degraded/local-only → print the §2 vtickets message (sub-issue linking — REST `sub_issues` and its GraphQL `addSubIssue` fallback alike — is GitHub's own API, no equivalent elsewhere), then still do Step 1 (read the plan) and Step 4 (compose issue content), and print the epic + sub-issue bodies ready to paste — marking which sub-issue holds the migrations per Step 5. Never abort the run because `gh` is unavailable.

## Step 1 — Read the plan

- Read `<plan-path>/plan.md` + ALL relevant `<plan-path>/phase-XX-*.md` files
- Understand the full scope: feature name, the phases, and which phase touches database/migration

## Step 2 — Find/create the Epic issue

These commands assume full gh mode from Step 0; in degraded mode, follow the manual path from Step 0 instead.

Discover the epic through this fallback chain, cheapest and most reliable check first — stop at the first hit:

1. **Local cache** (fastest, same-machine only) — `<plan-path>/issues.md` exists → read the epic row from it, use that issue number directly.
2. **Marker search** (survives a fresh clone on a different machine) — every epic this skill creates embeds a hidden marker `<!-- vplan: <plan-slug> -->` in its body (see step 5 below), where `<plan-slug>` is the plan directory's basename in kebab-case (same slug convention used elsewhere in this pack, e.g. `[feature-slug]` in vspecs/vplan). Search for it, then confirm an exact match — GitHub's search is fuzzy/tokenized, treat a hit as a candidate only, not proof:
   ```
   gh issue list --search "\"vplan: <plan-slug>\" in:body" --state all --json number,title,url,body
   ```
   Grep each candidate's `body` for the exact string `<!-- vplan: <plan-slug> -->` before trusting it as the epic.
3. **Title search** (last resort — epics created before the marker existed, or a body that was edited and lost it):
   ```
   gh issue list --search "<keyword from plan name>" --state all --json number,title,url,labels
   ```
   Highly similar issue title found → use it as the epic, **DO NOT create a new one**.
4. None of the above found anything → check whether the `epic` label already exists in the repo:
   ```
   gh label list
   ```
   - Exists → create the issue with `--label epic`
   - Doesn't exist → **STOP, ask the user** whether to create the new label (never create a label without confirmation)
5. Create the new epic — embed the marker as the first line of the body, above the Step 4 content:
   ```
   gh issue create --title "<feature name, in English>" --body "<!-- vplan: <plan-slug> -->

   <epic description, see Step 4>" --label epic
   ```
6. Get the epic's node ID — only needed for the GraphQL fallback in Step 3, not for the REST path (`<owner>`/`<repo>` resolved per §2):
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<epic_number>
   ```

## Step 3 — Create/update sub-issues

1. Group the plan's phases into sub-issues by area of work — **DO NOT** create one sub-issue per small phase; merge related phases (same layer, same feature slice) into a single sub-issue. Avoid creating too many issues. Derive each sub-issue's title **deterministically** from the phase numbers/area it covers (e.g. a fixed template such as `<Area name> (Phase N-M)`) — not free-form phrasing that varies between runs, so the dedupe check in step 3 reliably matches the same title on a re-run.
2. Before creating/updating or linking any sub-issue, fetch the epic's current sub-issues **once per skill invocation** (REST, `<owner>`/`<repo>` per §2) — cache this list (`id`, `number`, `title`) and reuse it for the creation dedup check in step 3, the already-linked check in step 5, AND the count check, don't re-fetch per sub-issue:
   ```
   gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues --paginate --jq '.[] | {id,number,title}'
   ```
   - Call fails outright → do not assume the epic has 0 sub-issues. Warn the user explicitly the current count/links couldn't be verified, ask whether to proceed before linking anything.
   - Succeeds → count check: list already has 100+ entries (GitHub's documented per-parent limit — reconfirm live if this skill is revisited later, don't trust a stale number) → **STOP**, tell the user the epic is at GitHub's sub-issue limit; they must close/reorganize existing sub-issues first. Once for the whole run, not per sub-issue.
3. For EACH sub-issue you plan to create — dedupe against the cached list from step 2 first, by exact title match: a cached entry whose title matches means it already exists, reuse its `number`. Only when the epic has no matching sub-issue in that cached list, fall back to a repo-wide title search (title-based, can miss GitHub's title normalization or special characters):
   ```
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
4. If it already exists (from either lookup in step 3) → update its content according to the matching phase:
   ```
   gh issue edit <number> --body "<new content>"
   ```
   If it doesn't exist → create a new one:
   ```
   gh issue create --title "<title, in English>" --body "<content, see Step 4>"
   ```
5. For each sub-issue to link (found or newly created in step 4):
   a. Fetch its numeric `id` — **NOT** `number`, **NOT** node ID:
      ```
      gh api repos/<owner>/<repo>/issues/<sub_issue_number> --jq .id
      ```
   b. That numeric id already in the cached list from step 2 → already linked to this epic from a previous run, **skip silently** — expected, common outcome on every re-run, not an error.
   c. Otherwise, attempt REST linking (this also covers moving a sub-issue that currently belongs to a different parent, via `replace_parent`):
      ```
      gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues -F sub_issue_id=<numeric_id> -F replace_parent=true
      ```
      - **201** → linked, done for this sub-issue.
      - **401/403** (permission/auth error) → **STOP** and report the exact error to the user directly — do **NOT** fall back to GraphQL; the same token/permission problem very likely also breaks the GraphQL mutation, so a silent fallback would mask a token-scope misconfiguration instead of surfacing it.
      - **Any other failure** (404, 410, 422, network error, etc.) → fall back to GraphQL: look up both node IDs, then call `addSubIssue` with `replaceParent: true`:
        ```
        gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<sub_issue_number>
        ```
        ```
        gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!,$replaceParent:Boolean){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId,replaceParent:$replaceParent}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id> -F replaceParent=true
        ```
6. Optional — milestone/labels: ask the user once (via `AskUserQuestion`) whether to assign a milestone per phase and/or labels per area of work to the sub-issues touched this run. Yes:
   ```
   gh issue edit <number> --milestone "<milestone>" --add-label "<label>"
   ```
   Declines → skip silently, don't ask again per sub-issue.

## Step 4 — Issue content (both epic and sub-issues follow this format)

Plain, non-technical language — no file names, function names, DB table names, or variable names. Focus on the problem the end user faces + the desired outcome. Body language: resolve per `repo-profile.md` §4 (same resolution vcook uses for the PR body) — title stays English regardless (Step 2/3), only the body content follows the resolved language.

```md
## Current problem
<description of the problem/gap the user is experiencing>

## Desired outcome
<after this is done, what can the user do / what experience do they get>

## Scope
<brief — what's in, what's out>
```

(The epic's body additionally starts with the hidden `<!-- vplan: <plan-slug> -->` marker from Step 2.5 — sub-issue bodies don't carry it.)

## Step 5 — Migration constraint

Plan includes database changes → put ALL migration-related content into **the sub-issue containing phase 1's content** (not necessarily the first sub-issue created — Step 3.1 groups by area of work, not phase order). DO NOT scatter migration content across multiple sub-issues.

## Step 6 — Final links table

At the end of the run, print a table of every issue touched this run (epic + all sub-issues, created or updated):

```
| # | title | url | parent |
|---|---|---|---|
```

Also save this same table to `<plan-path>/issues.md`, so a future re-run of this skill on the same plan reads it directly instead of re-searching GitHub.

Epic/sub-issue discovery and linking (Steps 2-3) are idempotent and re-derive state from GitHub + `issues.md` on every run, so an interrupted run recovers by simply re-running `/vtickets <plan-path>` on the same plan directory — no separate recovery procedure needed.

---

## Hard rules

- Always check the epic's cached sub-issues list first for sub-issue creation dedup (step 3), falling back to `gh issue list --search` only when the epic has no matching title; for the epic itself, always run the full discovery chain first — `issues.md` cache → hidden `<!-- vplan: <plan-slug> -->` marker search → title search — before creating, to avoid duplicate epic/sub-issues on re-run (including from a fresh clone on another machine)
- REST `sub_issues` is the primary linking path; fetch the epic's sub-issues list once per run (cached), skip linking a sub-issue whose numeric `id` is already in that list — the idempotent no-op, never a REST failure requiring fallback
- GitHub's `sub_issues_summary`/`subIssuesSummary` field (progress badge on Project boards/issue lists) can go stale — a known GitHub bug, not a sign your linking failed; the issue's live `sub_issues` REST list (or GraphQL equivalent) is always the authoritative source, never the badge
- Status pin (as of 2026-09-11): GitHub's `sub_issues` REST API and the `addSubIssue` GraphQL mutation are confirmed GA, not beta/preview (GA announced 2025-03-17). Point-in-time snapshot, not a future guarantee — reconfirm live (per the 100-item-limit note in step 3.2) if this skill is revisited later and something looks off
- Only fall back to GraphQL `addSubIssue` (with `replaceParent: true`) on a genuine non-permission REST failure; a 401/403 from REST → stop, report it to the user directly, never silently fall back
- Never link a sub-issue when the epic's cached sub-issue count is already ≥ 100 (GitHub's per-parent limit) — stop, tell the user to close/reorganize existing sub-issues first; count-fetch itself fails → warn and ask before proceeding, don't assume 0
- Issue language always non-technical — no code jargon, no file/function/DB table names
- Migrations always go into the sub-issue containing phase 1's content, never scattered across multiple sub-issues
- Never create a new label (`epic` or otherwise) without confirming with the user first
- Merge related small phases into 1 sub-issue — don't create one issue per phase
- Never abort because `gh` is unavailable or the remote isn't GitHub — degrade per §2, still deliver the issue bodies

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
