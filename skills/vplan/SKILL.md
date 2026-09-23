---
name: vplan
description: "Create an implementation plan from an existing specs file: read specs + scout the codebase → compare case by case (PASS/FAIL/MISSING) → add missing baseline cases → generate plan.md + phase files, phases grouped by case, migrations consolidated into the first phase."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Invoke when you already have a specs file (created by vspecs, in the form plans/specs/<feature-slug>.md) and want to build an implementation plan from it."
metadata:
  author: vyvu
  version: "1.0.0"
---

> The input must be an existing specs file, and before generating the plan you must run a comparison step (gap analysis) between the specs and the current code to know exactly what needs to change.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — use `AskUserQuestion` to ask for the path to the specs file (default suggestion: `plans/specs/<feature-slug>.md`).

If the path doesn't exist → report the error and stop. **Do not create the specs yourself** — that's the job of `/vspecs`.

---

## Step 1 — Read specs + Scout the codebase (before anything else)

1. Read the ENTIRE specified specs file — Decisions table, Edge Cases, Experience Specs.
2. Scout the codebase relevant to this feature BEFORE analyzing: routes, services, schemas, UI components, seed data, existing migration files. Scouting delegated to a subagent → its findings write to `plans/reports/` per `_vskills-shared/repo-profile.md` §6.
3. Read other files in `plans/specs/` (if any) to avoid conflicts with related features' specs.
4. Determine the `[feature-slug]` (from the specs file name or feature name, kebab-case).

---

## Step 2 — Compare each case: specs vs code

For EVERY case in the specs (each row of the Decisions table, each Edge Case) — **verify it yourself by reading the code**, don't guess:

As each case's PASS/FAIL/MISSING verdict is determined, append its row directly to a `plan.md` Case Summary table under construction (create the file at the start of Step 2 if it doesn't exist yet) rather than holding the full comparison in conversation memory until Step 4. Leave Handling Phase / Effort blank for now — Step 4 fills those in once phases are assigned.

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

Generate the overview `plan.md` + one detailed `phase-XX-*.md` per phase, using the literal skeletons below. The Case Summary table was already started during Step 2 — this step fills in the Phases table, Key Dependencies, Risks/Rollback, and each phase file, plus the Handling Phase / Effort columns left blank in Step 2.

**`plan.md` skeleton:**

```markdown
# <Feature Name> — Implementation Plan

**Generated against commit:** <short-sha>  <!-- from `git rev-parse --short HEAD` at generation time -->

## Case Summary

| Case ID | Status | Handling Phase | Effort |
|---|---|---|---|
| <id> | PASS / FAIL / MISSING | phase-N or "—" | S/M/L or "—" |

## Phases

| Phase | Title | Status | Dependencies |
|---|---|---|---|
| Phase 1 | <title> | pending | — |
| Phase 2 | <title> | pending | Phase 1 |

## Key Dependencies

- <cross-phase or external dependency>

## Risks / Rollback

### Phase 1
- **If it fails partway:** <state left behind — code/DB>
- **Rollback:** <how to undo>
```

**`phase-XX-*.md` skeleton:**

```markdown
---
phase: 1
title: "<phase title>"
status: pending
priority: high | medium | low
effort: S | M | L
dependencies: []
---

## Overview
<1-2 sentences: what this phase does and why>

## Requirements
- <functional/non-functional requirement>

## Architecture
<component interactions, data flow relevant to this phase>

## Related Code Files
- <file to modify/create/delete>

## Implementation Steps
1. **File:** <path>
   **Logic:** <exact condition/branch/field changed>
   **Validate:** <specific test name (red→green), or manual verify command + expected result>

## Success Criteria
- <definition of done>

## Risk Assessment
- <potential issue + mitigation>
```

The `**Generated against commit:**` stamp exists so a reader (or `vcook` running the plan later) can tell how stale the plan's file:line references might be. `vcook` should treat a mismatch between this stamp and current HEAD as a signal to re-verify PASS cases before trusting them, not assume they still hold.

**Rules beyond the skeleton:**

1. **Phases are split by RELATED CASE GROUPS** (not by file/layer). Example: "Phase 2: Validate cart item quantity" groups every case related to quantity limits, even across different routes + services + UI.
2. Each entry in a phase's Implementation Steps MUST spell out 3 parts, no vagueness allowed:
   - **File:** the specific path
   - **Logic:** exactly what changes (never generic "update logic" — state the exact condition/branch/field being changed)
   - **Validate:** test framework exists in the repo → name the specific test (existing or new), state it must fail before the change (red) and pass after (green); no test framework → a specific manual verify command/step with the expected observation stated explicitly (not "check the UI" — the exact result confirming success)
3. **Migration grouping:** migrations go into a single **first Phase** by default. Split one into its own case's phase only when genuinely independent (no shared table/key) from Phase 1's other migrations — state that independence explicitly. A later phase needs an additional, non-independent schema change discovered while writing the plan → go back and update Phase 1, don't split off a new migration phase.
4. At the top of `plan.md`, the **"Case Summary"** table summarizes every case from Step 2 + Step 3: Case ID | Status (PASS/FAIL/MISSING) | Handling Phase (phase number, or "—" if PASS and nothing needs to change) | Effort (the handling phase's `effort` frontmatter value; "—" for PASS rows). Effort is a rough relative-sizing estimate, not calibrated — a coarse bucket (S/M/L), never a false-precision hour count or a promised timeline.
5. Fill in `## Risks / Rollback` for every phase, not just Phase 1 — state what state (code/DB) is left behind if that phase fails partway through, and how to roll it back.

---

## Step 5 — Cross-check the plan

After generating plan.md + phase files, before handoff, verify:

1. Every Case ID from Step 2 + Step 3 appears exactly once in the Case Summary table.
2. Every FAIL/MISSING case has a Handling Phase.
3. Every phase traces back to at least one case in the Case Summary — a phase tracing to none is flagged as possible scope creep.

Fix plan.md/phase files for any failing check before proceeding.

Then hand off — use `AskUserQuestion` to offer: (a) implement now via `vcook <plan-path>`, (b) create GitHub tracking issues first via `vtickets <plan-dir>`, or (c) end the session.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.

---

## Hard rules

- See `_vskills-shared/repo-profile.md` §8 (Verification honesty rule).
- Genuinely searched and found no related code → state clearly "searched at {path/pattern}, not found" instead of leaving it blank.
- Migrations go into a single Phase 1 by default — only split one into its own phase when genuinely independent (no shared table/key) from Phase 1's other migrations, and say so explicitly.
- Every entry in Implementation Steps must have complete, specific File + Logic + Validate — never generic phrases like "fix it properly" or "test again".
- Never create or edit the specs file yourself — specs missing an important case that requires a user decision (not inferrable from code) → stop, suggest running `/vspecs` to add it before continuing.
- Never skip Step 1 (scout the codebase) even for a simple-looking case — a PASS/FAIL/MISSING status is only valid once you've actually read the real code.
