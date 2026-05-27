# my-skills

Personal Claude Code skills + scripts. Clone & run `./install.sh` to set up.

## Structure

```
my-skills/
├── install.sh          # copy files to ~/.claude
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
└── scripts/
    └── <script-name>/  # e.g. lint-rules
        └── ...
```

## Install

```bash
git clone git@github.com:vyvu99/my-skills.git
cd my-skills
chmod +x install.sh
./install.sh
```

Dry-run to preview what will be copied:

```bash
./install.sh --dry-run
```

## Add a new skill

```bash
mkdir skills/<skill-name>
cp ~/.claude/skills/<skill-name>/SKILL.md skills/<skill-name>/
git add . && git commit -m "feat: add <skill-name> skill"
```

## Sync lint rules after Phase 5 harvest

```bash
cp .code-review/staged-lint-rules/*.sh scripts/lint-rules/rules/
git add . && git commit -m "feat(lint): add <rule-name> rule"
git push
```

## Sync SKILL.md changes back to repo

```bash
cp ~/.claude/skills/vreview/SKILL.md skills/vreview/SKILL.md
git add . && git commit -m "chore(vreview): sync SKILL.md"
git push
```
