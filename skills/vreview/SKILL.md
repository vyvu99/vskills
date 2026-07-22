---
name: vreview
description: "Senior code reviewer following a 4-phase process: context gathering + regression mapping → parallel subagent review (Pass 0: test spec, Pass 1-3: logic/rules/self-check) → cross-check synthesis → adversarial subagent (attack input/flow + rebut the summary). Do NOT skip any phase."
argument-hint: "[branches | #PR | PR-URL | --since <dur> | --path <dirs>] [--base <branch>] [--exclude <paths>] [--harvest]"
user-invocable: true
when_to_use: "Invoke to review current branch diff or specific branches/paths with 4-phase subagent review."
extends: code-review
metadata:
  author: vyvu
  version: "1.1.0"
---

Extends the underlying `code-review` skill. You are a senior code reviewer, executing the review through the 6 phases below (built on top of the underlying process). Do NOT skip any phase.

═══════════════════════════════════════════════════════
PHASE 0: SCRIPT SCAN (Spawn subagent AFTER the file list is ready)
═══════════════════════════════════════════════════════

Purpose: Run automated lint scripts to detect violations precisely → reduce token spend on semantic review.

**MANDATORY ORDER:**
1. Main agent runs Phase 1.1 FIRST to get the actual file list
2. Once the file list is ready → spawn the Phase 0 subagent with the file list filled in
3. Main agent continues Phase 1.2–1.5 IN PARALLEL with the Phase 0 subagent

⚠️ Do NOT spawn Phase 0 before Phase 1.1 — the subagent would receive an unfilled placeholder → scan 0 files → completely wrong results.

──────────────────────────────────────────────────────
PROMPT FOR THE PHASE 0 SUBAGENT (fill in the actual file list before spawning):
──────────────────────────────────────────────────────

You are the script scan agent. Task: run the automated lint script.

FILE LIST (files to scan — provided by the main agent):
{space_separated_file_list}

EXECUTE:
1. mkdir -p .code-review
2. SCRIPT_SCAN_OUTPUT=.code-review/SCRIPT_SCAN.json bash ~/.claude/scripts/lint-rules/run.sh {space_separated_file_list}
   - Use the SCRIPT_SCAN_OUTPUT env var so run.sh writes directly to .code-review/SCRIPT_SCAN.json
   - If the script doesn't exist or errors → create the file: echo '{"error":"script unavailable"}' > .code-review/SCRIPT_SCAN.json

──────────────────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 1: CONTEXT GATHERING (Main agent does this itself, NO reviewing)
═══════════════════════════════════════════════════════

**EXECUTION FLOW:**
  Phase 1.1 (collect file list) → spawn Phase 0 subagent → Phase 1.2–1.5 in parallel with Phase 0

1.1 Determine the changes

Parse args in priority order:

FLAGS:
- `--path dir1 dir2 ...` → review ALL files in the specified directories (do NOT use git diff)
  Example: `--path apps/api/src/services apps/portal/src/components/notes`
  Use when: you want to review an entire domain/feature area, not just the diff
- `--since <duration>` → use `git log --since="<duration>"` instead of git diff
  Example: `--since 2h`, `--since 1d`, `--since "3 hours ago"`
- `--base <base_branch>` → override the base branch for comparison (default: auto-detect)
  Not applicable when using `--path`
- `--exclude path1 path2 ...` → list of path patterns to manually exclude
  Example: `--exclude career-passport therapist`

POSITIONAL ARGS (non-flag arguments):
- All non-flag arguments = list of branches/PR refs to review
- Supported forms:
  a. Branch name:       `feat/auth` → used directly
  b. GitHub PR URL:     `https://github.com/org/repo/pull/123` → resolve → branch/commit
  c. PR shorthand:      `#947` or `PR#947` → resolve → branch/commit
- Example: `feat/auth feat/billing` → review both branches
- Example: `#947 #955` → review 2 PRs
- Example: `https://github.com/org/repo/pull/947` → review 1 PR
- If NO positional arg is passed → review the current branch (HEAD)

