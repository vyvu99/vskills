#!/bin/bash
RULE_ID="ts-zod-schema-in-route-file"
for file in "$@"; do
  [[ "$file" =~ -(route|handler|controller|router)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # z.object/string/number/enum etc. defined in route file (not trivial single-field params)
  grep -nE "z\.(object|string|number|boolean|array|enum|union|intersection)\s*\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
