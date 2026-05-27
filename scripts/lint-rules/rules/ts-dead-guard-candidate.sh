#!/bin/bash
# CANDIDATE: if (!x) return/throw — verify x có được dùng sau guard, nếu không → xóa guard
RULE_ID="ts-dead-guard-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "if\s*\(\s*![a-zA-Z_][a-zA-Z0-9_.]*\s*\)\s*(return|throw)" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
