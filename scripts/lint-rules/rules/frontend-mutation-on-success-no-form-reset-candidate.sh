#!/bin/bash
# CANDIDATE: useMutation onSuccess không có form.reset() — form có thể reopen với stale data
RULE_ID="frontend-mutation-on-success-no-form-reset-candidate"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "\bonSuccess\s*:" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check if this onSuccess is inside useMutation (within 20 lines above)
    start=$((line_num - 20)); [[ $start -lt 1 ]] && start=1
    above=$(sed -n "${start},$((line_num - 1))p" "$file" 2>/dev/null)
    echo "$above" | grep -qE "useMutation" || continue
    # Check ±8 lines for form.reset call
    context=$(sed -n "${line_num},$((line_num + 8))p" "$file" 2>/dev/null)
    if ! echo "$context" | grep -qE "\.reset\s*\("; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
