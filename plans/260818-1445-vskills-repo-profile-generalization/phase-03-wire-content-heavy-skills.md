---
phase: 3
title: Wire content-heavy skills
status: completed
priority: P2
effort: 1.5h
dependencies:
  - 1
blockedBy:
  - 1
---

# Phase 3: Wire content-heavy skills

## Overview

Wire the 2 largest skills — `vcook` (131 lines, the 9-step implementation checklist) and `vreview` (698 lines, the 6-phase review). Their hardcoding sits deeper: `vcook` bakes Vietnamese into the PR description in two places, `vreview` assumes `gh` for PR-ref resolution and implicitly assumes a TypeScript diff. 4 files (2 × `SKILL.md` + `SKILL.vi.md`).

**Blocked by phase 1.** Runs in parallel with phase 2 (disjoint files).

Same cross-cutting soft-pointer rule and same `.vi.md` mirroring rule as phase 2: pointer + inline fallback to today's default; `.vi.md` gets the identical structural change with Vietnamese prose and identical command text.

## Key insights (from scout)

- `vcook` hardcodes Vietnamese twice, not once: Step 9 (`skills/vcook/SKILL.md:111`) and the Hard rules recap (`:126`). Fixing only one leaves a self-contradicting skill.
- `vreview` needs `gh` only for **PR-ref** resolution (`:88`) and for `baseRefName` in base-branch auto-detect (`:117`). Branch names (`:84`), `--path` (`:126`), `--since` (`:132`) and the base-branch fallbacks (`:118-120`) are pure git — so the degraded mode is genuinely narrow: lose `#947`-style refs, keep everything else.
- `vreview` line 182's lockfile filter already covers pnpm/npm/yarn/bun — the JS gap is closed; what's missing is non-JS ecosystems.
- `vreview` Phase 5 lint harvest at `:631` gates on `[[ "$file" =~ \.(ts|tsx)$ ]]` — that is a *shell* filter inside a generated rule script, correct as-is for TS rules. Out of scope; the §3 wiring targets the review pass, not the harvested rule scripts.

## Requirements

**Functional**
1. `vcook` PR body language resolves from §4 (project CLAUDE.md → global CLAUDE.md → English), not a constant.
2. `vcook` Step 9 PR/issue automation degrades per §2 without losing the composed PR body.
3. `vreview` PR-ref resolution degrades per §2; branch/`--path`/`--since` modes keep working.
4. `vreview` boilerplate filter covers non-JS lockfiles.
5. `vreview` applies language-specific CLAUDE.md rules per file language (§3), not blanket-TypeScript.

**Non-functional**
- `vcook`'s PR style (non-technical, business impact) is unchanged — only the *language* becomes dynamic.
- `vreview`'s 6-phase structure, subagent fan-out, and severity taxonomy untouched; edits confined to Phase 1.1 and 1.3b.

## Architecture

```
repo-profile §2 ──> vcook   Step 9 (gh issue edit, PR creation)
repo-profile §4 ──> vcook   Step 9 PR description language + Hard rules recap
repo-profile §2 ──> vreview Phase 1.1 (gh pr view → PR refs, baseRefName)
repo-profile §3 ──> vreview Phase 1.1 header (diff language tally, consumed in Phase 2)
(no profile)   ──> vreview Phase 1.3b (extra lockfile patterns — static list)
```

Data flow: `vreview` resolves the profile once in Phase 1.1 and writes it into `CONTEXT.txt`, so the Phase 2 review subagents inherit the language tally without each re-detecting. That is the only structural addition in this phase — one extra CONTEXT.txt line.

## Related code files

**Modify (4)**
- `skills/vcook/SKILL.md` + `skills/vcook/SKILL.vi.md`
- `skills/vreview/SKILL.md` + `skills/vreview/SKILL.vi.md`

**Create / delete** — none.

**Out of scope:** `skills/vreview/SKILL.md:631` (shell extension guard inside generated lint rules — correct as written); Phase 5 harvest logic generally; `skills/vfix`, `skills/vplan`, `skills/vspecs`, `skills/vmigrate-rollback` (scout found no host/PM hardcoding worth wiring).

## Implementation Steps

### Step 1 — vcook: gh degrade in Step 9

**File:** `skills/vcook/SKILL.md` (then `SKILL.vi.md`)

**Logic.** In STEP 9 (lines 101-114), before the **Commit:** sub-block, add one resolution line: resolve the VCS profile per `repo-profile.md` §2 (fallback if the file is absent: assume GitHub + gh). Then:

- **Commit** (lines 104-106) — unchanged; git works everywhere.
- **PR** (lines 108-114) — full gh mode → exactly as today. Degraded/local-only → push the branch, print the §2 vcook message plus the **fully composed title and body** (template-conformant per line 109) so the user pastes it into their host's UI. Do not skip composing the body just because it can't be submitted.
- **Issue linkage** (lines 112-114) — `Closes #<issue>` at the top of the body is plain text, keep it in both modes. The `gh issue edit <issue>` back-link (line 114) is gh-only → in degraded mode, print "add a link to the PR in issue #N manually" and continue.

