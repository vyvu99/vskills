---
name: vtickets
description: "Creates or syncs a GitHub epic issue plus linked sub-issues from one plan directory (plan.md + phase-XX-*.md), using the gh CLI and the REST sub_issues API. Issue text is non-technical, migrations are consolidated into one sub-issue, and re-running updates instead of duplicating. Run it explicitly as /vtickets <plan-path>."
argument-hint: "<plan-path>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Use when the user wants an existing plan turned into a GitHub epic with sub-issues, or an already-created epic re-synced after the plan changed."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vtickets

Turns a plan directory into a GitHub epic with linked sub-issues. It creates and edits real issues, so it only runs when the user invokes it. Scope is the issues and `<plan-path>/issues.md`, with no code changes.

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the plan directory (e.g. `plans/<slug>/`).

## Step 0 — VCS profile

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §2; if it is missing, assume GitHub + gh. In full gh mode, continue below. In degraded or local-only mode, print the §2 vtickets message (sub-issue linking is GitHub's own API), do Steps 1 and 4 only, and print the epic and sub-issue bodies ready to paste, marking the migration sub-issue per Step 5. A missing `gh` never aborts the run.

## Step 1 — Read the plan

Read `<plan-path>/plan.md` and every `phase-XX-*.md`. Note the feature name, the phases, and which phase touches the database or migrations.

## Step 2 — Find or create the epic

Use the first hit of this chain, cheapest check first:

1. `<plan-path>/issues.md` exists: take the epic number from it (same machine only).
2. Marker search, which survives a fresh clone. Every epic created here carries `<!-- vplan: <plan-slug> -->` as the first body line, where `<plan-slug>` is the kebab-case basename of the plan directory. The marker keeps its historical `vplan` name because renaming it would orphan existing epics. GitHub search is fuzzy, so treat hits as candidates and confirm the exact string in each `body`:
   ```bash
   gh issue list --search "\"vplan: <plan-slug>\" in:body" --state all --json number,title,url,body
   ```
3. Title search, for epics that predate the marker or lost it when edited. A clearly matching title is the epic:
   ```bash
   gh issue list --search "<keyword from plan name>" --state all --json number,title,url,labels
   ```
4. Nothing found: check `gh label list`. If `epic` exists, create with `--label epic`. If not, ask the user before creating the label, since labels are shared repo state.
5. Create the epic. Issue bodies are multi-line text with quotes and backticks, so write the body (marker line first, then the Step 4 content) to a temp file and pass it with `--body-file`:
   ```bash
   gh issue create --title "<feature name, English>" --body-file <temp-file> --label epic
   ```

## Step 3 — Create, update and link sub-issues

1. Group phases into sub-issues by area of work (same layer or feature slice). One sub-issue per small phase makes noise. Title each one from a fixed template such as `<Area name> (Phase N-M)`, so the dedupe in item 3 matches the same title on every re-run.
2. Once per run, fetch the epic's current sub-issues and reuse the list for dedupe, the already-linked check and the limit check:
   ```bash
   gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues --paginate --jq '.[] | {id,number,title}'
   ```
   If the call fails, do not assume zero sub-issues; tell the user the links could not be verified and ask before linking anything. If the list already has 100 entries (GitHub's per-parent limit at time of writing), stop and tell the user to close or reorganize sub-issues first.
3. Dedupe each planned sub-issue by exact title against the cached list and reuse the match. Only if the epic has no match, search the repo by title (it can miss titles GitHub normalizes):
   ```bash
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
4. Existing: read its current body first; if it differs from the body planned this run, ask once (`AskUserQuestion`) before overwriting, since people edit issue bodies by hand, then update with `gh issue edit <number> --body-file <temp-file>`. New: `gh issue create --title "<title, English>" --body-file <temp-file>`.
5. Link each sub-issue (found or new):
   - Get its numeric `id` (not the number, not the node ID): `gh api repos/<owner>/<repo>/issues/<sub_issue_number> --jq .id`.
   - Id already in the cached list: already linked, skip silently. This is the normal outcome on a re-run.
   - Otherwise link with REST; `replace_parent` also moves a sub-issue from another parent:
     ```bash
     gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues -F sub_issue_id=<numeric_id> -F replace_parent=true
     ```
   - 201: linked. 401/403: stop and report the exact error, because GraphQL would fail the same way and a fallback would hide the token problem. Any other failure: follow `references/graphql-fallback.md`.
6. Ask once (`AskUserQuestion`) whether to set a milestone per phase and labels per area. Yes: `gh issue edit <number> --milestone "<milestone>" --add-label "<label>"`. No: do not ask again.

## Step 4 — Issue content

Epic and sub-issues use plain language with no file, function, table or variable names, since the readers are product people. Body language follows `repo-profile.md` §4; titles stay English. Sub-issue bodies have no marker.

```md
## Current problem
<the problem or gap the user experiences>

## Desired outcome
<what the user can do after this is done>

## Scope
<what is in, what is out>
```

## Step 5 — Migrations

If the plan changes the database, put all migration content in the one sub-issue that holds phase 1's content (not necessarily the first created, because Step 3 groups by area). Spreading it across sub-issues hides the ordering constraint.

## Step 6 — Verify and report

Re-fetch the epic's sub-issue list (the Step 3 call) and compare it with the sub-issues planned this run; the live list is authoritative, while the `sub_issues_summary` progress badge can lag. Report any missing link. Then print and save to `<plan-path>/issues.md` a table of every issue touched:

```
| # | title | url | parent |
|---|---|---|---|
```

An interrupted run recovers by re-running `/vtickets <plan-path>`, because discovery and linking re-derive state from GitHub and `issues.md`.

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
