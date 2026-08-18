---
phase: 2
title: Wire mechanical skills
status: completed
priority: P2
effort: 2h
dependencies:
  - 1
blockedBy:
  - 1
---

# Phase 2: Wire mechanical skills

## Overview

Wire the 4 skills whose hardcoding is shallow — a command prefix, a `gh` call, one framework-specific component name. Each edit swaps a hardcoded assumption for a pointer to a `repo-profile.md` section plus an inline fallback. 8 files (4 × `SKILL.md` + `SKILL.vi.md`).

**Blocked by phase 1** — the §1/§2/§3 section numbers must exist before they can be cited.
Runs in parallel with phase 3 (disjoint files).

**Cross-cutting rule (from plan.md):** every pointer is soft — *"read `~/.claude/skills/_vskills-shared/repo-profile.md` §N if present; if it isn't, assume `<today's hardcoded default>`."* A stand-alone copy of the skill keeps working.

**Vietnamese variants:** `SKILL.vi.md` is a straight translation of `SKILL.md` in each skill dir. Every step below applies the same structural change to the `.vi.md` file with the prose in Vietnamese; the file path in the pointer, the section numbers, and all command templates stay identical (they are code, not prose).

## Requirements

**Functional**
1. `vcheck` runs on npm/yarn/bun and on single-package repos (no `--filter`).
2. `vissues`, `vrules`, `vdesign` never hard-fail when `gh` is absent or the remote isn't GitHub — one `⚠️`, manual instructions, then continue.
3. `vdesign` stops prescribing `next/image` outside Next.js.
4. `vrules` stops carrying its own owner/repo parse.

**Non-functional**
- Diffs stay small: pointer + fallback, never a copy of the detection logic. If a phase-2 file grows by more than ~15 lines, the logic belongs in `repo-profile.md` instead.
- Author-facing behavior (Case A) byte-identical.

## Architecture

```
repo-profile §1 ──> vcheck   Step 0 (workspace shape), Step 1/2 (command prefix), Step 3 (format script)
repo-profile §2 ──> vissues  Step 2/3   (gh issue, gh api graphql)
              ├──> vrules   Step 2      (owner/repo parse + gh pr view/api)
              └──> vdesign  Phase 0 §3  (--pr → gh pr diff)
repo-profile §3 ──> vdesign  "Images & Media" checklist item
```

Runtime flow per skill: skill start → read repo-profile → resolve profile → substitute into templates → run. No new state, no new files.

## Related code files

**Modify (8)**
- `skills/vcheck/SKILL.md` + `skills/vcheck/SKILL.vi.md`
- `skills/vissues/SKILL.md` + `skills/vissues/SKILL.vi.md`
- `skills/vrules/SKILL.md` + `skills/vrules/SKILL.vi.md`
- `skills/vdesign/SKILL.md` + `skills/vdesign/SKILL.vi.md`
- (small) `README.md` line 16 + `README.vi.md` equivalent row — see step 5

**Create / delete** — none.

**Explicitly out of scope:** `skills/vdesign/SKILL.md:308` "Constraints for eTARO" — already path-gated on `/Users/vyvu/Documents/work/taro/eTARO`, i.e. it is the *correct* pattern (opt-in by location, inert elsewhere), not lock-in. Do not touch it.

## Implementation Steps

### Step 1 — vcheck: package manager + workspace shape

**File:** `skills/vcheck/SKILL.md` (then mirror into `SKILL.vi.md`)

**Logic — 4 edits:**

1. **New block after the `$ARGUMENTS` fence (after line 22, before `## Step 0`)**, titled `## Step -1 — Resolve the repo profile`: read `~/.claude/skills/_vskills-shared/repo-profile.md` §1 → resolve `pm` + `workspace?` + the script names. Fallback line: *if the file is absent, assume pnpm + workspace (`pnpm --filter <pkg> exec …`)*. If §1 reports "not a JS/TS project", stop the skill with one line saying so — vcheck has nothing to do there.

2. **Step 0, line 30** — currently: *"Read the `packages:` field in `pnpm-workspace.yaml` (or the `workspaces` field in the root `package.json` if that file doesn't exist)"*. Replace with: use the workspace shape from §1; **single-package → the package list is just the root package**, skip glob resolution and go to Step 1. Keep lines 31-33 (glob resolve → read child `package.json` name → keep only packages with a `build` script and/or `tsconfig.json`) unchanged.

3. **Step 1, line 40** — replace the literal
   `pnpm --filter <package> exec tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &`
   with the §1 template form: `<pm workspace-exec template> <typecheck cmd> > /tmp/tsc-<package>.log 2>&1 &`, plus a worked line under it showing the pnpm+workspace resolution reproducing exactly the old string, and one showing npm single-package (`npm exec -- tsc --noEmit > …`). `<typecheck cmd>` comes from §1 script resolution (`typecheck` → `type-check` → `tsc --noEmit`). Leave the background-`&` + `wait` mechanics and the "recheck only the fixed package" rule untouched.