**Validate.** Case A: gh authed → same `gh` PR creation + `gh issue edit` as today. Case B: no gh → branch pushed, title/body printed in full, one `⚠️` line, run completes (Step 9 is the last step, so "continue" means finishing cleanly rather than reporting failure).

### Step 2 — vcook: PR description language from §4

**File:** `skills/vcook/SKILL.md` (then `SKILL.vi.md`)

**Logic — 2 edits, both required:**

1. **Line 111** — currently: *"Description: **written in Vietnamese**, non-technical — for readers who aren't engineers, focused on user/business impact, no code jargon."* Replace the language clause only: *"Description: written in the project's communication language (resolve per `repo-profile.md` §4: project `CLAUDE.md` → `~/.claude/CLAUDE.md` → English; if the file is absent, Vietnamese), non-technical — …"*. The rest of the sentence is unchanged: non-technical, business impact, no jargon is style, not language.

2. **Line 126 (Hard rules)** — currently: *"**PR description** → in Vietnamese, non-technical, following `.github/pull_request_template.md` exactly if it exists"*. Same replacement: "in the §4-resolved language". Leaving this line stale would contradict Step 9 — the model reads both.

3. Title (line 110) stays "English, concise" in all cases — commit/branch/PR titles are already English-by-convention across this skill pack (`:38`, `:105`) and conventional-commit prefixes are English anyway. Do not route the title through §4.

**Validate.** `grep -n "Vietnamese\|tiếng Việt" skills/vcook/SKILL.md` → only inside the §4 fallback clause. Case A: `~/.claude/CLAUDE.md` has `## Ngôn ngữ` → Vietnamese description, i.e. today's output. Case B: no language section anywhere → English description, same structure and template conformance.

### Step 3 — vreview: PR-ref resolution degrade

**File:** `skills/vreview/SKILL.md` (then `SKILL.vi.md`)

**Logic — 3 edits inside Phase 1.1 (lines 45-147):**

1. **Top of Phase 1.1**, right after `1.1 Determine the changes` (line 53 <!-- Updated: Validation Session 1 - corrected from line 45, verified via grep -->), add a short "resolve the repo profile first" block: §2 (host + gh) and §3 (language tally, used from Phase 2 on). Fallback if absent: GitHub + gh + TypeScript, i.e. today's assumptions.

2. **`RESOLVE PR REFS` block (lines 79-107)** — the form-detection at lines 81-84 is regex-only, keep it. Gate the `gh pr view` call (lines 87-90) on full gh mode; degraded → print the §2 vreview message (`⚠️ can't resolve PR refs without gh — pass a branch name`), drop that positional arg from `branch_list`, and **continue with the remaining args**; if `branch_list` ends up empty, fall back to reviewing HEAD (the documented no-arg behavior at line 77) rather than aborting. Leave the OPEN/MERGED/CLOSED state handling (lines 92-107) unchanged — it is only reachable in full gh mode.

3. **Base-branch auto-detect (lines 116-120)** — point 1 ("take baseRefName from `gh pr view`") is gh-only; add "skip to point 2 in degraded mode". Points 2-4 (`git symbolic-ref` → `main` → `master`) already work everywhere; unchanged.

**Validate.** Case A: `vreview #947` → identical `gh pr view --json headRefName,state,mergeCommit,baseRefName` call. Case B: `vreview feat/x --base develop` with no gh → runs fully, zero gh calls; `vreview #947` with no gh → one `⚠️`, falls back to HEAD, review still produces a report.

### Step 4 — vreview: non-JS lockfiles in the boilerplate filter

**File:** `skills/vreview/SKILL.md` line 182 (then `SKILL.vi.md`)

**Logic.** Line 182 currently lists `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb` — JS coverage is complete, leave it. Append the non-JS lockfiles as a sibling bullet in the same 1.3b list (lines 177-184): `Cargo.lock`, `go.sum`, `poetry.lock`, `Gemfile.lock`, `composer.lock` — lockfiles, other ecosystems. Static list, no detection needed: filtering `Cargo.lock` in a repo that has none is a no-op. Do not touch the other 1.3b patterns.

**Validate.** Re-read lines 175-186; excluded files still get written to the CONTEXT.txt "BOILERPLATE SKIPPED" section (line 186) for transparency. Case A unaffected — no JS project contains these files.

### Step 5 — vreview: language-scoped rule application

**File:** `skills/vreview/SKILL.md` (then `SKILL.vi.md`)

**Logic — 2 edits:**

