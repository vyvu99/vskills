---
name: vci
description: "Runs format, typecheck, build and lint (plus tests with --test) in parallel across all or some packages of a JS/TS repo, fixes the errors it finds and rechecks only the packages it fixed. Detects the package manager and workspace packages itself. Use before a commit or PR, or when asked to check that everything still compiles and builds."
argument-hint: "[package-names...] [--test] [--changed]"
user-invocable: true
when_to_use: "Use when the user wants the whole repo or a group of packages typechecked, built, linted or tested before committing, e.g. 'run typecheck and build', 'does everything still build after this refactor'. Not for explaining code, reviewing a PR or writing tests."
allowed-tools: Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(tsc:*), Bash(turbo:*), Bash(nx:*), Bash(eslint:*), Bash(prettier:*), Bash(biome:*), Bash(git:*), Bash(timeout:*), Bash(gtimeout:*), Bash(command:*), Bash(mkdir:*), Bash(cat:*), Bash(echo:*), Bash(wait:*)
metadata:
  author: vyvu
  version: "2.0.0"
---

# vci

Checks a JS/TS repo (monorepo or single package) with format, typecheck, build and lint, plus tests on request. It edits files: the formatter rewrites them and failing checks get fixed. Scope is the checks only, with no unrequested features, tests or docs.

```
$ARGUMENTS
```

## 1. Resolve the profile and the package list

Read `~/.claude/skills/_vskills-shared/repo-profile.md` §1 for the package manager (`pm`), the workspace shape and the script names. If the file is missing, assume pnpm with a workspace. If §1 says this is not a JS/TS project, stop and say so.

Package list, first match wins:
- Names in `$ARGUMENTS` (after stripping `--test` and `--changed`): use exactly those.
- `--changed`: map `git diff --name-only <default-branch>...HEAD` to their containing packages and dedupe. Dependents of those packages are not included, so prefer the orchestrator's affected mode when step 2 applies.
- Otherwise the whole workspace: resolve the globs in `pnpm-workspace.yaml` or `workspaces`, read each `package.json` name, and keep packages that have a `build` script or a `tsconfig.json`. A single-package repo is just the root.

If `turbo.json` or `nx.json` exists, use the orchestrator for the checks in step 3 (`turbo run typecheck build lint --filter=<pkg>` or `--affected`, `nx run-many --target=...`). It gives cache hits and dependency order, and you read its output instead of per-package logs.

## 2. Format first

Format before the checks so they verify the final code. Use the first that applies: the root `format`/`format:fix` script, `prettier --write .`, `biome check --write .`, `eslint --fix .`.

## 3. Run the checks in parallel

Without an orchestrator, run one stage at a time (typecheck, then build, then lint, then test), all packages of a stage in parallel. One Bash call per stage, with the Bash tool timeout set to 600000 ms so a hung package cannot hang `wait`:

```bash
mkdir -p /tmp/vci
(<pm exec template> <cmd>; echo "exit=$?") > /tmp/vci/<stage>-<safe-name>.log 2>&1 &
# ...one line per package...
wait
```

- `<safe-name>`: package name with `/` and `@` replaced by `_`, since a raw scoped name breaks the log path.
- Prefix `<cmd>` with `timeout 600` (or `gtimeout 600`) only when `command -v` finds one. Stock macOS has neither, and the Bash tool timeout already covers it.
- Command per stage: typecheck uses `typecheck`, then `type-check`, then `tsc --noEmit`; build uses the package's `build` script and skips packages without one; lint uses `lint`, then `lint:check`, then `eslint .`; test (only with `--test`) prefers `test:run`/`test:ci` over a watch-mode `test`.
- A package without `tsconfig.json` has no typecheck, which is not an error.

Read each log's last lines. Failure: fix the cause, then rerun only that package and stage. A test failure is never skipped or weakened; fix it or report it.

## 4. Verify and report

After the last fix, rerun the stages that touched fixed files for those packages, so the final state is proven rather than assumed. Print one table, one row per package: typecheck, build, lint, test (pass, fail, or skipped with reason), plus files the formatter changed. If a stage could not run (missing script, tooling error), say so instead of reporting pass.

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
