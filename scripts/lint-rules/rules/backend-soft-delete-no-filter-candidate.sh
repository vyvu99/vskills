#!/bin/bash
# CANDIDATE: SELECT query trên entity không có deletedAt filter — có thể bị missing soft-delete check
RULE_ID="backend-soft-delete-no-filter-candidate"
for file in "$@"; do
  [[ "$file" =~ -(repository|repo)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "db\.select\(\)|\.from\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check next 8 lines for deletedAt filter
    context=$(sed -n "${line_num},$((line_num + 8))p" "$file" 2>/dev/null)
    if ! echo "$context" | grep -qE "deletedAt|deleted_at|isNull|is null"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
