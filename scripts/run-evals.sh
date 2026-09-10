#!/bin/bash
# scripts/run-evals.sh -- trigger + behavior evals for the vcheck / vreview skills.
# Usage: bash scripts/run-evals.sh
#
# ISOLATION POSTURE (soft containment, NOT a sandbox -- see
# plans/260909-1608-vskills-review-triage-batch2/phase-03-eval-infrastructure.md):
#   every `claude -p` call below runs with a throwaway `mktemp -d` copy of the
#   fixture as its actual `cwd`, plus `--add-dir "$tmp"` as a secondary
#   allowance, `--disallowedTools WebFetch,WebSearch` to remove the web-exfil
#   surface, and `--permission-mode bypassPermissions` so it never blocks on
#   an interactive prompt. `--add-dir` is ADDITIVE, not confining -- it does
#   NOT hard-sandbox the session to $tmp (confirmed empirically; `--restricted`
#   is the only flag that hard-confines, and it strips Bash + refuses
#   bypassPermissions, both of which vcheck needs). This is acceptable ONLY
#   because every prompt this script runs is one of the small, fixed,
#   hand-authored strings in evals/**/*.json -- never external/untrusted
#   input. Do not extend this runner to run arbitrary/externally-sourced
#   prompts without redoing this risk assessment.
#
# OUTPUT FORMAT (confirmed empirically, do not change without re-checking):
#   `--output-format json` carries NO tool-use detail -- just the final
#   result text + usage/cost. `--output-format stream-json --verbose` is
#   required: it prints one JSON object per line, and a Skill invocation
#   shows up as an `assistant` message whose `message.content[]` array
#   contains `{"type":"tool_use","name":"Skill","input":{"skill":"<name>"}}`.
#   That is the exact shape `skill_invoked()` below greps for via jq.
#
# CONTAINMENT INCIDENT (found during this phase's own first live run, not
# hypothetical): with cwd=$tmp + --add-dir "$tmp" + bypassPermissions, a
# handful of trigger-eval prompts run in an EMPTY temp dir caused the
# subprocess to read/edit real tracked files in THIS repo
# (skills/vfix/SKILL.md, skills/vreview/SKILL.md, skills/vcheck/SKILL.vi.md,
# etc.) via absolute paths, and to create new files under scripts/. This is
# exactly the "--add-dir does not hard-confine" risk the plan's Risk
# Assessment named -- it was not hypothetical, it happened. `--strict-mcp-config`
# (no `--mcp-config` given) is added below to drop the `mcp__memory__*` tools,
# the most likely vector (this user's global CLAUDE.md instructs every
# session to search project memory first) -- but bypassPermissions still lets
# an absolute-path Read/Edit/Write reach anywhere, so this is mitigation, not
# a fix. `guarded_run_claude()` below is the actual backstop: it snapshots
# `git status --porcelain` in $REPO_ROOT before and after every single
# invocation and hard-reverts + flags the eval FAIL if anything changed.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVALS_DIR="$REPO_ROOT/evals"

# CLEAN-TREE PRECONDITION (added after the incident above: guarded_run_claude's
# `git checkout -- .` + delete-new-untracked revert destroyed OTHER, unrelated
# uncommitted work that happened to be sitting in the tree when a breach fired
# during this same session -- git cannot tell "this subprocess's rogue edit"
# apart from "legitimate WIP from something else." Refuse to run at all unless
# the tree is clean, so a mid-run revert can only ever touch what THIS run itself
# produced. Commit or stash your work before running this script.
if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "ERROR: $REPO_ROOT has uncommitted changes. Refusing to run -- guarded_run_claude()" >&2
  echo "reverts the ENTIRE working tree on a detected breach, which would destroy any" >&2
  echo "unrelated WIP along with the breach. Commit or 'git stash push --include-untracked'" >&2
  echo "first, then re-run." >&2
  exit 1
fi

# timeout / gtimeout detection -- same fallback pattern as scripts/lint-rules/run.sh.
# One hung `claude -p` call must not hang the whole suite.
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout 120s"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout 120s"
else
  echo "WARNING: neither 'timeout' nor 'gtimeout' found on PATH -- running WITHOUT a hang guard" >&2
  TIMEOUT_CMD=""
fi

PASS=0
FAIL=0
RESULTS=()   # "skill|eval_type|name|VERDICT|detail" rows for the final table

# run_claude <tmp_dir> <prompt>
# Runs claude -p with the fixed isolation posture above, writing the
# stream-json transcript to "$tmp_dir/claude_stream.jsonl".
run_claude() {
  local tmp="$1" prompt="$2"
  (cd "$tmp" && $TIMEOUT_CMD claude -p "$prompt" \
    --output-format stream-json --verbose \
    --add-dir "$tmp" \
    --permission-mode bypassPermissions \
    --disallowedTools WebFetch,WebSearch \
    --strict-mcp-config) >"$tmp/claude_stream.jsonl" 2>"$tmp/claude_stream.err"
}

