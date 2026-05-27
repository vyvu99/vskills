#!/bin/bash
# CANDIDATE: <Image> hoặc <img> không có alt prop — accessibility violation
# Rule: Alt text bắt buộc cho mọi image element
RULE_ID="jsx-missing-alt-text-candidate"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "<(Image|img)(\s[^>]*)?(/>|>)" "$file" 2>/dev/null \
    | grep -vE "alt=" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
