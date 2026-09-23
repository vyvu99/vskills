---
name: vci
description: "Run typecheck + build + format (+ optional test) in parallel for all or part of the packages in a JS/TS repo (monorepo or single package). Auto-detects workspace packages and package manager, no hardcoded package names."
argument-hint: "[package-names...] [--test] [--changed]"
user-invocable: true
when_to_use: "Invoke when you need a fast typecheck/build (and test) of the whole repo or a group of packages in a JS/TS monorepo (or single package) before commit/PR."
allowed-tools: Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(tsc:*), Bash(turbo:*), Bash(nx:*), Bash(eslint:*), Bash(prettier:*), Bash(biome:*), Bash(git:*)
metadata:
  author: vyvu
  version: "1.2.0"
---

# vci

Runs typecheck + build (+ optional test) in parallel for packages in a JS/TS repo (monorepo or single package), using background commands + `wait`. No hardcoded package names or package manager.

Read input from the user:

```
$ARGUMENTS
```

---

## Step -1 — Resolve the repo profile

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §1 (if present) to resolve the package manager (`pm`), workspace shape, and the typecheck/build/format script names. Absent → assume pnpm + workspace (`pnpm --filter <pkg> exec …`), today's default. §1 reports "not a JS/TS project" → stop, say so — vci has nothing to do in a non-JS/TS repo.

`turbo.json` or `nx.json` exists at the repo root → prefer the orchestrator for Steps 1-2: `turbo run typecheck build` (or `nx run-many --target=typecheck,build`) gets cache hits and topological ordering for free. Fall back to the manual per-package spawn below otherwise.

## Step 0 — Determine the package list

- If `$ARGUMENTS` contains `--test`, treat it as a test-request flag (see Step 4) and strip it before parsing package names
- If `$ARGUMENTS` contains `--changed`, strip it and derive the package list from `git diff --name-only <base>...HEAD` (base = the repo's default branch, e.g. `origin/main`, fallback `main`) instead of the full workspace: map each changed file path to its containing package directory (the directories resolved in point 2 below), dedupe, and use that list
- If `$ARGUMENTS` contains a list of package names → use that exact list, skip auto-detect
- If empty → auto-detect the whole workspace:
  1. Use the workspace shape from Step -1. **Single-package** → the package list is just the root package; skip glob resolution, go straight to Step 1. **Monorepo** → continue with the glob pattern from `pnpm-workspace.yaml` (or the `workspaces` field in the root `package.json`):
  2. Resolve the glob into the actual list of package directories
  3. For each directory, read the child `package.json` to get the `name` field
  4. Only keep packages that have a `build` script in `package.json` AND/OR a `tsconfig.json` — packages with nothing to check are dropped

## Step 1 — Parallel typecheck

Sanitize the package name for use as a filesystem path first: replace `/` and `@` with `_` (e.g. `@app/api` → `_app_api`) — a scoped name written raw into `/tmp/tsc-<package>.log` breaks (unintended subdirectory, or outright failure).

`turbo`/`nx` preferred (Step -1) → run the orchestrator's typecheck target instead of the loop below, skip straight to reading its output.

For EACH package in the list, spawn a background command wrapped in `time` so the log carries per-package wall-time:

```
{ time timeout 600s <pm workspace/root exec template from Step -1> <typecheck cmd> ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &
```

`<typecheck cmd>` = the resolved script from Step -1 (`typecheck` → `type-check` → `tsc --noEmit`). Worked examples:
- pnpm + workspace, no `typecheck` script → `{ time timeout 600s pnpm --filter <package> exec tsc --noEmit ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &` (today's default, byte-identical)
- npm + single-package → `{ time timeout 600s npm exec -- tsc --noEmit ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &`

Spawn all packages first, then `wait` — never sequentially. Resuming after an interruption → reuse an existing fresh `/tmp/tsc-<sanitized-package>.log` if present instead of re-spawning that package's check.

After `wait`, read each `/tmp/tsc-<sanitized-package>.log`:
- No errors → report pass, with the wall-time `time` printed at the end of the log
- Errors → extract file:line + message, fix, recheck **only the package just fixed** (rerun exactly 1 tsc command, do not re-run the whole list)
- No `tsconfig.json` → treat as "no typecheck config", not a type error — skip/report accordingly

## Step 2 — Parallel build

Sanitize the package name for use as a filesystem path first: replace `/` and `@` with `_` (e.g. `@app/api` → `_app_api`) — a scoped name written raw into `/tmp/build-<package>.log` breaks (unintended subdirectory, or outright failure).

`turbo`/`nx` preferred (Step -1) → run the orchestrator's build target instead of the loop below, skip straight to reading its output.

Same as step 1: spawn a background command per package, wrapped in `time`:

```
{ time timeout 600s <pm workspace/root exec template from Step -1> <build script> ; } > /tmp/build-<sanitized-package>.log 2>&1 &
```

`<build script>` = the package's declared `build` script (Step -1 — no raw fallback; a package with no `build` script is skipped, not run with a substitute). Worked example: pnpm + workspace → `{ time timeout 600s pnpm --filter <package> build ; } > /tmp/build-<sanitized-package>.log 2>&1 &` (today's default, byte-identical).

Spawn all → `wait` → parse each package's log (pass/fail, with wall-time). Failing package → fix, recheck only that package. Resuming after an interruption → reuse an existing fresh `/tmp/build-<sanitized-package>.log` if present instead of re-spawning.

## Step 2.5 — Parallel lint

Resolve a lint script the same way as typecheck/build (Step -1 pattern): `lint` → `lint:check` → direct `eslint .` fallback.

For EACH package in the list, spawn a background command:

```
timeout 600s <pm workspace/root exec template from Step -1> <lint cmd> > /tmp/lint-<sanitized-package>.log 2>&1 &
```

Spawn all → `wait` → parse each package's log (pass/fail). Failing package → fix, recheck only that package — same rules as Steps 1-2. Resuming after an interruption → reuse an existing fresh `/tmp/lint-<sanitized-package>.log` if present instead of re-spawning.

## Step 3 — Format

Try, in order, stopping at the first one that applies:
1. Root `package.json` format script (`format`, `format:fix`, ...) via the root template from Step -1
2. `prettier --write .` if `prettier` is a devDependency anywhere in the workspace
3. `biome check --write .` if `@biomejs/biome` is a devDependency
4. `eslint --fix .` otherwise, as the last resort

## Step 4 — Test (only when the user requests it or `$ARGUMENTS` contains `--test`)

- Determine the test script in each package's `package.json` that needs testing — prefer non-watch mode (`test:run`, `test:ci`, `test -- --run`, ...) over plain `test` if you suspect the default is watch mode
- Run in background + `wait`, same as steps 1-2 (prefix with `timeout 600s`)
- Failure → fix, recheck only that package, repeat until it passes — **never skip a test failure** for any reason

---

## Hard rules

- Always spawn every package with background `&` then `wait` — never run packages sequentially one by one
- Never hardcode any specific package name in the logic — every list must come from the argument or workspace auto-detect
- Failing package → recheck only that package after fixing, don't re-run the whole list
- Never skip a test failure to move past a step — must fix and recheck until it passes
- Wrap every background command in `timeout 600s` (or `gtimeout` on macOS) — a hung package must not hang the whole `wait`.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