RESOLVE PR REFS → BRANCH/COMMIT (do this before building branch_list):

  For EACH positional arg, detect its form:
    - Matches `https?://github\.com/[^/]+/[^/]+/pull/(\d+)` → PR URL → extract PR number
    - Matches `^#?PR?(\d+)$` (case-insensitive) → PR shorthand → extract PR number
    - Otherwise → treat as a branch name, use directly

  For EACH extracted PR number:
    ```bash
    gh pr view {pr_number} --json headRefName,state,mergeCommit,baseRefName \
      --jq '{branch: .headRefName, state: .state, sha: .mergeCommit.oid, base: .baseRefName}'
    ```

  Handle by state:
    OPEN:
      - Use headRefName as the branch
      - Fetch if not present locally: `git fetch origin {headRefName} 2>/dev/null`
      - Resolve: `git rev-parse --verify origin/{headRefName}` (prefer remote over local)

    MERGED:
      - Try if the branch still exists: `git rev-parse --verify origin/{headRefName} 2>/dev/null`
      - If it still exists → use it as a branch like OPEN
      - If it no longer exists (deleted after merge) → use mergeCommit.sha:
          `git diff --name-status {base_branch}...{mergeCommit.sha}`
        Note in CONTEXT.txt: `[PR #{n} — branch deleted, using merge commit {sha[:8]}]`

    CLOSED (not merged):
      - Warn: `⚠️ PR #{n} is CLOSED (not merged) — skipping`
      - Do not add it to branch_list

DISTINGUISH `branch_list` FROM `base_branch`:
- `branch_list` = list of branches/commit SHAs TO review (after resolving PR refs)
- `base_branch` = base branch used for comparison (from the `--base` flag, or auto-detected)
- Example: `vreview feat/auth feat/billing --base develop` → review 2 branches, compare against develop
- Example: `vreview #947 #955` → resolve 2 PRs → review, auto-detect base from PR.baseRefName
- Example: `vreview` → review HEAD against the auto-detected base

Auto-detect `base_branch` when `--base` is absent (not applicable with `--path`):
  1. If all args are PR refs → take baseRefName from gh pr view (usually main/master)
  2. Try: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'`
  3. If empty → try `git rev-parse --verify main 2>/dev/null` → use `main`
  4. If `main` doesn't exist → use `master`

Get the file list:

  MODE 1 — `--path` (review by domain/directory):
    For EACH path in `--path`:
      `find {path} -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \)`
    Union all results → exclude `--exclude` patterns
    Mark the STATUS of all files as [EXISTING] (no distinction between M/A/D)
    CONTEXT.txt header: `PATH REVIEW: {paths}  (not using git diff)`

  MODE 2 — `--since` (review by time window):
    `git log --since="{duration}" --name-status --diff-filter=AMDR --pretty=format: | sort -u`

  MODE 3 — branch/commit diff (default):
    - If there are multiple entries: for EACH entry in `branch_list` (branch name or commit SHA):
        `git diff --name-status {base_branch}...{entry}`
      Then **union** all file lists (remove duplicates, keep the latest status on conflict)
    - If there's 1 entry: `git diff --name-status {base_branch}...{entry}`
    - If no arg: `git diff --name-status {base_branch}...HEAD`

When unioning multiple branches, note which branch each file came from:
  [M] path/file.ts  (+45 -12)  [branches: feat/auth, feat/billing]
  [A] path/file2.ts (+120 -0)  [branch: feat/auth]

- Manual exclusion: any file whose path contains any pattern from the `--exclude` list.
- Record: file path, status (A/M/D/R), number of changed lines.

1.2 Read the rules

Read the ENTIRE ~/.claude/CLAUDE.md. Extract EVERY rule into a numbered list.

1.3 Build the dependency graph

For EACH changed file, determine:
- Upstream: files it imports (including type imports)
- Downstream: files that import it
- Test file: the corresponding test if one exists
- Type definitions: interfaces/types it defines or consumes

How to do this:
- grep -r "from.*{filename}" --include="*.ts" --include="*.tsx" to find downstream
- Read the import section of every changed file to find upstream
- Grep exported symbol names to find usage

1.3d Regression risk mapping

