#!/bin/bash
# Entry point cho lint-rules scanner
# Usage: bash run.sh [file1 file2 ...]
# Output: SCRIPT_SCAN.json (có git blame) + stdout
# Nếu không có args → scan files từ git diff HEAD
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
MERGER="$SCRIPT_DIR/merge-reports.js"

if [[ ! -f "$MERGER" ]]; then
  echo "ERROR: merge-reports.js not found at $MERGER" >&2
  exit 1
fi

# Collect file list từ args hoặc git diff
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=()
  while IFS= read -r line; do
    files+=("$line")
  done < <(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' | grep -v node_modules)
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo '{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","summary":{"total_violations":0,"rules_violated":0,"rules_passed":0},"violations":[],"passed_rules":[]}'
  exit 0
fi

# Chạy tất cả rule scripts, pipe kết quả TSV vào merger
OUTPUT_FILE="${SCRIPT_SCAN_OUTPUT:-SCRIPT_SCAN.json}"

# timeout command: GNU coreutils (Linux hoặc macOS via brew install coreutils)
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout 30s"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout 30s"
else
  TIMEOUT_CMD=""
fi

# Helper: lọc files theo scope regex từ rule-registry.json
# Nếu rule không có scope → truyền toàn bộ files
filter_files_by_scope() {
  local rule_id="$1"
  shift
  local all_files=("$@")
  local scope
  scope=$(node -e "
    const r = require('$SCRIPT_DIR/config/rule-registry.json');
    const rule = r['$rule_id'];
    process.stdout.write(rule && rule.scope ? rule.scope : '');
  " 2>/dev/null)
  if [[ -z "$scope" ]]; then
    printf '%s\n' "${all_files[@]}"
    return
  fi
  for f in "${all_files[@]}"; do
    if echo "$f" | grep -qE "$scope"; then
      echo "$f"
    fi
  done
}

{
  for script in "$RULES_DIR"/*.sh; do
    [[ -x "$script" ]] || continue
    rule_id="$(basename "$script" .sh)"
    # Lấy subset files phù hợp scope của rule (hoặc toàn bộ nếu không có scope)
    scoped_files=()
    while IFS= read -r line; do
      scoped_files+=("$line")
    done < <(filter_files_by_scope "$rule_id" "${files[@]}")
    [[ ${#scoped_files[@]} -eq 0 ]] && continue
    if [[ -n "$TIMEOUT_CMD" ]]; then
      $TIMEOUT_CMD bash "$script" "${scoped_files[@]}" || echo "WARN: $script timed out or failed" >&2
    else
      bash "$script" "${scoped_files[@]}"
    fi
  done
} | node "$MERGER" | tee "$OUTPUT_FILE"
