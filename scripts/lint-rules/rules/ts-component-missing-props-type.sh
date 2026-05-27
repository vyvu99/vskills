#!/bin/bash
RULE_ID="ts-component-missing-props-type"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # function Component({ prop1, prop2 }) without type annotation
  # Catches: function Foo({ ... }) and const Foo = ({ ... }) without : Props
  grep -nE "^(export (default )?)?function [A-Z][a-zA-Z]*\s*\(\s*\{[^}]*\}\s*\)" "$file" 2>/dev/null \
    | grep -vE "\}:\s*[A-Za-z]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
