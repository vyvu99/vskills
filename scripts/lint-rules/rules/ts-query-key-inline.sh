#!/bin/bash
# useQuery/useSuspenseQuery/useInfiniteQuery với queryKey là string literal inline
# Rule: query key factory đặt ở file chung — NEVER inline string trong hook
RULE_ID="ts-query-key-inline"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "(useQuery|useSuspenseQuery|useInfiniteQuery)\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    context=$(sed -n "${line_num},$((line_num + 5))p" "$file" 2>/dev/null)
    # Flag nếu queryKey chứa string literal (không phải variable reference)
    if echo "$context" | grep -qE "queryKey\s*:\s*\[['\"]"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
