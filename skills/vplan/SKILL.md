---
name: vplan
description: "Turns an existing specs file (plans/specs/<feature-slug>.md, made by vspecs) into an implementation plan: compares every spec case with the current code as PASS, FAIL or MISSING, then writes plan.md and phase files grouped by case. Does not write specs and does not change code."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Use when a vspecs specs file exists and the user wants a plan, a gap analysis of specs against code, or phases to feed vcook."
metadata:
  author: vyvu
  version: "2.0.0"
---

The input is an existing specs file. Compare it with the current code before planning, so the plan covers exactly what has to change.

Read the input:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask with `AskUserQuestion` for the specs path (suggest `plans/specs/<feature-slug>.md`). If the path does not exist, report it and stop; creating specs is `/vspecs`'s job, not this skill's.

**Scope:** this skill writes only `plans/<feature-slug>/plan.md` and its phase files. It does not edit the specs file or any source code.

## Step 1 - Read the specs and scout the code

1. Read the whole specs file: Decisions, Edge Cases, Experience Specs.
2. Scout the code for the feature before judging anything: routes, services, schemas, UI components, seed data, existing migrations. Delegate the scouting to a subagent only when it spans many areas; a few files you read yourself. A subagent's brief states the feature, the areas to cover, that it is read-only, and the report file it writes under `plans/reports/` (`_vskills-shared/repo-profile.md` §6); read that file back.
3. Read the other files in `plans/specs/` to avoid conflicting with related features.
4. Derive `[feature-slug]` (kebab-case) from the file name or feature name.

## Step 2 - Compare each case with the code

Verify every case (each Decisions row and each Edge Case) by reading the code yourself; a verdict from memory is not valid. Create `plans/<feature-slug>/plan.md` at the start of this step and append each case's row to its Case Summary table as soon as the verdict is known, leaving Handling Phase and Effort blank until Step 4.

Per case, keep the specs' ID and name:
- **Status:** PASS (code already behaves as specified), FAIL (code behaves differently) or MISSING (not implemented).
- **Specs requirement:** one line.
- **Current code:** file:line and the actual behavior. For FAIL or MISSING keep searching until found; if the search truly finds nothing, write "searched at {path/pattern}, not found" (§8).
- **Proposed fix:** only for FAIL and MISSING: which file changes and what logic changes.

A PASS case needs only a one-line confirmation with file:line.

## Step 3 - Add missing baseline cases

Think through the usual gaps (empty or null input, concurrency, permissions, limits, network or API errors, intermediate states) without asking the user, because this is planning and not specs brainstorming. Add at most 5 such cases, each with a status (MISSING unless the code already handles it), a specific fix and the note `(added beyond specs)`. The cap keeps the plan from growing past what the user approved; more gaps than that go in the handoff message as a suggestion to run `/vspecs`.

## Step 4 - Generate the plan

Write `plan.md` and one `phase-XX-*.md` per phase. The Case Summary table already exists from Step 2; fill in the Phases table, Key Dependencies, Risks / Rollback, each phase file and the Handling Phase and Effort columns.

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

The commit stamp tells a reader, or `vcook` running the plan later, how stale the file:line references may be; `vcook` re-verifies PASS cases when the stamp differs from HEAD.

**Rules beyond the skeleton:**

1. Split phases by related case group, not by file or layer. "Validate cart item quantity" is one phase even when it touches several routes, services and UI.
2. Every Implementation Step has all three parts, because a vague step forces the implementer to guess:
   - **File:** the exact path.
   - **Logic:** the exact condition, branch or field that changes, never "update logic".
   - **Validate:** with a test framework, the specific test (existing or new), failing before the change and passing after; without one, a concrete command or step and the exact observation that confirms success, never "check the UI".
3. Migrations go in the first phase, so every later phase builds on a finished schema. Give a migration its own phase only when it is independent (no shared table or key) of Phase 1's migrations, and say why. A later phase that needs another schema change means going back to update Phase 1.
4. Case Summary covers every case from Steps 2 and 3: Case ID, Status, Handling Phase (a phase number, or "—" for a PASS needing no change) and Effort (the phase's `effort` value, "—" for PASS). Effort is a coarse S/M/L bucket, never hours or a promised date.
5. Phase status lives only in the `plan.md` Phases table, so it cannot drift from a copy in the phase files. Fill Risks / Rollback for every phase: the state left if it fails partway and how to undo it.

## Step 5 - Cross-check the plan

Before handoff, check and fix anything that fails:
1. Every Case ID from Steps 2 and 3 appears exactly once in the Case Summary.
2. Every FAIL or MISSING case has a Handling Phase.
3. Every phase traces to at least one case; a phase tracing to none is possible scope creep.

If the specs lack a case that needs a user decision (not inferable from code), stop and suggest `/vspecs` to add it.

Then offer with `AskUserQuestion`: (a) implement now with `vcook <plan-path>`, (b) create GitHub tracking issues first with `vtickets <plan-dir>`, or (c) end the session.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
