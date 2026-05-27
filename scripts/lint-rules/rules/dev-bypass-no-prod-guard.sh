#!/bin/bash
RULE_ID="dev-bypass-no-prod-guard"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx|js)$ ]] || continue
  [[ -f "$file" ]] || continue
  # SKIP_*/USE_LOCAL_* flags must be guarded by NODE_ENV !== 'production'
  grep -nE "(SKIP_[A-Z_]+|USE_LOCAL_[A-Z_]+|[A-Z_]+_LOCAL_[A-Z_]+)\s*[=&|)]" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check surrounding 4 lines for NODE_ENV guard
    start=$((line_num - 2)); [[ $start -lt 1 ]] && start=1
    context=$(sed -n "${start},$((line_num + 2))p" "$file" 2>/dev/null)
    if ! echo "$context" | grep -qE "NODE_ENV|process\.env\.NODE_ENV"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
