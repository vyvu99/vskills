---
phase: 1
title: Shared repo-profile foundation
status: completed
priority: P1
effort: 1.5h
dependencies: []
blocks:
  - 2
  - 3
---

# Phase 1: Shared repo-profile foundation

## Overview

Create the single source of truth for stack detection — `skills/_vskills-shared/repo-profile.md` — and make `install.sh` ship it to `~/.claude/skills/_vskills-shared`. Nothing consumes it yet; phases 2 and 3 do the wiring. Section numbering (§1–§4) is frozen at the end of this phase, since every later pointer cites it.

Blocks phases 2 and 3.

## Key insights (from scout)

- `install.sh:46` loops `for skill_dir in "$SKILLS_SRC"/*/` and links `${skill_dir}SKILL.md` per directory. A new `skills/_vskills-shared/` directory is caught by that glob.
- `link()` (`install.sh:25-36`) never checks that `src` exists — `ln -s` happily creates a **broken** symlink. So the failure mode of forgetting to exclude `_vskills-shared` is *silent*: `~/.claude/skills/_vskills-shared/SKILL.md` → nonexistent target, and Claude Code sees a malformed skill dir. This is why exclusion must land in the same change as the new directory.
- `install.sh:30-31` (`rm -rf "$dst"` when dst exists but isn't a symlink) means a previously-created broken `~/.claude/skills/_vskills-shared/` directory is cleaned up automatically on the next run. No manual cleanup instructions needed.
- `--lang=vi` (`install.sh:49-51`) only swaps `SKILL.md` → `SKILL.vi.md`. `_vskills-shared` is symlinked at directory level, so both language installs read the same English `repo-profile.md`. Intentional.

## Requirements

**Functional**
1. `skills/_vskills-shared/repo-profile.md` exists, written in English, matching the register of the existing `SKILL.md` files (imperative, terse, code fences for command templates).
2. Exactly 4 sections numbered `## §1` … `## §4`, each with: detection criteria in priority order → fallback → worked example.
3. Every command template in §1 is verified to produce today's exact command for the pnpm+workspace case.
4. `install.sh` always symlinks `skills/_vskills-shared` → `~/.claude/skills/_vskills-shared` (not gated behind `--with-scripts` or any flag).
5. `install.sh` no longer attempts to link `_vskills-shared/SKILL.md`.
6. `README.md` + `README.vi.md` maintainer trees mention the new directory.

**Non-functional**
- `repo-profile.md` ≤ ~130 lines. It is read at the start of a skill run; every line is a token tax on 6 skills.
- No frontmatter, no `user-invocable`, no `name:` field — it must not register as a skill / slash command.

## Architecture

```
skills/_vskills-shared/repo-profile.md          (new, plain reference doc — no frontmatter)
        ▲            ▲            ▲
        │            │            │   "read ~/.claude/skills/_vskills-shared/repo-profile.md §N
        │            │            │    if present; else assume <today's default>"
   vcheck §1    vissues §2    vcook §2,§4        (phases 2-3)
   vrules §2    vdesign §2,§3  vreview §2,§3

install.sh ── link(dir-level) ──> ~/.claude/skills/_vskills-shared/repo-profile.md
```

Data flow at skill runtime: skill reads repo-profile.md → runs the listed detection commands against the *current working repo* → gets a resolved profile (pm, workspace?, host, cli?, lang, framework, pr-lang) → substitutes into its own command templates. Detection is read-only (`cat package.json`, `ls` lockfiles, `git remote get-url`, `gh auth status`); it never writes.

## Related code files

**Create**
- `skills/_vskills-shared/repo-profile.md`

**Modify**
- `install.sh` — lines 45-57 (skill loop) + a new block after it
- `README.md` — lines 150-155 (maintainer structure tree)
- `README.vi.md` — lines 151-156 (same tree, Vietnamese comments)

**Delete** — none.

## Implementation Steps

### Step 1 — Write `skills/_vskills-shared/repo-profile.md`

**File:** `skills/_vskills-shared/repo-profile.md` (new)

**Logic.** Open with 3 lines of preamble: what this file is (shared detection reference for the v* skills), that it is not a skill, and the rule "detect once per run, reuse the result; if a signal is ambiguous, ask the user rather than guessing." Then 4 sections:

**`## §1 — Package manager + workspace shape`**
- Detection order:
  1. `packageManager` field in root `package.json` (corepack format `"pnpm@9.1.0"`) → take the part before `@`.
  2. No such field → lockfile: `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `bun.lockb`→bun, `package-lock.json`→npm.
  3. Multiple lockfiles present → prefer the `packageManager` field; if that is also absent, ask the user (do not guess).
  4. No JS lockfile and no `package.json` → not a JS/TS project: skip every step that runs a package-manager command and say so in one line.
- Workspace shape: `pnpm-workspace.yaml` exists, or root `package.json` has a `workspaces` field → **monorepo**; otherwise **single-package** (drop `--filter`/`-w` entirely, run at root).
- Command template table (both columns required):

  | pm | in a workspace package | at root |
  |----|------------------------|---------|
  | pnpm | `pnpm --filter <pkg> exec <cmd>` | `pnpm exec <cmd>` |
  | yarn | `yarn workspace <pkg> <cmd>` | `yarn <cmd>` |
  | npm | `npm exec -w <pkg> -- <cmd>` | `npm exec -- <cmd>` |
  | bun | `bun --filter <pkg> <cmd>` | `bun <cmd>` |

- Script resolution: before falling back to a raw binary, read `scripts` in the target `package.json` and prefer a declared script — `typecheck` → `type-check` → `tsc --noEmit` (raw); `build` → declared `build` only (no raw fallback, a package with no `build` script has nothing to build). Same idea for `format` (`format` → `format:fix`) and test (`test:run` → `test:ci` → `test`).
- Worked example, stated explicitly as the regression anchor: *pnpm + `pnpm-workspace.yaml` + no `typecheck` script → `pnpm --filter @app/api exec tsc --noEmit`* — byte-identical to `skills/vcheck/SKILL.md:40` today.
- Note on confidence: the pnpm row is the regression anchor and must stay byte-identical (it's the author's daily case). The yarn/npm/bun rows are best-effort, derived from each tool's documented workspace syntax, not exercised against a real yarn/npm/bun monorepo yet — mark them in the file as `<!-- best-effort, unverified against a real repo -->` so a future skill run that hits a syntax error knows to fix the template, not just work around it once. <!-- Updated: Validation Session 1 - risk accepted, documented instead of adding a pre-merge verification step -->

**`## §2 — VCS host + CLI availability`**
- Detection order:
  1. `git remote get-url origin` → empty/error → **local-only**: skip every PR/issue step, print one line telling the user why, continue with the rest of the skill.
  2. URL host is `github.com` (handle both `git@github.com:owner/repo.git` and `https://github.com/owner/repo(.git)`) **and** `gh auth status` exits 0 → **full gh mode**, use `gh` exactly as the skills do today.
  3. Host is github.com but `gh` is missing or unauthenticated → **degraded**.
  4. Host is anything else → **degraded**.
- Owner/repo parse (single canonical snippet, used by every skill instead of re-deriving it — replaces the ad-hoc parse at `skills/vrules/SKILL.md:34`): strip a trailing `.git`, take the last two path segments → `<owner>/<repo>`.
- Degraded-mode contract — this is the whole point of the section, spell it out as rules:
  - Print exactly one `⚠️` line naming what is unavailable and why.
  - Follow it with concrete manual steps for the action that was skipped.
  - **Continue the rest of the skill.** Never abort the run because a host feature is missing.
  - Never invent a substitute CLI (`glab`, `tea`, …) — not supported, by decision.
- Per-skill degraded messages, listed in the file so each skill just cites §2 (author them here; phases 2-3 only reference them):
  - PR creation (vcook): `⚠️ gh unavailable / non-GitHub remote — commits are pushed, open the PR manually on your host. Suggested title: <title>. Body below.` then print the body.
  - Issue sync (vissues): `⚠️ Sub-issue linking uses GitHub's addSubIssue GraphQL mutation, which has no equivalent on other hosts — create the epic + sub-issues manually and link them by hand.` then print the ready-to-paste issue bodies.
  - PR-comment fetch (vrules): `⚠️ Can't fetch review comments without gh — paste the bot's review comments and I'll continue from Step 3.`
  - PR diff (vdesign, vreview): `⚠️ Can't resolve PR refs without gh — pass a branch name instead; branch/diff modes work without gh.`

**`## §3 — Primary language + framework`**
- Language: count file extensions across the reviewed diff (or the repo when there is no diff) — `.ts/.tsx`→TypeScript, `.js/.jsx`→JavaScript, `.py`→Python, `.go`→Go, `.rs`→Rust, etc. The winner is the *primary* language; keep the full tally, since a mixed diff means language-specific rules apply per file, not per run.
- Framework signal, first match wins: `next` dependency or `next.config.*` → Next.js; `nuxt.config.*` → Nuxt; `astro.config.*` → Astro; `svelte.config.*` → SvelteKit; `vite.config.*` + a `react-router*` dep → Vite/React Router; `remix.config.*` → Remix. No match → **generic**.
- Consumption rules (write them as rules, not prose): apply a language-specific rule **only to files of that language** — a CLAUDE.md TypeScript rule must not be raised on a `.py` file. Framework-specific component names (`next/image`, `next/link`) are only valid under the matching framework; under `generic`, say "the framework's image/link component" or ask the user which one the project uses. Never assume Next.js from the presence of React alone.

**`## §4 — PR / communication language`**
- Resolution order: the current project's `CLAUDE.md` (look for a `## Ngôn ngữ` or `## Language` section) → `~/.claude/CLAUDE.md` (same section names) → **English**.
- Output of the section is one value, `pr_language`, consumed wherever a skill writes prose for humans (PR body, issue body).
- State the anchor: on the author's machine `~/.claude/CLAUDE.md` has `## Ngôn ngữ` → resolves to Vietnamese → identical to the hardcoded behavior at `skills/vcook/SKILL.md:111` today.
- Style is *not* language: "non-technical, business-impact focused" stays fixed regardless of which language wins.

**Validate.** Read the file back and walk Case A through all 4 sections by hand: pnpm+workspace → `pnpm --filter <pkg> exec tsc --noEmit`; github.com + gh authed → full gh mode; `.ts/.tsx` + `next` dep → TypeScript/Next.js; `~/.claude/CLAUDE.md` has `## Ngôn ngữ` → Vietnamese. All four must match today's hardcoded values exactly. Then confirm `wc -l` ≤ ~130 and that the file has no `---` frontmatter block.

### Step 2 — Exclude `_vskills-shared` from the per-skill symlink loop

**File:** `install.sh`, inside the loop at lines 46-56.

**Logic.** Immediately after `skill_name="$(basename "$skill_dir")"` (line 47), add a guard: `[[ "$skill_name" == _* ]] && continue`. Prefix-based (not an exact `_vskills-shared` match) so any future `_`-prefixed shared directory is excluded for free — and it is one line, cheaper than maintaining a list. Add a short comment above it: shared dirs are not skills, they are linked whole below.

**Validate.** `./install.sh --dry-run` — the output must contain no line mentioning `_vskills-shared/SKILL.md`, and must still list all 10 real skills.

### Step 3 — Always symlink `skills/_vskills-shared`

**File:** `install.sh`, new block placed after the skill loop closes (`fi` at line 57) and **before** the `if $WITH_SCRIPTS` block at line 60.

**Logic.**
```bash
# ── Shared reference docs (always installed — skills read these at runtime) ──
[[ -d "$SKILLS_SRC/_vskills-shared" ]] && link "$SKILLS_SRC/_vskills-shared" "$SKILLS_DST/_vskills-shared"
```
Directory-level link (unlike skills, which are linked per-file for `--lang`) because `repo-profile.md` has no language variants. Must sit outside every `if $WITH_*` branch — this is not opt-in.

**Validate.** `./install.sh --dry-run` prints `linked: ~/.claude/skills/_vskills-shared → <repo>/skills/_vskills-shared`. Then run the real `./install.sh` and confirm `readlink ~/.claude/skills/_vskills-shared` resolves and `cat ~/.claude/skills/_vskills-shared/repo-profile.md | head -3` works — the path phases 2-3 will cite must be live.

### Step 4 — Update the maintainer structure trees

**Files:** `README.md` lines 150-155; `README.vi.md` lines 151-156.

**Logic.** In both fenced trees, add a line above the `scripts/` entry:
- `README.md`: `├── skills/_vskills-shared/repo-profile.md   # shared stack-detection reference, always symlinked (not opt-in)`
- `README.vi.md`: same position, Vietnamese comment: `# reference detect stack dùng chung, luôn symlink (không opt-in)`

Reorder the box-drawing characters so the last entry keeps `└──`. Do not add a new README section — inline patch only.

**Validate.** Re-read both fenced blocks; tree characters consistent, `scripts/` line still last with `└──`.

## Todo list

- [x] Write `skills/_vskills-shared/repo-profile.md` (§1–§4)
- [x] Case A walkthrough against the finished file — all 4 sections resolve to today's values
- [x] `install.sh`: `_*` guard in the skill loop
- [x] `install.sh`: unconditional `_vskills-shared` dir link
- [x] `README.md` + `README.vi.md` structure trees
- [x] `./install.sh --dry-run` clean; real install verified via `readlink`

## Success Criteria

- [x] `skills/_vskills-shared/repo-profile.md` exists, no frontmatter, ≤ ~130 lines, exactly 4 numbered sections
- [x] `./install.sh --dry-run` exits 0, output contains a `_vskills-shared` link line and **zero** `_vskills-shared/SKILL.md` lines
- [x] After a real `./install.sh`, `~/.claude/skills/_vskills-shared/repo-profile.md` is readable through the symlink
- [x] `./install.sh --lang=vi --dry-run` also links `_vskills-shared` (unchanged by the lang flag) and still picks `SKILL.vi.md` for the 10 skills
- [x] Case A tabletop: §1 → `pnpm --filter <pkg> exec tsc --noEmit`, §2 → full gh mode, §3 → TypeScript/Next.js, §4 → Vietnamese
- [x] Case B tabletop: §1 → `npm exec -- <cmd>` (no `--filter`), §2 → degraded + `⚠️` + manual steps, §3 → Python/generic, §4 → English
- [x] `README.md` + `README.vi.md` trees list `skills/_vskills-shared/`
- [x] Zero behavior change for the 10 existing skills (no skill file touched in this phase)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Loop links a broken `_vskills-shared/SKILL.md` — silent, because `link()` never validates `src` (`install.sh:25-36`) | High if step 2 is skipped | Medium — malformed skill dir in `~/.claude/skills` | Steps 2 and 3 land in the same commit as the new directory; dry-run grep for `_vskills-shared/SKILL.md` is an explicit success criterion |
| Stale broken `~/.claude/skills/_vskills-shared/` from a half-done attempt | Low | Low | `install.sh:30-31` `rm -rf`s a non-symlink dst on the next run — self-healing, no manual step |
| §1 command template drifts from today's pnpm command → phase 2 wires in a wrong command | Medium | **High** (breaks the author's daily `vcheck`) | Case A walkthrough is a blocking criterion; §1 carries the pnpm example inline as the regression anchor |
| Section numbers renumbered later → every phase 2-3 pointer dangles | Medium | Medium | Numbering frozen at end of this phase; a future section is appended as §5, never inserted |
| `repo-profile.md` bloats into an essay → token cost on every run of 6 skills | Medium | Low | ≤130-line cap as a success criterion |
| `--lang=vi` users get an English reference doc | Certain (by design) | Low | Documented decision in plan.md open questions; it is model-facing text, not user-facing |

## Security considerations

Detection is read-only and local: reading `package.json`/lockfile names, `git remote get-url origin`, `gh auth status` (which prints account/scopes, never a token). §2 must state: print the *host* of the remote, never the full URL, since a remote can embed credentials (`https://user:token@host/...`). Add that as an explicit line in §2.

## Next steps

Unblocks phases 2 and 3, which can then run in parallel (disjoint file ownership).
