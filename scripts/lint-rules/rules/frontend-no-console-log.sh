#!/bin/bash
RULE_ID="frontend-no-console-log"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # Skip server-side files
  [[ "$file" =~ (server|api/)/ ]] && continue
  # console.log debug leftover in component files
  grep -nE "console\.log\s*\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