1. **Phase 1.1 profile block (from step 3 above)** — add the normative sentence: the diff's primary language and per-file language tally come from §3; a CLAUDE.md rule that names a language or framework (TypeScript rules, React/Next.js rules, Tailwind rules) applies **only** to files of that language/framework in the diff. A `.py` or `.go` file in the diff must not be flagged against a TypeScript rule. Where no rule applies to a file's language, review it on general principles (naming, error handling, security, dead code) rather than skipping it.

2. **Phase 1.5 output / CONTEXT.txt (around lines 195-230)** — add one line to the CONTEXT.txt header capturing the resolved profile, e.g. `PROFILE: lang=TypeScript(12) Python(2) · framework=Next.js · host=github(gh) · pm=pnpm`. This is what carries §3 into the Phase 2 subagents, which read CONTEXT.txt instead of re-detecting. One line, not a section.

**Validate.** Case A: an all-`.ts/.tsx` diff → the tally is 100% TypeScript, every TypeScript rule applies exactly as today; `PROFILE:` is one extra informational line, no finding changes. Case B: a mixed `.py`/`.ts` diff → TypeScript rules raise findings on the `.ts` files only. Confirm the file-list format at lines 221-222 and the severity taxonomy are untouched.

## Todo list

- [x] vcook: Step 9 gh degrade (PR + `gh issue edit`)
- [x] vcook: line 111 language → §4
- [x] vcook: line 126 Hard rules language → §4
- [x] vcook `.vi.md` mirrored (both language edits + degrade)
- [x] vreview: Phase 1.1 profile block (§2 + §3)
- [x] vreview: PR-ref + base-detect degrade
- [x] vreview: line 182 non-JS lockfiles
- [x] vreview: `PROFILE:` line in CONTEXT.txt header
- [x] vreview `.vi.md` mirrored
- [x] Case A / Case B walkthrough for both skills

## Success Criteria

- [x] Case A `vcook`: PR description resolves to Vietnamese, same style wording, same `gh` PR + `gh issue edit` calls as today
- [x] Case A `vreview`: `#947` resolution issues the identical `gh pr view` command; findings unchanged on an all-TS diff
- [x] Case B `vcook`: English description, full title+body printed, branch pushed, run completes without an abort
- [x] Case B `vreview`: branch/`--path`/`--since` modes make zero gh calls and produce a report; a PR ref degrades to one `⚠️` + HEAD fallback
- [x] `grep -n "Vietnamese" skills/vcook/SKILL.md` → only the §4 fallback clause (no stale Hard-rules copy)
- [x] `vreview` 1.3b lists `Cargo.lock`, `go.sum`, `poetry.lock`, `Gemfile.lock`, `composer.lock` alongside the 4 JS lockfiles
- [x] `vreview` phase structure, severity taxonomy, subagent fan-out unchanged (diff confined to Phase 1.1, 1.3b, 1.5)
- [x] `skills/vreview/SKILL.md:631` extension guard untouched
- [x] Both `.vi.md` files structurally match their `.md`

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Only one of vcook's two Vietnamese mentions (`:111`, `:126`) is updated → skill contradicts itself, model picks arbitrarily | **High** (easy to miss) | **High** (wrong-language PRs) | Both listed as separate todos; grep criterion catches a stale copy |
| §4 resolves to English on the author's machine (section heading not matched) → PRs silently switch language | Low | **High** (visible to the author's team) | §4 matches both `## Ngôn ngữ` and `## Language`, and the *absent-file* fallback is Vietnamese, not English; Case A walkthrough is blocking |
| Editing a 698-line file damages the Phase 2-4 structure | Medium | High | Edits confined to 3 named blocks (1.1, 1.3b, 1.5); structure-unchanged criterion |
| Degraded `vreview` empties `branch_list` and the run stalls | Medium | Medium | Explicit HEAD fallback reusing the documented no-arg behavior at `:77` |
| §3 language scoping gets read as "skip non-TS files entirely" → review coverage silently shrinks | Medium | **High** (missed findings) | The rule text explicitly says: review non-matching-language files on general principles, never skip |
| `PROFILE:` line inflates every CONTEXT.txt and subagent prompt | Certain | Negligible | Capped at one line |
| `.vi.md` drift | High | Medium | Paired todos + structural-parity criterion |

## Security considerations

`vreview` is the security-review skill — the §3 language scoping must not weaken it. Security-class checks (secrets in code, injection, authz) are language-agnostic and stay applied to **every** file regardless of the tally; only language/framework-*specific* style and API rules are scoped. State that explicitly in the step-5 sentence. Also: the `PROFILE:` line records the host name only, never the remote URL (credentials).

## Next steps

After phases 2 and 3 land: re-run `./install.sh --dry-run` and `--lang=vi --dry-run` once, then dogfood on the author's own repo — run `/vcheck` and `/vreview` on a real branch and confirm the emitted commands match the pre-change ones. That dogfood run is the real regression test; the tabletop walkthroughs are only a pre-check.
