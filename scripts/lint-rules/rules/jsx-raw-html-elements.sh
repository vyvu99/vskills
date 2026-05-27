#!/bin/bash
RULE_ID="jsx-raw-html-elements"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # Raw interactive HTML elements — use component library
  # Lowercase element name = HTML element (not React component)
  grep -nE "<(button|input|select|textarea|dialog)(\s|>|/)" "$file" 2>/dev/null \
    | grep -vE "^\s*//|^\s*\*|{/\*" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
