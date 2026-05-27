#!/bin/bash
RULE_ID="frontend-invalidate-queries-no-key"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # invalidateQueries() with no key or empty object — must scope to specific query key
  grep -nE "invalidateQueries\s*\(\s*\)|invalidateQueries\s*\(\s*\{\s*\}\s*\)" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
