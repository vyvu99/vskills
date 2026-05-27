#!/bin/bash
RULE_ID="frontend-direct-fetch-bypass"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # Raw fetch()/axios. in component files bypasses the API client layer
  grep -nE "\bfetch\s*\(|axios\.(get|post|put|patch|delete)\s*\(" "$file" 2>/dev/null \
    | grep -vE "^\s*//|^\s*\*" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
