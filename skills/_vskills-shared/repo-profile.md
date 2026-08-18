Shared detection reference for the v* skills. Not a skill — no frontmatter, not invocable.

Detect each section once per run and reuse the result. If a signal is ambiguous, ask the user rather than guessing.

## §1 — Package manager + workspace shape

Detection order:
1. `packageManager` field in root `package.json` (corepack format `"pnpm@9.1.0"`) → take the part before `@`.
2. No such field → lockfile: `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `bun.lockb`→bun, `package-lock.json`→npm.
3. Multiple lockfiles present → prefer the `packageManager` field; if that is also absent, ask the user (do not guess).
4. No JS lockfile and no `package.json` → not a JS/TS project: skip every step that runs a package-manager command and say so in one line.

Workspace shape: `pnpm-workspace.yaml` exists, or root `package.json` has a `workspaces` field → **monorepo**; otherwise **single-package** (drop `--filter`/`-w` entirely, run at root).

Command template:

| pm | in a workspace package | at root |
|----|------------------------|---------|
| pnpm | `pnpm --filter <pkg> exec <cmd>` | `pnpm exec <cmd>` |
| yarn | `yarn workspace <pkg> <cmd>` | `yarn <cmd>` |
| npm | `npm exec -w <pkg> -- <cmd>` | `npm exec -- <cmd>` |
| bun | `bun --filter <pkg> <cmd>` | `bun <cmd>` |

<!-- best-effort, unverified against a real repo: pnpm row is the regression anchor and must stay exact; yarn/npm/bun rows are derived from each tool's documented workspace syntax, not exercised against a real yarn/npm/bun monorepo yet — fix the template (not just the one call) if a real run hits a syntax error. -->

Script resolution — prefer a declared `package.json` script before a raw binary:
- typecheck: `typecheck` → `type-check` → `tsc --noEmit` (raw)
- build: declared `build` script only — no raw fallback, nothing to build without one
- format: `format` → `format:fix`
- test: `test:run` → `test:ci` → `test`

Worked example (regression anchor): pnpm + `pnpm-workspace.yaml` + no `typecheck` script → `pnpm --filter @app/api exec tsc --noEmit`.

## §2 — VCS host + CLI availability

Detection order:
1. `git remote get-url origin` → empty/error → **local-only**: skip every PR/issue step, print one line why, continue with the rest of the skill.
2. Host is `github.com` (both `git@github.com:owner/repo.git` and `https://github.com/owner/repo(.git)`) **and** `gh auth status` exits 0 → **full gh mode**, use `gh` exactly as normal.
3. Host is github.com but `gh` is missing/unauthenticated → **degraded**.
4. Host is anything else → **degraded**.

Owner/repo parse (single canonical snippet — every skill uses this instead of re-deriving it): strip a trailing `.git`, take the last two path segments → `<owner>/<repo>`.

Degraded-mode contract:
- Print exactly one `⚠️` line naming what is unavailable and why.
- Follow it with concrete manual steps for the skipped action.
- **Continue the rest of the skill.** Never abort a run because a host feature is missing.
- Never invent a substitute CLI (`glab`, `tea`, …) — not supported, by decision.
- Name the remote **host** only in any message, never the full remote URL — a remote can embed credentials (`https://user:token@host/...`).

Per-skill degraded messages:
- **vcook** (PR creation): `⚠️ gh unavailable / non-GitHub remote — commits are pushed, open the PR manually on your host. Suggested title: <title>. Body below.` then print the body.
- **vissues** (sub-issue linking): `⚠️ Sub-issue linking uses GitHub's addSubIssue GraphQL mutation, which has no equivalent on other hosts — create the epic + sub-issues manually and link them by hand.` then print the ready-to-paste issue bodies.
- **vrules** (PR-comment fetch): `⚠️ Can't fetch review comments without gh — paste the bot's review comments and I'll continue from Step 3.`
- **vdesign / vreview** (PR diff / PR-ref resolution): `⚠️ Can't resolve PR refs without gh — pass a branch name instead; branch/diff modes work without gh.`

## §3 — Primary language + framework

Language: count file extensions across the reviewed diff (or the repo when there is no diff) — `.ts/.tsx`→TypeScript, `.js/.jsx`→JavaScript, `.py`→Python, `.go`→Go, `.rs`→Rust, etc. The winner is the primary language; keep the full tally — a mixed diff means language-specific rules apply per file, not per run.

Framework signal, first match wins: `next` dependency or `next.config.*` → Next.js; `nuxt.config.*` → Nuxt; `astro.config.*` → Astro; `svelte.config.*` → SvelteKit; `vite.config.*` + a `react-router*` dep → Vite/React Router; `remix.config.*` → Remix. No match → **generic**.

Consumption rules: apply a language-specific rule only to files of that language — a TypeScript CLAUDE.md rule must not be raised on a `.py` file. Framework-specific component names (`next/image`, `next/link`) are only valid under the matching framework; under `generic`, say "the framework's image/link component" or ask the user which one the project uses. Never assume Next.js from the presence of React alone.

## §4 — PR / communication language

Resolution order: the current project's `CLAUDE.md` (look for a `## Ngôn ngữ` or `## Language` section) → `~/.claude/CLAUDE.md` (same section names) → **English**.

Output is one value, `pr_language`, consumed wherever a skill writes prose for humans (PR body, issue body). Style ("non-technical, business-impact focused") is not language — it stays fixed regardless of which language wins.

Anchor: on the author's machine, `~/.claude/CLAUDE.md` has `## Ngôn ngữ` → resolves to Vietnamese — identical to today's hardcoded behavior.
