#!/bin/bash
RULE_ID="jsx-key-is-index"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # key={index} or key={i} in map callbacks — not stable for reorderable lists
  grep -nE "key=\{(index|i|idx|_index)\}" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
