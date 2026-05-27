#!/bin/bash
RULE_ID="ts-no-unsafe-type-cast"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Catches: ) as Type, ] as Type, someVar as Type, as primitive — excludes import/export as aliases
  grep -nE "(\)|\]|[a-zA-Z0-9_]) as [A-Z][a-zA-Z]+[^A-Za-z(]|as (string|number|boolean|object)[^A-Za-z_]|as unknown as" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:.*(import |export |// )" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
