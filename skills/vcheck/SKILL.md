---
name: vcheck
description: "Run typecheck + build (+ optional test) in parallel for all or part of the packages in a JS/TS repo (monorepo or single package). Auto-detects workspace packages and package manager, no hardcoded package names."
argument-hint: "[package-names...]"
user-invocable: true
when_to_use: "Invoke when you need a fast typecheck/build (and test) of the whole repo or a group of packages in a JS/TS monorepo (or single package) before commit/PR."
category: workflow
keywords: [typecheck, build, tsc, pnpm, npm, yarn, bun, monorepo, ci]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vcheck

Runs typecheck + build (+ optional test) in parallel for packages in a JS/TS repo (monorepo or single package), using background commands + `wait`. Generic — no hardcoded package names or package manager.

Read input from the user:

```
$ARGUMENTS
```

---

## Step -1 — Resolve the repo profile

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §1 (if present) to resolve the package manager (`pm`), workspace shape, and the typecheck/build/format script names. If the file is absent, assume pnpm + workspace (`pnpm --filter <pkg> exec …`) — today's default. If §1 reports "not a JS/TS project", stop here and say so — vcheck has nothing to do in a non-JS/TS repo.

## Step 0 — Determine the package list

- If `$ARGUMENTS` contains a list of package names → use that exact list, skip auto-detect
- If empty → auto-detect the whole workspace:
  1. Use the workspace shape from Step -1. **Single-package** → the package list is just the root package; skip glob resolution, go straight to Step 1. **Monorepo** → continue with the glob pattern from `pnpm-workspace.yaml` (or the `workspaces` field in the root `package.json`):
  2. Resolve the glob into the actual list of package directories
  3. For each directory, read the child `package.json` to get the `name` field
  4. Only keep packages that have a `build` script in `package.json` AND/OR a `tsconfig.json` — packages with nothing to check are dropped

## Step 1 — Parallel typecheck

For EACH package in the list, spawn a background command:

```
<pm workspace/root exec template from Step -1> <typecheck cmd> > /tmp/tsc-<package>.log 2>&1 &
```

`<typecheck cmd>` = the resolved script from Step -1 (`typecheck` → `type-check` → `tsc --noEmit`). Worked examples:
- pnpm + workspace, no `typecheck` script → `pnpm --filter <package> exec tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &` (today's default, byte-identical)
- npm + single-package → `npm exec -- tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &`

Spawn all packages first, then `wait` — do not run them sequentially one by one.

After `wait`, read each `/tmp/tsc-<package>.log`:
- No errors → report pass
- Errors → extract the specific file:line + message, fix, then recheck **only the package just fixed** (rerun exactly 1 tsc command for that package, do not re-run the whole list)

## Step 2 — Parallel build

Same as step 1, spawn a background command for each package:

```
<pm workspace/root exec template from Step -1> <build script> > /tmp/build-<package>.log 2>&1 &
```

`<build script>` = the package's declared `build` script (Step -1 — no raw fallback; a package with no `build` script is skipped, not run with a substitute). Worked example: pnpm + workspace → `pnpm --filter <package> build > /tmp/build-<package>.log 2>&1 &` (today's default, byte-identical).

Spawn all → `wait` → parse each package's log (pass/fail). Failing package → fix, recheck only that package.

## Step 3 — Format

Read the scripts in the root `package.json`, look for a format script (`format`, `format:fix`, ...) in that priority order, run the first one found via the root template from Step -1 (`pnpm exec <script>` / `npm exec -- <script>` / `yarn <script>` / `bun <script>`).

## Step 4 — Test (only when the user requests it or specifies it via argument)

- Determine the test script in each package's `package.json` that needs testing — prefer non-watch mode (`test:run`, `test:ci`, `test -- --run`, ...) over plain `test` if you suspect the default is watch mode
- Run in background + `wait`, same as steps 1-2
- Failure → fix, recheck only that package, repeat until it passes — **never skip a test failure** for any reason

---

## Hard rules

- Always spawn every package with background `&` then `wait` — never run packages sequentially one by one
- Never hardcode any specific package name in the logic — every list must come from the argument or workspace auto-detect
- Failing package → recheck only that package after fixing, don't re-run the whole list
- Never skip a test failure to move past a step — must fix and recheck until it passes

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