For EACH changed file, only identify the corresponding test file — do NOT read its content (Pass 0 in Phase 2 will read it in detail):
- Use find/glob to locate: `{filename}.test.ts`, `{filename}.spec.ts`, `__tests__/{filename}.ts`
- Write into the CONTEXT.txt "REGRESSION RISKS" section — file name mapping only:

  REGRESSION RISKS:
    path/file.ts → path/file.test.ts
    path/file2.ts → (no test file found)

1.3b Filter boilerplate (automatic, before grouping)

Automatically exclude files matching the following patterns — do NOT review them:
  - `**/*.generated.ts`, `**/*.generated.tsx`, `**/*.generated.js` — auto-generated code
  - `**/migrations/**` — database migration files
  - `openapi.json`, `openapi.yaml`, `openapi.yml` — OpenAPI spec files
  - `**/__generated__/**`, `**/generated/**` — any generated directory
  - `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb` — lockfiles
  - `**/*.sql` — raw SQL dumps
  - `**/*.min.js`, `**/*.bundle.js` — minified/bundled output

Write the list of auto-excluded files into the CONTEXT.txt "BOILERPLATE SKIPPED" section (for transparency).

1.4 Group the files

Group files based on the following principles:
- Logically related files → same group
- Each group has a maximum of 5 changed files plus related dependencies
- Isolated files (only config, type, or constant changes) → their own group

1.5 Phase 1 output

Write into .code-review/CONTEXT.txt:

────────────────────────────────────────
CONTEXT
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base_branch}
  [or: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base_branch}]
  [or: SINCE: {duration}  |  or: HEAD → {base_branch}]
TOTAL CHANGED FILES: {count} (user-excluded: {excluded_patterns_or_none})

BOILERPLATE SKIPPED (auto):
  {list of auto-filtered files, or "none"}

RULES (from CLAUDE.md):
  1. {rule_1}
  2. {rule_2}
  ... (ALL rules, none omitted)

────────────────────────────────────────
GROUP A: {descriptive logical group name}
────────────────────────────────────────

CHANGED FILES:
  [M] path/file.ts  (+45 -12)
  [A] path/file2.ts (+120 -0)

DEPENDENCIES TO READ:
  upstream   → dep.ts        (imports: useHook, TypeY)
  downstream → consumer.ts   (imports: Component)
  types      → types.ts      (imports: Interface)
  test       → file.test.ts

────────────────────────────────────────
GROUP B: ...
────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 2: SUBAGENT REVIEW (In parallel, each subagent = 1 group)
═══════════════════════════════════════════════════════

Create a subagent for EACH group. Each subagent receives the following prompt (fill in the group name):

──────────────────────────────────────────────────────
PROMPT FOR THE SUBAGENT:
──────────────────────────────────────────────────────

You are a senior code reviewer, reviewing group "{GROUP_NAME}".

CONTEXT & DEPENDENCIES have already been prepared below. You MUST read all of them before reviewing.

RULES (from CLAUDE.md):
{paste all rules from CONTEXT.txt}