4. **Step 2, line 54** — same treatment for `pnpm --filter <package> build`, using the §1 template + the `build` script. Note in one line: a package with no `build` script is skipped, not run with a raw fallback.

5. **Step 3, line 61** — already reads the root `package.json` scripts, keep it, just add "run it via the §1 root template" so npm/yarn users get `npm exec -- …`/`yarn …` instead of a bare `pnpm`.

6. **Frontmatter** — line 3 `description` and line 6 `when_to_use` say "in a pnpm monorepo"; line 8 `keywords` lists `pnpm`. Change to "JS/TS repo (monorepo or single package)"; keep `pnpm` in keywords and add `npm, yarn, bun` (keywords are for discovery, wider is better).

**Validate.** Re-read the file: `grep -n "pnpm --filter" skills/vcheck/SKILL.md` returns only the worked *example* lines, not the normative command. Walk Case A: pnpm + `pnpm-workspace.yaml` → step 1 renders `pnpm --filter @app/api exec tsc --noEmit` — identical to the pre-change line 40. Walk Case B: npm, no workspaces → `npm exec -- tsc --noEmit`, no `--filter` anywhere, package list = root only.

### Step 2 — vissues: gh availability

**File:** `skills/vissues/SKILL.md` (then `SKILL.vi.md`)

**Logic — 2 edits:**

1. **New block after line 24 (the "ask for the plan path" line), before `## Step 1`**, titled `## Step 0 — Resolve the VCS profile`: read `repo-profile.md` §2. Full gh mode → continue as written. Degraded/local-only → print the §2 vissues message (`addSubIssue` is GitHub-specific), then **still do Step 1 (read the plan) and Step 4 (compose issue bodies)** and print the epic + sub-issue bodies ready to paste, marking which sub-issue holds the migrations per Step 5. Explicitly: do not abort the run. Fallback if repo-profile is missing: assume GitHub + gh, i.e. today's behavior.

2. **Steps 2-3 (lines 33-74)** — leave every `gh` command as written; prepend one line to Step 2: "these commands assume full gh mode from Step 0; in degraded mode do the manual path instead." Where Step 2 point 5 (line 52) and Step 3 point 4 need `<owner>`/`<repo>` for the GraphQL query, cite §2's parse instead of leaving them undefined.

3. **Hard rules (lines 97-104)** — add one: *never abort because `gh` is unavailable; degrade per §2 and still deliver the issue bodies.*

**Validate.** Case A: `gh` authed + github.com → Step 0 resolves to full mode, Steps 2-3 execute the same `gh` commands as today, unchanged in content <!-- Updated: Validation Session 1 - "6 gh commands" replaced with "unchanged in content"; grep found 9 distinct gh invocations, not 6 -->. Case B: no `gh` → skill still reads the plan and prints paste-ready bodies; grep the file for any instruction to stop/exit on missing gh — must find none.

### Step 3 — vrules: dedupe owner/repo parse + degrade

**File:** `skills/vrules/SKILL.md` (then `SKILL.vi.md`)

**Logic:**

1. **Step 2, line 34** — currently *"You need to know `<owner>/<repo>` — infer it from `git remote get-url origin` in the current directory, and ask if it's unclear."* Replace with: resolve host + `<owner>/<repo>` per `repo-profile.md` §2 (single canonical parse). Keep "ask the user if it's unclear".

2. **Step 2, after the command fence (lines 36-40)** — add the degraded branch: not GitHub or no `gh` → print the §2 vrules message (`⚠️ can't fetch review comments — paste them and I'll continue from Step 3`) and continue from Step 3 with user-pasted comments. Step 1 (read `~/.claude/CLAUDE.md`) and Steps 3-5 need no host access at all, so the skill is still ~80% useful without `gh` — say that explicitly so the model doesn't bail.

3. **Hard rules (lines 72-78)** — add: *missing `gh` is a degrade, not a stop; the clustering/proposal steps run on pasted comments.*

**Validate.** Case A: unchanged — same three `gh` calls at lines 37-39. Case B: no `gh` → skill asks for pasted comments and completes Steps 3-5. Confirm `git remote get-url origin` no longer appears as its own parsing instruction (`grep -n "remote get-url" skills/vrules/SKILL.md` → only inside the §2 reference sentence, if at all).

### Step 4 — vdesign: gh degrade + framework-neutral image guidance

**File:** `skills/vdesign/SKILL.md` (then `SKILL.vi.md`)

**Logic — 3 edits:**

1. **Input mode table, line 39** (`| `--pr` | `gh pr diff` to get changed files → …`) — append: "requires gh (§2); unavailable → falls back to `--diff`".

