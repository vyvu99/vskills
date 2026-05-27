#!/bin/bash
RULE_ID="orm-join-without-comment"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # JOIN operations — must have comment explaining why sequential queries not used
  grep -nE "\.(innerJoin|leftJoin|rightJoin|fullJoin)\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check if the line itself or the line above contains a comment
    prev_line=$(sed -n "$((line_num - 1))p" "$file" 2>/dev/null)
    curr_line="${hit#*:}"
    if ! echo "$prev_line$curr_line" | grep -qE "//|/\*"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "$curr_line"
    fi
  done
done