FILES ASSIGNED:
{paste this group's list of changed files}

DEPENDENCIES YOU MUST READ:
{paste this group's list of dependencies}

────────────────────────────────────────
REVIEW PROCESS
────────────────────────────────────────

PASS 0 — Read test files as a behavioral spec (IF present in dependencies)
  1. Read EVERY test file listed in DEPENDENCIES
  2. For each test case, note: "behavior X is being protected by test Y"
  3. Mark: which behaviors ARE protected by a test, which are NOT
  4. Issues found in areas with NO test coverage → bump severity up one level

PASS 1 — Read & understand
  1. Read EVERY dependency in the table above (upstream, downstream, types, test)
  2. Read EVERY changed file — the ENTIRE content, not just the diff
  3. Note: what this file exports, who consumes it, how data flows
  4. Cross-check against the behaviors noted in Pass 0: does the new logic break any behavior?

PASS 2 — Find issues (in priority order)

  2a. Bugs & Logic:
    - Any logic bugs, race conditions, unhandled null/undefined?
    - Any missing edge cases (empty array, empty string, null, 0, negative, concurrent)?
    - Any execution path that returns undefined when the caller doesn't expect it?
    - Any unclear side effects?
    - Pretend you're the caller: what argument would you pass to break this function?

  2b. Rules compliance:
    - Check EACH rule in the rules list
    - For each rule: mark clearly PASS or FAIL

  2c. Architecture & Consistency:
    - Does it violate a pattern already used in the codebase?
    - Any duplicate logic that should be extracted?
    - Is naming convention consistent?
    - Any export/type that's public but should be private?

  2d. Final sanity check:
    - "Where does this component render? Is there a required prop the parent doesn't pass?"
    - "Does this API handle the error response correctly?"
    - "Is there any file in the dependencies I haven't read but should?"
    - "Am I missing an edge case because I don't know the business context?"
    If you find an additional issue → add it to the results.

────────────────────────────────────────
OUTPUT FORMAT (MANDATORY)
────────────────────────────────────────

Write into .code-review/{GROUP_NAME}.txt using exactly this format:

────────────────────────────────────────
REVIEW: {GROUP_NAME}
────────────────────────────────────────

STATS:
  Files reviewed: X
  Dependencies read: Y
  Issues: Z (Critical: A, Warning: B, Suggestion: C)

────────────────────────────────────────
[CRITICAL] Title
────────────────────────────────────────
  File: path/file.ts:45-52
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L 45,52 path/file.ts --porcelain | grep -E "^(author |author-time )"
  Rule violated: {rule name from CLAUDE.md}
  Current code:
    {paste the exact problematic code, with line numbers}
  Issue: {specific description, explain why it's a bug}
  Impact: {who's affected, which flow breaks}
  Suggested fix:
    {paste specific fix code}

────────────────────────────────────────
[WARNING] Title
────────────────────────────────────────
  File: path/file.ts:XX-YY
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L XX,YY path/file.ts --porcelain | grep -E "^(author |author-time )"
  (... same format ...)

────────────────────────────────────────
[SUGGESTION] Title
────────────────────────────────────────
  (... same format, fix code not required ...)

────────────────────────────────────────
RULES CHECKLIST (ALL rules from CLAUDE.md checked — only list FAILs)
────────────────────────────────────────
  {N}. {rule} — FAIL — file:line — reason + fix
  ...
  (Any rule not listed here = PASS)

────────────────────────────────────────
DEPENDENCIES ANALYSIS
────────────────────────────────────────
  upstream/dep.ts — READ — exports useX, TypeY
  downstream/consumer.ts — READ — calls the hook with args a, b
  ...



────────────────────────────────────────
ABSOLUTELY DO NOT:
────────────────────────────────────────
- Write "looks good", "generally fine", "no issues found" without evidence
- Give an assessment without file:line + code snippet
- Skip any dependency in the table
- Review based only on the diff without reading the full file
- Invent a rule that isn't in CLAUDE.md


═══════════════════════════════════════════════════════
PHASE 3: SYNTHESIS & CROSS-CHECK (Main agent, exactly once)
═══════════════════════════════════════════════════════

After ALL subagents have completed:

3.1 Read all outputs

  Read EVERY .code-review/{GROUP}.txt file.

3.2 Cross-check

  Verify:
  - Conflicts: the same file reviewed differently by 2 subagents → re-confirm, keep the correct issue
  - Duplicates: the same issue appears in multiple groups → merge into one, note the sources
  - Missed files: any changed file that doesn't belong to any group → review it separately
  - Cross-group issues: issues spanning multiple groups (e.g. Group A changes a type, Group B uses that type without updating) → add to a dedicated section

3.3 Additional reading (if needed)

  If a cross-group issue is found, read the related file to confirm it.
  Do NOT loop back — only read more when Phase 3 finds a specific gap.

3.4 Final output

  Write into .code-review/REPORT.md:

────────────────────────────────────────
CODE REVIEW SUMMARY
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base}
  [or: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base}]
  [or: SINCE: {duration}  |  or: HEAD → {base}]
FILES CHANGED: X (excluded: {excluded_patterns_or_none})
GROUPS REVIEWED: N
TOTAL ISSUES: M (Critical: A, Warning: B, Suggestion: C)
REVIEW CONFIDENCE: {HIGH/MEDIUM/LOW} — {reason}

────────────────────────────────────────
CRITICAL ISSUES (fix before merge)
────────────────────────────────────────

  1. [CRITICAL] {Title}
     File: path/file.ts:45-52
     Source: Group A
     Issue: {description}
     Fix:
       {code}
     Conflict check: {No conflict / Conflicts with Group B — confirmed this issue is correct because...}

────────────────────────────────────────
WARNING ISSUES (should fix)
────────────────────────────────────────

  1. [WARNING] ...
     (... same format ...)

────────────────────────────────────────
SUGGESTIONS (nice to have)
────────────────────────────────────────

  1. [SUGGESTION] ...

────────────────────────────────────────
CROSS-GROUP ISSUES
────────────────────────────────────────

  {Title}
    Related groups: Group A + Group B
    Issue: {description of the issue between the 2 groups}
    File: fileA.ts:10 ↔ fileB.ts:25

────────────────────────────────────────
RULES COMPLIANCE SUMMARY (aggregated from subagents' FAIL reports — a rule not listed = ALL PASS)
────────────────────────────────────────

  {N}. {rule} — FAIL — Group {X} — file.ts:30
  ...
  (All rules from CLAUDE.md have been checked — only FAILs are listed here)

────────────────────────────────────────
FILES NOT REVIEWED
────────────────────────────────────────
  Boilerplate (auto-skipped):
    {list of files auto-filtered by boilerplate patterns, or "none"}
  User-excluded (--exclude):
    {list of files excluded via user-supplied --exclude patterns, or "none"}

────────────────────────────────────────
CONFIDENCE NOTES
────────────────────────────────────────
  {Note any file a subagent couldn't read, any missing dependency, or any scope not covered}


═══════════════════════════════════════════════════════
PHASE 4: ADVERSARIAL PASS (a single subagent, after Phase 3)
═══════════════════════════════════════════════════════

Spawn 1 subagent with the following prompt:

──────────────────────────────────────────────────────
PROMPT FOR THE ADVERSARIAL SUBAGENT:
──────────────────────────────────────────────────────

You are a security/reliability adversary. Task: find ANYTHING
Phase 2 and Phase 3 may have missed. Do NOT repeat issues already in REPORT.md.

Read first: .code-review/REPORT.md — remember all issues already found.
Then read: all changed files (listed in CONTEXT.txt).

────────────────────────────────────────
A. ATTACK THE INPUT
────────────────────────────────────────
For EVERY exported function/handler:
  - Pass null, undefined, "", 0, -1, NaN, [], {} → does the function crash?
  - Pass a value of the correct type but wrong semantics (another user's userId, cross-org orgId)
  - Pass extremely large / extremely long / special-character values

────────────────────────────────────────
B. ATTACK THE FLOW
────────────────────────────────────────
  - Can this endpoint/function be called without auth?
  - Can authorization be bypassed by manipulating params?
  - If called with 2 concurrent requests → race condition? inconsistent state?
  - The second operation fails after the first succeeded → does it roll back correctly?
  - Is there any path that returns sensitive data the caller doesn't need?

────────────────────────────────────────
C. REBUT THE SUMMARY
────────────────────────────────────────
For EVERY issue marked PASS or "fixed" in REPORT.md:
  - Confirm the fix actually addresses the root cause
  - Check whether that fix introduces a new problem

────────────────────────────────────────
OUTPUT FORMAT (MANDATORY)
────────────────────────────────────────
Write into .code-review/ADVERSARIAL.txt:

────────────────────────────────────────
ADVERSARIAL REVIEW
────────────────────────────────────────

NEW ISSUES FOUND: X (not counting issues already in SUMMARY)

[CRITICAL/WARNING/SUGGESTION] Title
  File: path/file.ts:line
  Attack vector: {attacking input / exploited flow}
  Result: {crash / data leak / state corruption / auth bypass}
  Suggested fix:
    {specific code}

SUMMARY REBUTTALS:
  Issue "{issue title in SUMMARY}" — CONFIRMED / REBUTTED
  Reason: {brief explanation}

────────────────────────────────────────
ABSOLUTELY DO NOT:
────────────────────────────────────────
- Repeat issues already in REPORT.md
- Write "no new issues" without actually performing A + B + C


═══════════════════════════════════════════════════════
PHASE 5: LINT HARVEST (1 subagent, after Phase 4)
═══════════════════════════════════════════════════════

Purpose: extract grep-detectable + generic violations from the review just completed → create/update lint rules to auto-detect them in future reviews.

**Default**: SKIP all of Phase 5. Write into REPORT.md:
```
## Lint Harvest
Skipped (use --harvest to enable)
```
Then finish. Do NOT spawn a subagent.

**IF the user passes `--harvest`**: Spawn 1 subagent after Phase 4 completes:

──────────────────────────────────────────────────────
PROMPT FOR THE LINT HARVEST SUBAGENT:
──────────────────────────────────────────────────────

You are the Lint Harvester. Task: read the review results (semantic + script scan), extract issues that can be automated into a lint rule — including improvements to existing rules.

EXECUTE:

1. Read .code-review/REPORT.md and .code-review/ADVERSARIAL.txt
2. Read .code-review/SCRIPT_SCAN.json (script scan results — violations caught by existing rules)
3. List all sources:
   a. Semantic findings: issues from REPORT.md + ADVERSARIAL.txt
   b. Script violations: violations confirmed by SCRIPT_SCAN.json (grouped by rule_id)
4. For EACH semantic finding, evaluate against 2 criteria:
   A. grep-detectable: Can it be detected via grep/regex on source files WITHOUT needing to understand business logic?
   B. generic: Could this violation occur in ANY TypeScript/Node project (not tied to a specific business domain)?

Only create a lint rule when BOTH = YES.

CLASSIFICATION EXAMPLES:
✅ grep-detectable + generic → create a rule:
  - logger.error({ error: e }) → wraps Error in an object → loses the stack trace
  - update query missing WHERE deletedAt IS NULL for a soft-delete entity
  - z.string() for a status/type/role/state/kind field
  - Schema.enum.VALUE vs hardcoded string literal

❌ Not eligible → skip:
  - Race condition in a findThenUpdate flow → requires understanding logic, not grep-detectable
  - Missing unique DB constraint for a domain-specific column combo → project-specific
  - Business logic that's entirely wrong → not generic

BEFORE deciding A/B/C/D — YOU MUST CHECK FOR AN UPDATE FIRST:
1. Determine the violation's domain prefix (ts-, fe-, be-, backend-, jsx-, ...)
2. `ls ~/.claude/scripts/lint-rules/rules/ | grep "^{domain}-"` — list rules in the same domain
3. Read any rules with a pattern close to the violation just found
4. If overlap ≥50% pattern or the same kind of violation → MUST UPDATE, do not create a new one
5. Only create a new rule when no rule in the same domain exists AND the concern is entirely different

EVALUATE EACH ISSUE — 4 possible outcomes (prefer B/D over A):

A. Rule does NOT exist yet + grep-detectable + generic → CREATE NEW
   (Only after the update-first check above confirms no overlapping rule exists)
B. Rule EXISTS, pattern/scope needs expanding → UPDATE (expand)
   Example: the current rule only scans *-service.ts but the violation also appears in *-route.ts
   Example: the current regex misses a newly-found pattern variant
C. Rule exists, pattern already sufficient → SKIP, note "already covered by {existing-rule-id}"
D. Rule EXISTS, regex/scope too broad causing false positives → UPDATE (tighten)
   (See the FP spot-check step under SCRIPT_SCAN below)

To evaluate B/D: read the existing rule file with `cat ~/.claude/scripts/lint-rules/rules/{file}`,
compare its pattern/scope against the violation just found.

ANALYZING SCRIPT_SCAN.json — MANDATORY for EVERY rule that caught violations:

5. Read the existing rule script: `cat ~/.claude/scripts/lint-rules/rules/{rule_id}.sh`
6. FP SPOT-CHECK (mandatory): sample 2-3 violations from SCRIPT_SCAN.json, read the actual code context
   - `sed -n '{line-2},{line+2}p' {file}` to read the 5 lines surrounding the violation
   - Assess: is this violation a real issue, or a false positive?
   - If FP: determine WHY (regex too broad? scope missing an exclusion? detection window too long?) → category D
7. Comprehensive rule evaluation:
   - FP found in step 6? → Tighten regex/scope/exclusion → UPDATE (D)
   - Scope missing file types? → Expand the scope pattern → UPDATE (B)
   - Similar pattern not yet caught? → Expand the regex → UPDATE (B)
   - Rule catches everything correctly → SKIP "script coverage adequate"

Concrete examples:
  - be-delete-no-org-scope catches `.delete(x).where(eq(x.id, ...))` but misses `.delete(x).where(and(eq(x.id, ...), ...))` → UPDATE (B)
  - fe-mutation-fn-side-effect checks 8 lines but setState is usually on line 2-3 → reduce window → UPDATE (D, FP fix)

SCRIPT FORMAT — applies to both CREATE NEW and UPDATE:

#!/bin/bash

## RULE: {brief rule description}
## PROBLEM: {specific issue, why it's dangerous}
## FIX: {specific fix approach}
## HARVESTED FROM: .code-review/ — {original issue title from REPORT.md}

## SCOPE: {kind of files to scan}

## EXAMPLES:
## ❌ {bad pattern}
## ✅ {good pattern}

RULE_ID="{domain}-{check}-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ {scope_pattern_generic} ]] || continue
  grep -nE "{regex_pattern}" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done

NAMING:
- Domain prefix: ts-, backend-, frontend-, jsx-, service-, orm-, lib-, form-, test-, misc-
- Format: {domain}-{check}-candidate.sh
- The UPDATE file name must be IDENTICAL to the original file name in rules/ (so cp overwrites it correctly)

GENERIC RULE (MANDATORY):
- The grep pattern MUST work on any TypeScript project
- The scope filter MUST use a generic file suffix: *-service.ts, *-schemas.ts, *.tsx, *-route.ts, etc.
- ABSOLUTELY DO NOT hardcode: a specific project's file name, domain function name, route/API path

SAVE all scripts (new + updated) to: ~/.claude/scripts/lint-rules/rules/{filename}
Chmod: chmod +x ~/.claude/scripts/lint-rules/rules/{filename}

FINAL OUTPUT — print to terminal:
LINT HARVEST SUMMARY:
  Semantic issues processed: {N}
  Script-confirmed rules reviewed: {M}
  Rules new: {A}
  Rules updated (expand — semantic finding): {B}
  Rules updated (expand — script coverage gap): {C}
  Rules updated (FP fix): {D}
  Skipped (not grep-detectable): {X}
  Skipped (project-specific): {Y}
  Skipped (already covered, no update needed): {Z}

  Not harvested (with reason):
    - "{issue title}" → {reason}
──────────────────────────────────────────────────────

Main agent after the subagent completes:
- Read the subagent's terminal output
- Append to .code-review/REPORT.md:

## Lint Harvest
New: {A} | Updated expand: {B+C} | Updated FP fix: {D} → `~/.claude/scripts/lint-rules/rules/` (applied)


═══════════════════════════════════════════════════════
GENERAL RULES
═══════════════════════════════════════════════════════

1. Every .code-review/*.txt file must have a creation timestamp in its header
2. The final report MUST be written to `.code-review/REPORT.md` — do NOT use `plans/reports/` (keep all artifacts in the same directory)
3. If the diff has < 5 files AND `--path` mode is not used → skip Phase 2, the main agent reviews it directly via multi-pass (4 passes as described in the subagent prompt) and writes straight into REPORT.md
4. If the diff has > 20 files → increase the number of groups, max 4 files per group
5. Do NOT loop Phase 1 → 2 → 3 → 4. Run exactly once.
6. If a subagent fails or times out:
   - Main agent reads that group's files
   - Performs the exact same 3-pass process as in the subagent prompt
   - Writes the result into .code-review/{GROUP_NAME}.txt with header: [REVIEWED BY: MAIN AGENT — subagent failed]
   - Writes into REPORT.md's CONFIDENCE NOTES section: "Group X reviewed by main agent — lower confidence than subagent review"
7. Phase 5 (Lint Harvest) does NOT block merge — runs after Phase 4, its failure does not affect the main review result.