2. **Phase 0 point 3, line 68** (`If there's `--pr` → `gh pr diff --name-only``) — add the degraded branch: no gh / non-GitHub → print the §2 vdesign message and ask the user for a branch name or fall back to `git diff --name-only` (the `--diff` mode at line 40, which needs no gh). Then continue into Phase 1 normally.

3. **"Images & Media" checklist, line 216** (`- [ ] `next/image` with `fill` + container with an explicit size — no layout shift`) — rewrite framework-neutral, keeping the *rule* (explicitly sized container, no layout shift) and making the component name conditional on §3: Next.js → `next/image` with `fill`; Nuxt → `NuxtImg`; Astro → `astro:assets` `<Image>`; generic → the project's own image component, with explicit width/height or an aspect-ratio container; ask the user if none is discoverable. Add a one-line note that the same §3 conditionality applies to any other framework-specific API named in this checklist.

**Validate.** Case A: Next.js repo → the checklist item resolves to the original `next/image` + `fill` wording; `--pr` still runs `gh pr diff --name-only`. Case B: Vite/React-Router + no gh → `--pr` degrades to `git diff --name-only` with a warning, and the image item names the project's image component, not `next/image`. Confirm `grep -n "eTARO" skills/vdesign/SKILL.md` still shows the untouched section at ~308.

### Step 5 — README wording follow-up

**Files:** `README.md` line 16 (`| `vcheck` | Typecheck + build in parallel across a pnpm monorepo | …`) and line 73 (`→ typecheck + build every package in the workspace in parallel …`), plus the matching rows in `README.vi.md`.

**Logic.** Line 16: "across a pnpm monorepo" → "across a JS/TS workspace (any package manager)". Line 73 already says "workspace", leave it. Two-word inline patch; no new README section.

**Validate.** Re-read both rows; skills table still renders (pipe count unchanged).

## Todo list

- [x] vcheck: Step -1 profile block + Steps 0/1/2/3 templated + frontmatter
- [x] vcheck `.vi.md` mirrored
- [x] vissues: Step 0 + degrade path + hard rule
- [x] vissues `.vi.md` mirrored
- [x] vrules: §2 parse + degrade from Step 3 + hard rule
- [x] vrules `.vi.md` mirrored
- [x] vdesign: line 39/68 gh degrade + line 216 framework-neutral
- [x] vdesign `.vi.md` mirrored
- [x] README.md + README.vi.md vcheck row
- [x] Case A / Case B walkthrough for all 4 skills

## Success Criteria

- [x] Case A, all 4 skills: rendered commands byte-identical to the pre-change literals (`pnpm --filter <pkg> exec tsc --noEmit`, `pnpm --filter <pkg> build`, every `vissues` gh call unchanged <!-- Updated: Validation Session 1 - "all 6" replaced, actual count is 9 -->, `vrules` 3 gh calls, `gh pr diff --name-only`, `next/image` + `fill`)
- [x] Case B, all 4 skills: complete their run with a `⚠️` line and manual instructions — none instructs an abort
- [x] No detection logic duplicated: `grep -rn "packageManager\|pnpm-lock\|gh auth status" skills/vcheck skills/vissues skills/vrules skills/vdesign` returns nothing (all of it lives in `_vskills-shared`)
- [x] Each of the 8 skill files grew by ≤ ~15 lines
- [x] Each `.vi.md` has the same section/step structure as its `.md` (same step count, same fences)
- [x] `skills/vdesign/SKILL.md` "Constraints for eTARO" unchanged
- [x] `./install.sh --dry-run` and `--lang=vi --dry-run` still clean

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Templated vcheck command renders differently from today's pnpm literal → author's daily check breaks | Medium | **High** | Worked pnpm example kept inline next to the template; Case A byte-identical check is a blocking criterion |
| `.vi.md` drifts from `.md` (edited one, forgot the other) → `--lang=vi` users get the old hardcoded behavior | **High** (8 files, mechanical) | Medium | Per-skill todo pairs each `.md` with its `.vi.md`; structural-parity criterion above |
| Degrade text turns into "stop and ask the user" in practice | Medium | Medium | Every degrade branch spells out "then continue with <next step>"; success criterion greps for abort instructions |
| Skill files bloat with re-explained detection | Medium | Low | ≤15-line growth cap; anything longer moves into `repo-profile.md` |
| vdesign framework list becomes a maintenance burden | Low | Low | Only 3 named frameworks + a generic branch; generic branch asks the user rather than enumerating more |
| Merge conflict with phase 3 | Low | Low | Disjoint ownership (plan.md table); only README is shared — patch different rows |

## Security considerations

No new attack surface: all changes are markdown, and detection is read-only. One carry-over from §2 — degraded-mode messages must name the remote *host*, never echo the full remote URL, which can embed credentials.

## Next steps

Independent of phase 3; either can land first. After both, a one-pass read of all 6 skills to confirm consistent phrasing of the pointer line is worthwhile (cosmetic, not blocking).
