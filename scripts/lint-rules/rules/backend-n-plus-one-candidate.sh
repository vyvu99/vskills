#!/bin/bash
# CANDIDATE: await DB call bên trong .map(async/.forEach(async — N+1 query pattern
RULE_ID="backend-n-plus-one-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Flag .map(async và .forEach(async — cần verify xem body có DB call không
  grep -nE "\.(map|forEach|filter|reduce)\s*\(\s*async" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check within next 10 lines for DB-related calls
    context=$(tail -n +"$line_num" "$file" 2>/dev/null | head -n 10)
    if echo "$context" | grep -qE "await (db|drizzle)\.|\.from\(|\.findBy|repository\.|service\."; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