# guarded_run_claude <tmp_dir> <prompt> <label>
# Same as run_claude, but snapshots `git status --porcelain` in $REPO_ROOT
# before and after -- if the real repo changed, hard-revert it immediately
# and set BREACH=1 (checked by callers to force a FAIL + note in the report).
BREACH=0
guarded_run_claude() {
  local tmp="$1" prompt="$2" label="$3"
  local before after
  before=$(git -C "$REPO_ROOT" status --porcelain)
  run_claude "$tmp" "$prompt"
  after=$(git -C "$REPO_ROOT" status --porcelain)
  BREACH=0
  if [ "$before" != "$after" ]; then
    BREACH=1
    echo "!!! CONTAINMENT BREACH during [$label]: claude -p modified $REPO_ROOT -- reverting !!!" >&2
    diff <(echo "$before") <(echo "$after") >&2
    # Safe now that the clean-tree precondition above guarantees $before was
    # empty at script start -- this can only revert what THIS run produced.
    # NOTE: awk '{print $2}' on porcelain output assumes no spaces in paths
    # and doesn't handle rename entries ("R  old -> new"); fine for this
    # script's hand-authored fixture paths, revisit if that ever changes.
    git -C "$REPO_ROOT" checkout -- . 2>/dev/null
    comm -13 <(echo "$before" | awk '{print $2}' | sort -u) <(echo "$after" | awk '{print $2}' | sort -u) \
      | while IFS= read -r p; do [ -n "$p" ] && rm -rf "${REPO_ROOT:?}/$p"; done
  fi
}

# skill_invoked <stream_file> <skill_name> -- exit 0 if that Skill tool_use appears anywhere in the transcript
skill_invoked() {
  jq -s -e --arg skill "$2" '
    any(.[]?; .type=="assistant" and ((.message.content // [])
      | any(.type=="tool_use" and .name=="Skill" and .input.skill==$skill)))
  ' "$1" >/dev/null 2>&1
}

# final_result_text <stream_file> -- the "result" field of the last result event
final_result_text() {
  jq -s -r '[.[]? | select(.type=="result")] | last | .result // ""' "$1" 2>/dev/null
}

run_trigger_evals() {
  local skill="$1"
  local file="$EVALS_DIR/trigger/$skill.json"
  local total; total=$(jq 'length' "$file")
  local i=0
  while [ "$i" -lt "$total" ]; do
    local query should_trigger tmp invoked verdict
    query=$(jq -r ".[$i].query" "$file")
    should_trigger=$(jq -r ".[$i].should_trigger" "$file")
    tmp=$(mktemp -d)
    guarded_run_claude "$tmp" "$query" "trigger/$skill: $query"
    invoked="false"
    skill_invoked "$tmp/claude_stream.jsonl" "$skill" && invoked="true"
    verdict="FAIL"
    [ "$invoked" = "$should_trigger" ] && [ "$BREACH" -eq 0 ] && verdict="PASS"
    if [ "$verdict" = "PASS" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
    if [ "$BREACH" -eq 1 ]; then
      RESULTS+=("$skill|trigger|${query:0:48}|FAIL|CONTAINMENT BREACH -- reverted, see stderr above")
      echo "[FAIL] trigger/$skill: \"$query\" -- CONTAINMENT BREACH, reverted (see stderr above)"
    else
      RESULTS+=("$skill|trigger|${query:0:48}|$verdict|invoked=$invoked expected=$should_trigger")
      echo "[$verdict] trigger/$skill: \"$query\" (invoked=$invoked, expected=$should_trigger)"
    fi
    rm -rf "$tmp"
    i=$((i + 1))
  done
}

run_vcheck_behavior() {
  local meta="$EVALS_DIR/behavior/vcheck/eval_metadata.json"
  local total; total=$(jq 'length' "$meta")
  local i=0
  while [ "$i" -lt "$total" ]; do
    local pm prompt sig tmp install_log output verdict
    pm=$(jq -r ".[$i].fixture" "$meta")
    prompt=$(jq -r ".[$i].prompt" "$meta")
    sig=$(jq -r ".[$i].assertions.error_signature" "$meta")
    tmp=$(mktemp -d)
    cp -r "$EVALS_DIR/behavior/vcheck/fixtures/$pm/." "$tmp/"

    install_log="$tmp/install.log"
    case "$pm" in
      pnpm) (cd "$tmp" && pnpm install --frozen-lockfile) >"$install_log" 2>&1 ;;
      npm)  (cd "$tmp" && npm ci) >"$install_log" 2>&1 ;;
      yarn) (cd "$tmp" && yarn install) >"$install_log" 2>&1 ;;
      bun)  (cd "$tmp" && bun install) >"$install_log" 2>&1 ;;
    esac
    if [ $? -ne 0 ]; then
      FAIL=$((FAIL + 1))
      RESULTS+=("vcheck|behavior|$pm|FAIL|install step failed, see $install_log")
      echo "[FAIL] behavior/vcheck: $pm (install step failed, see $install_log)"
      rm -rf "$tmp"
      i=$((i + 1))
      continue
    fi

    guarded_run_claude "$tmp" "$prompt" "behavior/vcheck: $pm"
    if [ "$BREACH" -eq 1 ]; then
      FAIL=$((FAIL + 1))
      RESULTS+=("vcheck|behavior|$pm|FAIL|CONTAINMENT BREACH -- reverted, see stderr above")
      echo "[FAIL] behavior/vcheck: $pm -- CONTAINMENT BREACH, reverted (see stderr above)"
      rm -rf "$tmp"
      i=$((i + 1))
      continue
    fi
    output=$(final_result_text "$tmp/claude_stream.jsonl")
    verdict="FAIL"
    echo "$output" | grep -q "$sig" && verdict="PASS"
    if [ "$verdict" = "PASS" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
    RESULTS+=("vcheck|behavior|$pm|$verdict|expected \"$sig\" in output")
    echo "[$verdict] behavior/vcheck: $pm (expected \"$sig\" in output)"
    rm -rf "$tmp"
    i=$((i + 1))
  done
}

