#!/bin/bash
# Symlink skills (+ optionally scripts, CLAUDE.md starter) into ~/.claude,
# and remove any previously-installed skill symlinks whose source was since
# deleted from this repo.
# Usage: ./install.sh [--dry-run] [--with-scripts] [--with-claude-md] [--lang=en|vi] [--target=<list>] [--help]
# --target: comma list of claude (default), codex, gemini, copilot, opencode, kiro, commandcode, agents, all.
#   Each links the skills into that CLI's skills folder; --with-claude-md copies the starter rules into
#   that CLI's instruction file (CLAUDE.md / AGENTS.md / GEMINI.md / copilot-instructions.md).
#   codex and agents both use ~/.agents/skills, the shared folder several other CLIs also read.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
WITH_SCRIPTS=false
WITH_CLAUDE_MD=false
LANG_CHOICE=en
TARGET=claude
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --with-scripts) WITH_SCRIPTS=true ;;
    --with-claude-md) WITH_CLAUDE_MD=true ;;
    --lang=*) LANG_CHOICE="${arg#--lang=}" ;;
    --target=*) TARGET="${arg#--target=}" ;;
    -h|--help) sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[install] unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

case "$LANG_CHOICE" in
  en|vi) ;;
  *) echo "[install] unsupported --lang=$LANG_CHOICE (use en or vi)" >&2; exit 2 ;;
esac

# target_info <name> — sets SK (skills folder) and MD (instruction file, empty if none)
target_info() {
  case "$1" in
    claude)      SK="$HOME/.claude/skills";          MD="$HOME/.claude/CLAUDE.md" ;;
    codex)       SK="$HOME/.agents/skills";          MD="$HOME/.codex/AGENTS.md" ;;
    gemini)      SK="$HOME/.gemini/skills";          MD="$HOME/.gemini/GEMINI.md" ;;
    copilot)     SK="$HOME/.copilot/skills";         MD="$HOME/.copilot/copilot-instructions.md" ;;
    opencode)    SK="$HOME/.config/opencode/skills"; MD="$HOME/.config/opencode/AGENTS.md" ;;
    kiro)        SK="$HOME/.kiro/skills";            MD="" ;;
    commandcode) SK="$HOME/.commandcode/skills";     MD="$HOME/.commandcode/AGENTS.md" ;;
    agents)      SK="$HOME/.agents/skills";          MD="" ;;
    *) return 1 ;;
  esac
}
[[ "$TARGET" == all ]] && TARGET="claude,codex,gemini,copilot,opencode,kiro,commandcode"
IFS=',' read -ra TARGETS <<< "$TARGET"
for t in "${TARGETS[@]}"; do
  target_info "$t" || { echo "[install] unsupported --target=$t (use claude, codex, gemini, copilot, opencode, kiro, commandcode, agents or all)" >&2; exit 2; }
done
log() { echo "[install] $*"; }
run() { $DRY_RUN && echo "[dry-run] $*" || eval "$*"; }

# link <src> <dst> — symlinks dst → src. An existing symlink is replaced; an existing real
# file/dir (e.g. your own ~/.claude/scripts/lint-rules with personal rules) is moved aside to
# <dst>.bak.<timestamp> instead of deleted, so nothing of yours is lost.
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    [[ "$(readlink "$dst")" == "$src" ]] && { log "up to date: $dst"; return; }
    run "rm '$dst'"
  elif [[ -e "$dst" ]]; then
    run "mv '$dst' '$dst.bak.$(date +%Y%m%d%H%M%S)'"
    log "backed up existing $dst"
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
install_skills() {
  local SKILLS_DST="$1"

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
      # references/ (if the skill has one) is symlinked whole — unlike SKILL.md,
      # it isn't subject to --lang per-file selection, so any skill with a
      # references/ dir gets it (generic, not hardcoded to a specific skill).
      [[ -d "${skill_dir}references" ]] && link "${skill_dir}references" "$dst_dir/references"
      # scripts/ (if the skill has one) is symlinked whole, same as references/ —
      # e.g. a bundled helper script the skill shells out to.
      [[ -d "${skill_dir}scripts" ]] && link "${skill_dir}scripts" "$dst_dir/scripts"
      # Root-level helper shell scripts (e.g. vsweep/stop-guard.sh, referenced by
      # SKILL.md as ~/.claude/skills/<skill>/<file>.sh) are symlinked per-file.
      for sh_file in "${skill_dir}"*.sh; do
        [[ -f "$sh_file" ]] && link "$sh_file" "$dst_dir/$(basename "$sh_file")"
      done
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
      [[ "$skill_name" == _* || "$skill_name" == *.bak.* ]] && continue
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
}
for t in "${TARGETS[@]}"; do target_info "$t"; install_skills "$SK"; done
# ── Webapp (always installed — vspecs and vreview --fix start it from here) ──
[[ -d "$REPO_DIR/web" ]] && link "$REPO_DIR/web" "$HOME/.claude/vskills-web"

