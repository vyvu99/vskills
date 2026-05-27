#!/bin/bash
RULE_ID="server-no-console-log"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx|js)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Only server-side files
  [[ "$file" =~ (server|api|services|handlers|middleware|workers|jobs|scripts)/ ]] || \
  [[ "$file" =~ -(service|repository|repo|handler|controller|middleware|worker|job)\.(ts|js)$ ]] || continue
  grep -nE "console\.(log|warn|error|info|debug)\s*\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
