#!/bin/bash
RULE_ID="ts-inline-type-in-service-route-repo"
for file in "$@"; do
  [[ "$file" =~ -(service|route|repository|repo|handler|controller)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # interface/type defined inline — should be in shared schemas
  grep -nE "^(export )?(interface [A-Z]|type [A-Z][a-zA-Z]+ =)" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
