#!/usr/bin/env bash
# Runs install.sh against a throwaway HOME, from a repo path holding a quote and a space.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/it's a repo"
export HOME="$TMP/it's home"
mkdir -p "$REPO" "$HOME"
cp -R "$ROOT/install.sh" "$ROOT/skills" "$ROOT/claude-md" "$REPO/"
fail() { echo "FAIL test-install: $*" >&2; exit 1; }
install() { bash "$REPO/install.sh" "$@" >"$TMP/log" 2>&1 || { cat "$TMP/log" >&2; fail "install.sh $*"; }; }

install --dry-run --target=all --with-rules
[[ -z "$(ls -A "$HOME")" ]] || fail "dry run wrote into HOME"

install --target=all --with-rules
for dir in .claude .agents .gemini .copilot .config/opencode .kiro .commandcode; do
  [[ -L "$HOME/$dir/skills/vcook/SKILL.md" && -f "$HOME/$dir/skills/vcook/SKILL.md" ]] || fail "vcook not linked in $dir"
done

# A skill removed from the repo: its links go, the user's own file stays.
SKILLS="$HOME/.claude/skills"
echo mine >"$SKILLS/vci/notes.txt"
rm -rf "$REPO/skills/vci" "$REPO/skills/vrollback"
install
[[ -f "$SKILLS/vci/notes.txt" && ! -L "$SKILLS/vci/SKILL.md" ]] || fail "orphan with user file handled wrongly"
[[ ! -e "$SKILLS/vrollback" ]] || fail "empty orphan not removed"
echo "PASS test-install"
