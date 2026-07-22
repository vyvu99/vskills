---
name: vspecs
description: "Create and update a specs file for a feature through an iterative loop: read the codebase → brainstorm edge cases → ask the user → update the file. Supports comparison with other products."
user-invocable: true
when_to_use: "Invoke when you want to create new specs or add to existing specs for a feature."
category: docs
keywords: [specs, feature, brainstorm, edge-cases, documentation]
argument-hint: "Feature: [feature name]\nCompare: [product name] (optional)"
extends: brainstorm
metadata:
  author: vyvu
  version: "1.0.0"
---

# Specs Loop

> Extends the underlying `brainstorm` skill — inherits all its principles (YAGNI/KISS/DRY, brutal honesty, explore alternatives, challenge assumptions). The difference: the final output is a specs file, not a design doc.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — use `AskUserQuestion` to ask:
- What feature do you want to write specs for?
- Compare against any product? (leave blank = no comparison)

---

## Step 1 — Reconnaissance (run in parallel)

1. Derive `[feature-slug]` from the feature name (kebab-case, English)
2. Check whether `plans/specs/[feature-slug].md` already exists
3. Scout the codebase for code related to this feature (routes, services, schemas, UI, seed data)
4. Read all of `plans/specs/` to learn existing decisions and avoid contradictions
5. If a Compare product was given: use `WebSearch` to research that product on the web (docs, help center, reviews, community forums, video demos) — only record what you directly observed, never infer from memory; if no Compare product was given → skip this step

## Step 2 — Classify and suggest

Based on the reconnaissance results, determine the situation and suggest an action:

| Situation | Suggestion |
|---|---|
| Feature doesn't exist yet + specs don't exist yet | Create a new specs file from the template, leave unknown parts blank, list open questions at the end of the file |
| Feature doesn't exist yet + specs already exist | Read the current specs → report what's complete / missing / contradictory → ask the user what to do next |
| Feature already exists + specs don't exist yet | Reverse-engineer specs from the code, create the specs file, clearly mark parts inferred from code vs. parts that remain uncertain |
| Feature already exists + specs already exist | Compare the specs against the code → list matches / discrepancies / behavior in the code not covered by the specs → ask the user which direction to sync toward |

**Stop and wait for the user's confirmation before continuing.**

---

## Step 3 — Edge case brainstorm loop

Once the user confirms, start the loop. Each round:

1. Re-read `plans/specs/[feature-slug].md` (in full)
2. Re-read the related code to understand current behavior
3. Personally verify anything unclear against the code — **never write "needs verification" or "unclear" or "possibly"** if the code exists and can be read; if you genuinely searched and found nothing → state clearly "searched, not found" + an alternative way to verify
4. Present at most **5 cases**, ordered by importance

**Format for each case:**

**[Type-Number]** _(e.g. UI-1, UX-2, FLOW-3, DATA-4)_
- **Priority:** P0 (blocks launch) / P1 (important) / P2 (nice-to-have)
- **Situation:** Describe in plain language — understandable by a non-technical reader
- **Impact:** What this case helps with when handled correctly; the consequence of ignoring it
- **Current:** What the system currently does — plain language, no code
- **Gap:** The concrete difference between current behavior and expectation (or the Compare product)
- **[Product name] handles it as:** _(only present when comparing — only record what was directly observed on the web; if not found → "not found on the web" + an alternative way to verify)_
- **Proposal:** 1-2 concrete directions, in plain language

After each round of 5 cases:
- Stop and wait for the user to decide on each case
- Update the specs file directly (Decisions, Edge Cases) — no recap, no explaining the change
- Ask: continue or not?

---

## Step 4 — Experience Specs

Only do this after the user confirms there are no more edge cases to cover. Add a single section at the end of the specs file:

```
### Experience Specs

- **What the user sees:** Describe the concrete UI for each state
- **What the user does:** Step by step actions
- **Feedback:** What the user sees immediately after each action
- **States:** What each data state looks like on screen (e.g. pending, completed, error, etc.)
- **Mobile vs Desktop:** Differences, if any
```

---

## Template for a new specs file

When a new file is needed:

```md
# [Feature name] — Feature Spec Draft

---

## Decisions

| #  | Case | Decision |
| -- | ---- | ----------- |

---

## Edge Cases

(to be added later)

---

## Experience Specs

(to be added later)

---

## Open Questions

1. ...
```

---

## Hard rules

- **Language:** plain Vietnamese — no technical jargon, no code snippets in the specs; understandable by non-technical readers
- If a technical concept must be mentioned → explain it immediately afterward in plain language, in parentheses
- **No comparison** → drop the Compare field, focus on the gap between current code and expectation
- **Verify before asking:** only ask a question when the code can't answer it — if the code already makes it clear, write it straight into Decisions
- Don't write "needs verification" unless you actually searched and couldn't find it
- Always pair a problem with a proposed solution, don't just state the issue
- No recap, no explaining the change after updating the file
- No timestamps, no version numbers in the specs content

## Next steps

Once the specs file is done (no open edge cases left), tell the user what fits the situation:
- Specs are for a feature that still needs building → suggest `/vplan <specs-file>` to turn it into an implementation plan.
- User only wanted documentation, nothing to build right now → just confirm the file is saved, nothing further needed.
- New edge cases come up later → re-run `/vspecs` on the same file to keep iterating.
