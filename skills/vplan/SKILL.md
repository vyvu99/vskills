---
name: vplan
description: "Create an implementation plan from an existing specs file: read specs + scout the codebase → compare case by case (PASS/FAIL/MISSING) → add missing baseline cases → generate plan.md + phase files, phases grouped by case, migrations consolidated into the first phase."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Invoke when you already have a specs file (created by vspecs, in the form plans/specs/<feature-slug>.md) and want to build an implementation plan from it."
category: workflow
keywords: [plan, specs, implementation, phases, migration, gap-analysis]
extends: plan
metadata:
  author: vyvu
  version: "1.0.0"
---

> Extends the underlying `plan` skill — inherits the entire base workflow (mode detection, plan.md + phase-XX-*.md structure, red-team, validate, task hydration, post-plan handoff). The difference: the input must be an existing specs file, and before generating the plan you must run a comparison step (gap analysis) between the specs and the current code to know exactly what needs to change.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — use `AskUserQuestion` to ask for the path to the specs file (default suggestion: `plans/specs/<feature-slug>.md`).

If the path doesn't exist → report the error and stop. **Do not create the specs yourself** — that's the job of `/vspecs`.

---

## Step 1 — Read specs + Scout the codebase (before anything else)

1. Read the ENTIRE specified specs file — Decisions table, Edge Cases, Experience Specs.
2. Scout the codebase relevant to this feature BEFORE analyzing: routes, services, schemas, UI components, seed data, existing migration files.
3. Read other files in `plans/specs/` (if any) to avoid conflicts with specs of related features.
4. Determine the `[feature-slug]` (from the specs file name or feature name, kebab-case).

---

## Step 2 — Compare each case: specs vs code

For EVERY case in the specs (each row of the Decisions table, each Edge Case) — **verify it yourself by reading the code**, don't guess:

**Format for each case:**

**[Case ID]** _(keep the ID/name exactly as in the specs)_
- **Status:** PASS / FAIL / MISSING
  - PASS — current code already behaves as the specs require
  - FAIL — current code behaves differently/incorrectly compared to the specs
  - MISSING — current code hasn't implemented this case yet
- **Specs requirement:** 1-line summary
- **Current code:** file:line + description of actual behavior (only fill in once you've read the code; if FAIL/MISSING and you haven't found it yet — keep searching, don't leave it vaguely blank)
- **Proposed fix:** (only for FAIL/MISSING) — which file to change, what logic changes specifically

A PASS case only needs a 1-line confirmation (file:line), no proposed fix needed.

---

## Step 3 — Add missing baseline cases

Using edge-case thinking similar to vspecs (empty/null input, concurrency, permissions, quantity limits, network/API errors, intermediate states...) but **without asking the user about each case again** — this is the planning stage, not specs brainstorming. Propose the case + status directly (MISSING by default, unless the code already handles it) + a specific fix, and add it to the case list from Step 2 with the note `(added beyond specs)`.

---

## Step 4 — Generate the plan

Follow the exact structure of the overview `plan.md` + detailed `phase-XX-*.md` per the canonical template of the underlying `plan` skill (frontmatter phase/title/status/priority/effort/dependencies; sections Overview/Requirements/Architecture/Related Code Files/Implementation Steps/Success Criteria/Risk Assessment).

**Differences from the default `plan`:**

1. **Phases are split by RELATED CASE GROUPS** (not by file/layer). Example: "Phase 2: Validate cart item quantity" groups every case related to quantity limits, even if those cases touch different routes + services + UI.
2. Each entry in a phase's Implementation Steps MUST spell out 3 parts, no vagueness allowed:
   - **File:** the specific path
   - **Logic:** exactly what changes (don't write generic "update logic" — must state the exact condition/branch/field being changed)
   - **Validate:** which test case covers it (if a test framework exists in the repo) or a specific manual verification step (which API to call, which UI to check, which DB field to check)
3. **Migration constraint (MANDATORY):** if any case (including cases added in Step 3) requires a database schema change → ALL related migrations must be consolidated into a single **first Phase**. Do not create separate migrations in phase 2, 3, etc. If a later phase needs an additional schema change discovered while writing the plan → go back and update Phase 1, don't split off a new migration phase.
4. At the top of `plan.md`, add a **"Case Summary"** section — a table summarizing every case from Step 2 + Step 3, each row: Case ID | Status (PASS/FAIL/MISSING) | Handling Phase (phase number, or "—" if PASS and nothing needs to change).

After finishing plan.md + phase files: continue with the exact Post-Plan Handoff of the underlying `plan` skill — use `AskUserQuestion` to offer running the validate/red-team gate of `plan`, implementing right away with `vcook <plan-path>`, or ending the session.

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.

---

## Hard rules

- Never write "needs verification", "unclear", "possibly" for any case if the code can be read and answer that question — you must read the code yourself before concluding a status.
- If you genuinely searched and found no related code → state clearly "searched at {path/pattern}, not found" instead of leaving it blank.
- Migrations must be consolidated into a single Phase 1 — no exceptions, no separate migration files in other phases.
- Every entry in Implementation Steps must have complete, specific File + Logic + Validate — never write generic phrases like "fix it properly" or "test again".
- Never create or edit the specs file yourself — if you find the specs are missing an important case that requires a user decision (something that can't be inferred from the code), stop and suggest running `/vspecs` to add it before continuing.
- Never skip Step 1 (scout the codebase) even if a case looks simple — a PASS/FAIL/MISSING status is only valid once you've actually read the real code.
