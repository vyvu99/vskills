# Phase 1 — Context Gathering

The main agent does all of this itself and reviews nothing yet. Flow: 1.0 incremental check, 1.1 file list, then start the Phase 0 lint scan, then 1.2-1.5 while it runs.

## Table of Contents
1. [1.0 Incremental check](#10-incremental-check)
2. [1.1 Determine the changes](#11-determine-the-changes) — repo profile, flags, PR resolution, file list
3. [1.2 Read the rules](#12-read-the-rules)
4. [1.3 Dependency graph](#13-dependency-graph) — import patterns, coverage tags, regression mapping, boilerplate, early exit
5. [1.4 Group the files](#14-group-the-files)
6. [1.5 CONTEXT.txt format](#15-contexttxt-format)

## 1.0 Incremental check

Applies to branch/commit diff mode only. `--path` and `--since` always run a full review, since there is no single previous commit to diff against.

If `.code-review/REPORT.md` exists, read its header for `REVIEWED_COMMIT:`.
- Not found (older report, or no file): full review, skip the rest of 1.0.
- Found, `{prev_sha}` resolves (`git cat-file -e {prev_sha} 2>/dev/null`) and differs from HEAD: incremental mode.
  - Copy the report before this run overwrites it: `cp .code-review/REPORT.md .code-review/REPORT.prev.md`
  - `git diff --name-status {prev_sha}...HEAD` gives the files changed since the last review.
  - Tag each file in 1.1: changed since `{prev_sha}` is `[NEW-SINCE-LAST-REVIEW]`; unchanged since then but still in the current base...HEAD diff is `[CARRIED-FORWARD]`.
  - Only `[NEW-SINCE-LAST-REVIEW]` files (plus their dependencies) are grouped for Phase 2. Phase 3 copies the carried-forward findings from `REPORT.prev.md` instead of re-reviewing.
- Found and `{prev_sha}` equals HEAD: nothing new. Skip Phases 0, 2, 4; copy `REPORT.md` forward unchanged with a prepended note `No changes since last review ({prev_sha[:8]})`, and stop.

## 1.1 Determine the changes

Repo profile: read `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (host and `gh` availability) and §3 (language/framework tally, used from Phase 2 on). If the file is absent, assume GitHub + `gh` + TypeScript. A CLAUDE.md rule that names a language or framework applies only to files of that language in the diff, so a `.py` file is never flagged against a TypeScript rule. Security checks (secrets, injection, authz) apply to every file. When no rule fits a file's language, review it on general principles (naming, error handling, security, dead code) rather than skipping it.

### Flags
- `--path dir1 dir2 ...`: review all files in those directories, no git diff. For a whole domain or feature area.
- `--since <duration>`: use `git log --since="<duration>"` instead of a diff (`2h`, `1d`, `"3 hours ago"`).
- `--base <branch>`: override the base branch. Not applicable with `--path`.
- `--exclude p1 p2 ...`: path patterns to exclude.

### Positional args
Every non-flag argument is a branch name, a PR URL (`https://github.com/org/repo/pull/123`), or a PR shorthand (`#947`, `PR#947`). No positional arg means review HEAD. `branch_list` is what gets reviewed (after PR resolution); `base_branch` is what it is compared against.

### Resolve PR refs
- Matches `https?://github\.com/[^/]+/[^/]+/pull/(\d+)` or `^#?PR?(\d+)$` (case-insensitive): extract the PR number. Anything else is a branch name used directly.
- Full gh mode (repo-profile §2):
  ```bash
  gh pr view {pr_number} --json headRefName,state,mergeCommit,baseRefName \
    --jq '{branch: .headRefName, state: .state, sha: .mergeCommit.oid, base: .baseRefName}'
  ```
- Degraded mode (no `gh`): print the §2 vreview message (`⚠️ can't resolve PR refs without gh — pass a branch name instead; branch/diff modes work without gh`), drop the arg, continue. If `branch_list` ends up empty, review HEAD.
- By state (full gh mode only):
  - OPEN: use `headRefName`; `git fetch origin {headRefName} 2>/dev/null` if not local; resolve with `git rev-parse --verify origin/{headRefName}` (prefer remote).
  - MERGED: if `origin/{headRefName}` still exists, treat as OPEN. If deleted, use `mergeCommit.sha` with `git diff --name-status {base_branch}...{sha}` and note `[PR #{n} — branch deleted, using merge commit {sha[:8]}]` in CONTEXT.txt.
  - CLOSED (not merged): warn `⚠️ PR #{n} is CLOSED (not merged) — skipping` and do not add it.

### Base branch
When `--base` is absent (and not `--path`): if every arg is a PR ref and gh is available, take `baseRefName` from `gh pr view`; otherwise follow `_vskills-shared/repo-profile.md` §9.

### File list
- Mode 1, `--path`: extensions come from the repo-profile §3 tally (TypeScript: `*.ts *.tsx`; Python: `*.py`; Go: `*.go`; Rust: `*.rs`; Java/Kotlin: `*.java *.kt`); resolve the tally first if needed. For each path run `find {path} -type f \( -name "*.{ext1}" -o -name "*.{ext2}" \)`, union the results, apply `--exclude`, mark every file `[EXISTING]`. CONTEXT.txt header: `PATH REVIEW: {paths}  (not using git diff)`.
- Mode 2, `--since`: `git log --since="{duration}" --name-status --diff-filter=AMDR --pretty=format: | sort -u`
- Mode 3, branch/commit diff (default): for each entry in `branch_list`, `git diff --name-status {base_branch}...{entry}`; union the lists (dedupe, keep the latest status). No arg: `git diff --name-status {base_branch}...HEAD`. When unioning branches, note the source: `[M] path/file.ts (+45 -12) [branches: feat/auth, feat/billing]`.
- Apply `--exclude` patterns by path substring. Record path, status (A/M/D/R), and changed-line count for each file.

## 1.2 Read the rules

Use the CLAUDE.md instructions already in context (user-level and project-level). Read the files only if they are not in context. Extract every rule into a numbered list and append a RULES block to `.code-review/CONTEXT.txt` immediately (create the file with its header block first if this run has not written it).

## 1.3 Dependency graph

Import-search pattern by language (from the §3 tally); substitute `{module}` with the changed file's basename without extension:
- TypeScript/JavaScript: `from ['"].*{module}['"]` or `require\(.*{module}\)`
- Python: `from .*{module} import` or `^import {module}`
- Go: `"{import_path}"` inside an `import (...)` block
- Rust: `use .*{module}`
- Java/Kotlin: `import .*\.{ClassName}`
- Other: skip the import grep and use the exported-symbol grep only

For each changed file determine: upstream (files it imports, including type imports), downstream (files that import it; grep with the pattern above and grep exported symbol names), its test file, and the type definitions it defines or consumes. Read the import section of each changed file for upstream.

Grep-based wiring misses some edges. Tag them next to the file's dependency entry so Phase 2 reviewers widen their manual read (barrel index, DI module, route registration) instead of trusting the edge list:
- directory with `index.ts`/`index.js`/`index.py` (barrel re-export): `[heuristic-incomplete: barrel-reexport]`
- DI/framework marker (`@Injectable`, `@Controller`, `@Component`, `@Service`, `@Autowired`, decorator-based routes): `[heuristic-incomplete: DI-wiring]`
- Next.js/Nuxt/SvelteKit/Remix file-based routing: `[heuristic-incomplete: file-based-routing]`

### Regression risk mapping
Only locate each changed file's test file; Phase 2 Pass 0 reads it. Look for the conventions of the file's language (`{name}.test.ts`, `{name}.spec.ts`, `__tests__/{name}.ts`, `test_{name}.py`, `{name}_test.go`). Write the mapping into the REGRESSION RISKS section of CONTEXT.txt: `path/file.ts → path/file.test.ts` or `→ (no test file found)`.

### Filter boilerplate
Exclude automatically, and list under BOILERPLATE SKIPPED for transparency:
- generated code: `**/*.generated.{ts,tsx,js}`, `**/__generated__/**`, `**/generated/**`
- `openapi.json`, `openapi.yaml`, `openapi.yml`
- lockfiles: `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lock`, `bun.lockb`, `Cargo.lock`, `go.sum`, `poetry.lock`, `Gemfile.lock`, `composer.lock`
- minified/bundled output: `**/*.min.js`, `**/*.bundle.js`

`**/migrations/**` and `**/*.sql` also leave the review but go in a separate MIGRATIONS SKIPPED list, which the report surfaces as not semantically reviewed rather than silently dropped.

### Early exit
- Empty list after filtering (all boilerplate, or an empty diff): skip Phases 2-4, discard any Phase 0 output, write `.code-review/REPORT.md` with only the header block, `TOTAL ISSUES: 0`, and the note "No reviewable files (all changes were boilerplate/docs)". Spawn nothing.
- Comment/whitespace-only files: check each remaining file with
  `git diff -U0 {base_branch}...{entry} -- {file} | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]\s*(//|#|\*|/\*|"""|--)'`
  An empty result means comment/whitespace-only. Tag it `[COMMENT-ONLY]`, leave it out of grouping and out of the 5-file threshold and per-group line cap, and list it under FILES NOT REVIEWED. Best effort: skip the check for languages without a match above.

## 1.4 Group the files

- Logically related files share a group.
- Cap each group at about 400 changed lines (sum of the counts from 1.1), not a file count, so five tiny files and one huge file are sized fairly. In incremental mode only `[NEW-SINCE-LAST-REVIEW]` files count. 400 lines is roughly what one subagent can read in full with its dependencies and still review carefully.
- Files that only change config, types, or constants form their own group.

As soon as a group's files and dependencies are final, append its block (1.5) to `CONTEXT.txt`; do not hold them all until the end.

## 1.5 CONTEXT.txt format

Blocks are written incrementally: header once 1.1 resolves, RULES at 1.2, each GROUP as 1.4 finalizes it.

```
CONTEXT
BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base_branch}
  [or: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base_branch}]
  [or: SINCE: {duration}  |  or: HEAD → {base_branch}]
TOTAL CHANGED FILES: {count} (user-excluded: {excluded_patterns_or_none})
PROFILE: lang={tally, e.g. TypeScript(12) Python(2)} · framework={framework} · host={host_mode} · pm={pm}
INCREMENTAL: {no  |  yes, since {prev_sha[:8]} — {N} new, {M} carried forward}

BOILERPLATE SKIPPED (auto):
  {files, or "none"}

MIGRATIONS SKIPPED (auto, not semantically reviewed):
  {files, or "none"}

RULES (from CLAUDE.md):
  1. {rule_1}
  2. {rule_2}
  ... (all rules)

REGRESSION RISKS:
  path/file.ts → path/file.test.ts

GROUP A: {descriptive logical group name}
CHANGED FILES:
  [M] path/file.ts  (+45 -12)
  [A] path/file2.ts (+120 -0)
DEPENDENCIES TO READ:
  upstream   → dep.ts        (imports: useHook, TypeY)
  downstream → consumer.ts   (imports: Component)
  types      → types.ts      (imports: Interface)
  test       → file.test.ts

GROUP B: ...
```
