# vskills

🌐 English | [Tiếng Việt](README.vi.md)

Claude Code skills for the full life of a coding task: spec, plan, build, review, fix. Each skill is a plain `SKILL.md` symlinked into `~/.claude/skills`. No plugin layer, no config file.

```mermaid
flowchart LR
    idea(["idea / bug"]) --> specs["/vspecs"] --> plan["/vplan"] --> cook["/vcook"] --> review["/vreview"] --> fix["/vreview --fix"] --> ship(["ship"])
    fix -. more issues .-> review
```

## Install

Requires the Claude Code CLI, `git` and `bash`. Optional: `gh` (GitHub skills), Node.js (webapp, lint rules, `check-skills`), `jq` (evals, `jobq` hook and dashboard).

```bash
git clone git@github.com:vyvu99/vskills.git && cd vskills
./install.sh
```

| Flag | Effect |
|---|---|
| `--lang=vi` | Install the Vietnamese variant of every skill |
| `--with-scripts` | Also install lint rules and the `jobq` job queue |
| `--with-claude-md` | Also copy a starter `~/.claude/CLAUDE.md` (skipped if one exists) |
| `--dry-run` | Print what would happen, change nothing |

Skills are symlinks, so editing the repo edits the installed skill. A real file already at a destination is moved to `<path>.bak.<timestamp>`, never deleted. Re-running removes skills that were deleted from the repo.

## Skills

`*` runs only when invoked by hand.

| Skill | What it does | Example |
|---|---|---|
| `vspecs` | Writes plain-language feature specs, deciding edge cases with you | `/vspecs Feature: rebooking` |
| `vplan` | Checks each spec case against the code (PASS/FAIL/MISSING), writes a phased plan | `/vplan plans/specs/rebooking.md` |
| `vcook`* | Branch, tests first, code, review, PR from a plan or a task | `/vcook plans/rebooking` |
| `vreview` | Reviews a diff, PR, branch or directory into `.code-review/REPORT.md`; `--fix` fixes it by priority | `/vreview #482` |
| `vtickets`* | Creates or syncs a GitHub epic and sub-issues from a plan | `/vtickets plans/rebooking` |
| `vci` | Format, typecheck, build, lint (and tests with `--test`) across a JS/TS repo, fixing what fails | `/vci --changed` |
| `vdesign` | Redesigns a page or component: research, audit, fix, verify at 375/768/1280px | `/vdesign /clients/[id]` |
| `vsweep` | Unattended, time-boxed pass over a backlog; unclear items become pending decisions | `/vsweep --until 06:00` |
| `vrollback`* | Rolls back one migration on a local dev database, with confirmation | `/vrollback 0007_add_status` |
| `vguide` | Writes a role-based user guide for a product or feature | `/vguide Feature: checkout` |

Flags and edge cases are in `skills/<name>/SKILL.md`.

## Job queue (optional)

`jobq` keeps the machine responsive when Claude launches heavy commands: it runs a few at a time, limits derived from your CPU and RAM, and reports commands that exceed their time limit so they can be split.

```bash
./install.sh --with-scripts        # links jobq, stepper, lint-script into ~/.local/bin
jobq run -- pnpm --filter api test # queue a command
jobq web                           # live dashboard
```

To make Claude use it, copy the `jobq-guard` hook into `~/.claude/settings.json` (needs `jq`). Details: [`scripts/job-queue/README.md`](scripts/job-queue/README.md).

## Contributing

| Path | Purpose |
|---|---|
| `skills/<name>/SKILL.md`, `SKILL.vi.md` | One skill, English and Vietnamese with the same line count |
| `skills/_vskills-shared/` | Reference docs shared by skills |
| `claude-md/CLAUDE.md` | Starter rules for `--with-claude-md` |
| `evals/` | Trigger and behavior evals (`scripts/run-evals.sh`, calls `claude -p`, billable) |
| `web/` | Local webapp used by `vspecs` and `vreview --fix` |
| `scripts/` | Opt-in tools: `lint-rules`, `job-queue` |

```bash
mkdir skills/<name>              # add SKILL.md and SKILL.vi.md
./install.sh
node scripts/check-skills.js     # frontmatter, description length, EN/VI parity
```

To remove a skill, delete its folder, grep for cross-references, and re-run `./install.sh`.

## License

[AGPL-3.0](LICENSE). Copyright (c) 2026 vyvu.
