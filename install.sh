#!/bin/bash
# Symlink skills (+ optionally scripts) into ~/.claude
# Usage: ./install.sh [--dry-run] [--with-scripts] [--lang=en|vi]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
WITH_SCRIPTS=false
LANG_CHOICE=en
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --with-scripts) WITH_SCRIPTS=true ;;
    --lang=*) LANG_CHOICE="${arg#--lang=}" ;;
  esac
done

log() { echo "[install] $*"; }
run() { $DRY_RUN && echo "[dry-run] $*" || eval "$*"; }

# link <src> <dst> — symlinks dst → src, replacing whatever was there
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    [[ "$(readlink "$dst")" == "$src" ]] && { log "up to date: $dst"; return; }
    run "rm '$dst'"
  elif [[ -e "$dst" ]]; then
    run "rm -rf '$dst'"
  fi
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -s '$src' '$dst'"
  log "linked: $dst → $src"
}

# ── Skills (always installed) ───────────────────────────────────────────────
# SKILL.md itself is symlinked per-file (not the whole dir) so --lang can pick
# SKILL.md (English, default) or SKILL.<lang>.md (e.g. SKILL.vi.md) as the source
# while the destination filename stays exactly "SKILL.md", as Claude Code requires.
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

if [[ -d "$SKILLS_SRC" ]]; then
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name="$(basename "$skill_dir")"
    src_file="${skill_dir}SKILL.md"
    if [[ "$LANG_CHOICE" != "en" && -f "${skill_dir}SKILL.$LANG_CHOICE.md" ]]; then
      src_file="${skill_dir}SKILL.$LANG_CHOICE.md"
    fi
    dst_dir="$SKILLS_DST/$skill_name"
    # clean up an older dir-level symlink from a previous install.sh version
    [[ -L "$dst_dir" ]] && run "rm '$dst_dir'"
    link "$src_file" "$dst_dir/SKILL.md"
  done
fi

# ── Scripts (opt-in — personal lint rules, may not fit your codebase) ──────
if $WITH_SCRIPTS; then
  SCRIPTS_SRC="$REPO_DIR/scripts"
  SCRIPTS_DST="$HOME/.claude/scripts"

  if [[ -d "$SCRIPTS_SRC" ]]; then
    for script_dir in "$SCRIPTS_SRC"/*/; do
      name="$(basename "$script_dir")"
      link "${script_dir%/}" "$SCRIPTS_DST/$name"
    done
  fi
else
  log "skipped scripts/ (lint rules) — pass --with-scripts to install"
fi

log "Done. (lang: $LANG_CHOICE)"
