# Contributing

Bug reports, ideas and pull requests are welcome. For a large change, open an issue first so we can agree on the direction.

## Repo layout

| Path | Purpose |
|---|---|
| `skills/<name>/SKILL.md`, `SKILL.vi.md` | One skill, English and Vietnamese with the same line count |
| `skills/_vskills-shared/` | Reference docs shared by skills |
| `claude-md/CLAUDE.md` | Starter rules for `--with-rules` |
| `evals/` | Trigger and behavior evals (`scripts/run-evals.sh`, calls `claude -p`, billable) |
| `web/` | Local webapp used by `vspecs` and `vreview --fix` |
| `scripts/` | Opt-in tools: `lint-rules`, `job-queue` |

## Adding or changing a skill

```bash
mkdir skills/<name>              # add SKILL.md and SKILL.vi.md
./install.sh
```

To remove a skill, delete its folder, grep for cross-references, and re-run `./install.sh`.

## Checks

CI runs these on every pull request. Run them before you push:

```bash
node scripts/check-skills.js     # frontmatter, description length, EN/VI parity, shared-file and § pointers
./scripts/test-install.sh        # installer, against a throwaway HOME
node --test web/server.test.mjs  # webapp server
```

If you change the job queue, also run `scripts/job-queue/check-jobq`.

## Pull requests

- One topic per pull request.
- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`…).
- Update both language versions of any skill or README you touch.
- Keep project names, local paths and secrets out of skills and examples.

By contributing, you agree that your work is released under the [AGPL-3.0](LICENSE) license.
