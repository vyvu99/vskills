#!/bin/bash
# Install skills + scripts to ~/.claude
# Usage: ./install.sh [--dry-run]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[install] $*"; }
run() { $DRY_RUN && echo "[dry-run] $*" || eval "$*"; }

# ── Skills ────────────────────────────────────────────────────────────────────
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

if [[ -d "$SKILLS_SRC" ]]; then
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name="$(basename "$skill_dir")"
    dst="$SKILLS_DST/$skill_name"
    run "mkdir -p '$dst'"
    run "cp -r '$skill_dir'* '$dst/'"
    log "skill: $skill_name → $dst"
  done
fi

# ── Scripts ───────────────────────────────────────────────────────────────────
SCRIPTS_SRC="$REPO_DIR/scripts"
SCRIPTS_DST="$HOME/.claude/scripts"

if [[ -d "$SCRIPTS_SRC" ]]; then
  for script_dir in "$SCRIPTS_SRC"/*/; do
    name="$(basename "$script_dir")"
    dst="$SCRIPTS_DST/$name"
    run "mkdir -p '$dst'"
    run "cp -r '$script_dir'* '$dst/'"
    log "scripts: $name → $dst"
  done
fi

log "Done."