# ── Post-install health-check summary ───────────────────────────────────────
# Quick sanity table over what actually landed in ~/.claude/skills — no lint,
# just surfaces anything obviously oversized or missing at a glance.
print_health_check() {
  local SKILLS_DST="$1"
  [[ -d "$SKILLS_DST" ]] || return 0
  log "post-install health check:"
  printf '  %-30s %10s %10s %12s\n' "skill" "desc-chars" "body-lines" "references"
  for skill_dir in "$SKILLS_DST"/*/; do
    skill_name="$(basename "${skill_dir%/}")"
    [[ "$skill_name" == _* ]] && continue
    md="${skill_dir}SKILL.md"
    [[ -f "$md" ]] || continue
    total_lines=$(wc -l < "$md" | tr -d ' ')
    close_line=$(awk '/^---$/{n++; if (n==2) { print NR; exit }}' "$md")
    body_lines=$(( ${close_line:-0} > 0 ? total_lines - close_line : total_lines ))
    desc=$(awk '/^---$/{n++; next} n==1' "$md" | grep '^description:' | head -1 | sed -E 's/^description:[[:space:]]*//; s/^"(.*)"$/\1/')
    refs="no"; [[ -d "${skill_dir}references" ]] && refs="yes"
    printf '  %-30s %10s %10s %12s\n' "$skill_name" "${#desc}" "$body_lines" "$refs"
  done
}

# ── Scripts (opt-in — personal lint rules, may not fit your codebase) ──────
if $WITH_SCRIPTS; then
  SCRIPTS_SRC="$REPO_DIR/scripts"
  SCRIPTS_DST="$HOME/.claude/scripts"

  if [[ -d "$SCRIPTS_SRC" ]]; then
    for script_dir in "$SCRIPTS_SRC"/*/; do
      name="$(basename "$script_dir")"
      link "${script_dir%/}" "$SCRIPTS_DST/$name"
    done
    # job-queue ships commands meant to be on PATH (the queue, the step runner, the script linter).
    if [[ -d "$SCRIPTS_SRC/job-queue" ]]; then
      for bin in jobq stepper lint-script; do
        link "$SCRIPTS_DST/job-queue/$bin" "$HOME/.local/bin/$bin"
      done
      log "job-queue: make sure ~/.local/bin is on PATH, then add the jobq-guard hook to ~/.claude/settings.json (see scripts/job-queue/README.md)"
    fi
  fi
else
  log "skipped scripts/ (lint rules) — pass --with-scripts to install"
fi

# ── CLAUDE.md starter (opt-in, never overwrites an existing one) ───────────
# Copied, not symlinked: this is a personal file you're meant to edit right
# away, not something that should silently change when the repo updates.
if $WITH_CLAUDE_MD; then
  CLAUDE_MD_SRC="$REPO_DIR/claude-md/CLAUDE.md"
  for t in "${TARGETS[@]}"; do
    target_info "$t"
    [[ -n "$MD" ]] || { log "no instruction file for target $t — skipping its starter rules"; continue; }
    if [[ -e "$MD" ]]; then
      log "WARNING: $MD already exists — not touching it."
    elif [[ -f "$CLAUDE_MD_SRC" ]]; then
      run "mkdir -p '$(dirname "$MD")'"
      run "cp '$CLAUDE_MD_SRC' '$MD'"
      log "copied starter rules → $MD (edit freely, not synced with this repo)"
    fi
  done
  $WITH_SCRIPTS || log "NOTE: the starter rules tell the agent to use jobq; also pass --with-scripts (and, on Claude Code, add the jobq-guard hook), or delete those rules"
else
  log "skipped CLAUDE.md starter — pass --with-claude-md to install (only applies if you don't already have one)"
fi

if ! $DRY_RUN; then
  for t in "${TARGETS[@]}"; do target_info "$t"; print_health_check "$SK"; done
fi

log "Done. (lang: $LANG_CHOICE)"
