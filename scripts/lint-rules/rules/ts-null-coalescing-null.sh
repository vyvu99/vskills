#!/bin/bash
RULE_ID="ts-null-coalescing-null"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # ?? null — prefer T | undefined over T | null unless DB/API requires null
  grep -nE "\?\? null([^a-zA-Z_]|$)" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
