#!/bin/bash
# Symlink skills (+ optionally scripts, CLAUDE.md starter) into ~/.claude,
# and remove any previously-installed skill symlinks whose source was since
# deleted from this repo.
# Usage: ./install.sh [--dry-run] [--with-scripts] [--with-claude-md] [--lang=en|vi]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
WITH_SCRIPTS=false
WITH_CLAUDE_MD=false
LANG_CHOICE=en
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --with-scripts) WITH_SCRIPTS=true ;;
    --with-claude-md) WITH_CLAUDE_MD=true ;;
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
    # shared reference dirs (e.g. _shared/) are not skills — linked whole, below
    [[ "$skill_name" == _* ]] && continue
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

# ── Orphaned skills (removed from this repo since the last install) ────────
# A destination whose symlink still points into this repo's skills/ dir, but
# whose source skill dir no longer exists, was deleted upstream — clean it up
# so it doesn't linger as a dangling symlink. Only touches entries this script
# itself created (target resolves under $SKILLS_SRC); anything else is left alone.
if [[ -d "$SKILLS_DST" ]]; then
  for dst_skill_dir in "$SKILLS_DST"/*/; do
    dst_skill_dir="${dst_skill_dir%/}"
    skill_name="$(basename "$dst_skill_dir")"
    [[ "$skill_name" == _* ]] && continue
    if [[ -L "$dst_skill_dir" ]]; then
      target="$(readlink "$dst_skill_dir")"
    elif [[ -L "$dst_skill_dir/SKILL.md" ]]; then
      target="$(readlink "$dst_skill_dir/SKILL.md")"
    else
      continue
    fi
    case "$target" in
      "$SKILLS_SRC"/*) ;;
      *) continue ;;
    esac
    [[ -d "$SKILLS_SRC/$skill_name" ]] && continue
    run "rm -rf '$dst_skill_dir'"
    log "removed orphaned skill: $skill_name (no longer in this repo)"
  done
fi

# ── Shared reference docs (always installed — skills read these at runtime) ──
[[ -d "$SKILLS_SRC/_vskills-shared" ]] && link "$SKILLS_SRC/_vskills-shared" "$SKILLS_DST/_vskills-shared"

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

# ── CLAUDE.md starter (opt-in, never overwrites an existing one) ───────────
# Copied, not symlinked: this is a personal file you're meant to edit right
# away, not something that should silently change when the repo updates.
if $WITH_CLAUDE_MD; then
  CLAUDE_MD_SRC="$REPO_DIR/claude-md/CLAUDE.md"
  CLAUDE_MD_DST="$HOME/.claude/CLAUDE.md"

  if [[ -e "$CLAUDE_MD_DST" ]]; then
    log "WARNING: $CLAUDE_MD_DST already exists — not touching it. Skipping --with-claude-md."
  elif [[ -f "$CLAUDE_MD_SRC" ]]; then
    run "cp '$CLAUDE_MD_SRC' '$CLAUDE_MD_DST'"
    log "copied starter CLAUDE.md → $CLAUDE_MD_DST (edit freely, not synced with this repo)"
  fi
else
  log "skipped CLAUDE.md starter — pass --with-claude-md to install (only applies if you don't already have one)"
fi

log "Done. (lang: $LANG_CHOICE)"
