#!/bin/bash
RULE_ID="ts-use-effect-derived-state"
for file in "$@"; do
  [[ "$file" =~ \.(tsx|ts)$ ]] || continue
  [[ -f "$file" ]] || continue
  # useState initialized to undefined/null then set inside useEffect — derived state pattern
  # Heuristic: set* call inside useEffect body
  grep -nE "useEffect\s*\(\s*\(\s*\)" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check if there's a setState call within 5 lines after this useEffect
    context=$(tail -n +"$line_num" "$file" 2>/dev/null | head -n 8)
    if echo "$context" | grep -qE "set[A-Z][a-zA-Z]+\("; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