run_vreview_behavior() {
  local meta="$EVALS_DIR/behavior/vreview/eval_metadata.json"
  local prompt tmp report total_gt hits i keyword verdict
  prompt=$(jq -r '.prompt' "$meta")
  tmp=$(mktemp -d)
  cp -r "$EVALS_DIR/behavior/vreview/fixtures/." "$tmp/"

  guarded_run_claude "$tmp" "$prompt" "behavior/vreview"
  if [ "$BREACH" -eq 1 ]; then
    FAIL=$((FAIL + 1))
    RESULTS+=("vreview|behavior|fixtures|FAIL|CONTAINMENT BREACH -- reverted, see stderr above")
    echo "[FAIL] behavior/vreview -- CONTAINMENT BREACH, reverted (see stderr above)"
    rm -rf "$tmp"
    return
  fi

  # Score against .code-review/REPORT.md when the full vreview skill wrote one;
  # fall back to the final result text otherwise -- a small fixture may get a
  # direct inline answer instead of the full report-writing workflow, and that
  # inline answer is a legitimate place to find the ground-truth findings too.
  report="$tmp/.code-review/REPORT.md"
  local scored_text
  if [ -f "$report" ]; then
    scored_text=$(cat "$report")
  else
    scored_text=$(final_result_text "$tmp/claude_stream.jsonl")
  fi
  total_gt=$(jq '.ground_truth | length' "$meta")
  hits=0
  i=0
  while [ "$i" -lt "$total_gt" ]; do
    keyword=$(jq -r ".ground_truth[$i].keyword" "$meta")
    echo "$scored_text" | grep -qi -- "$keyword" && hits=$((hits + 1))
    i=$((i + 1))
  done
  verdict="FAIL"
  [ "$hits" -gt 0 ] && verdict="PASS"
  if [ "$verdict" = "PASS" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
  RESULTS+=("vreview|behavior|fixtures|$verdict|matched $hits/$total_gt ground-truth findings")
  if [ -f "$report" ]; then
    echo "[$verdict] behavior/vreview: matched $hits/$total_gt ground-truth findings (report: $report)"
  else
    echo "[$verdict] behavior/vreview: matched $hits/$total_gt ground-truth findings (no REPORT.md written, scored final result text instead)"
  fi
  rm -rf "$tmp"
}

echo "=== Trigger evals: vcheck ==="
run_trigger_evals vcheck
echo "=== Trigger evals: vreview ==="
run_trigger_evals vreview
echo "=== Behavior evals: vcheck ==="
run_vcheck_behavior
echo "=== Behavior evals: vreview ==="
run_vreview_behavior

echo ""
echo "=== Summary ==="
printf '%-10s %-10s %-6s %s\n' "skill" "type" "result" "detail"
for r in "${RESULTS[@]}"; do
  IFS='|' read -r skill etype name verdict detail <<< "$r"
  printf '%-10s %-10s %-6s %s\n' "$skill" "$etype" "$verdict" "$name: $detail"
done
echo ""
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
