#!/bin/bash
RULE_ID="ts-zod-parse-not-safe-in-service-repo"
for file in "$@"; do
  [[ "$file" =~ -(service|repository|repo)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # .parse( without safeParse — flag calls that may crash on legacy DB data
  grep -nE "\bparse\s*\(" "$file" 2>/dev/null \
    | grep -vE "safeParse|JSON\.parse" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
