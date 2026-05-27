#!/bin/bash
RULE_ID="jsx-raw-img-anchor"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # <img> → use next/image <Image>
  # <a href> internal link → use next/link <Link>
  grep -nE "<img(\s|>|/)|<a\s+href=" "$file" 2>/dev/null \
    | grep -vE "^\s*//|^\s*\*|{/\*" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
