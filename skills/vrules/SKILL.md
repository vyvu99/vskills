---
name: vrules
description: "Analyze Claude bot's review comments on a PR, cross-check them against existing rules in ~/.claude/CLAUDE.md, and propose new rules to fill the gaps — helping CLAUDE.md self-improve based on real review patterns."
argument-hint: "<PR-number>"
user-invocable: true
when_to_use: "Invoke after Claude bot has finished reviewing a PR, when you want to distill recurring patterns into new rules for CLAUDE.md."
category: meta
keywords: [claude-md, rules, pr-review, self-improvement]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vrules

Distill new rules for `~/.claude/CLAUDE.md` from recurring patterns in Claude bot's review comments on a PR — a self-improvement loop for the global rule file.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — ask the user which PR number to analyze.

---

## Step 1 — Extract existing rules

Read the ENTIRE `~/.claude/CLAUDE.md`. Extract every rule/bullet into a numbered list (keeping the original section, e.g. `[Backend-12]`, `[TypeScript-3]`) — to be used for cross-checking in Step 3. Do not summarize or paraphrase the rule content.

## Step 2 — Fetch Claude bot's review comments

You need to know `<owner>/<repo>` — infer it from `git remote get-url origin` in the current directory, and ask if it's unclear.

```bash
gh pr view <PR-number> --json comments,reviews
gh api repos/<owner>/<repo>/pulls/<PR-number>/comments
gh api repos/<owner>/<repo>/pulls/<PR-number>/reviews
```

Filter by author being the automated review bot (usually suffixed `[bot]` or a custom-configured app name). If you're not sure of the exact bot account name → ask the user before filtering, don't guess.

## Step 3 — Cluster patterns

Group comments by recurring issue type (e.g. missing null check, N+1 query, leftover console.log, missing loading state) — do NOT list individual comments one by one.

For each pattern, count its occurrences in this PR.

Cross-check each pattern against the rule list from Step 1:
- **Already clearly covered by an existing rule** → skip, note "already covered by [section-number]" so the user knows that rule is working as intended
- **Not covered yet, or the existing rule is too narrow** → this is a gap, move to Step 4

## Step 4 — Propose new rules

For each gap:
- Write the rule as GENERIC AS POSSIBLE — don't describe it in terms of this PR's specific case (e.g. NOT "don't forget the null check in getUserById" but "any function receiving input from a DB/external API → must check null/undefined before accessing a field")
- State clearly which section of the existing CLAUDE.md it should go into (Backend, Frontend, TypeScript, Styling, Form Fields, ...) — don't create a new section if the rule fits an existing one
- Include the occurrence count in this PR (so the user can judge whether the pattern deserves to become a general rule — see Hard Rules)

Present the full set of proposals to the user, **ask for confirmation on each rule before patching** — never auto-edit CLAUDE.md without approval.

## Step 5 — Patch (only after user approval)

Patch CLAUDE.md following the Document Updates rule already defined in that same file:
- Patch inline into the relevant section
- Do NOT add a new "Fixed" / "Changelog" / "Update" section at the end of the file
- Don't keep version history, don't record dates in the rule content

---

## Hard Rules

- **Always ask for confirmation** before patching CLAUDE.md — never edit unilaterally even if the user has approved the general direction; each rule must be approved individually
- Proposed rules **MUST be generic**, not tied to the specific case of the PR being analyzed
- Only patterns that repeat **≥2 times** within the PR qualify to be proposed as a general rule — a single occurrence is an edge case and should not be auto-proposed as a rule; if there's only 1 occurrence, state the count clearly and let the user decide whether to add it
- Never guess the bot account name if unsure — ask the user
- Don't dump raw comments into the output — only present the clustered patterns
