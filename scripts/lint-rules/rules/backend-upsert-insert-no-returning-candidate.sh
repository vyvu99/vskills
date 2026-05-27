#!/bin/bash
# CANDIDATE: INSERT/UPDATE không có RETURNING clause — phải re-query để lấy DB-authoritative value
# FIX: Tăng lookahead từ 5 lên 15 lines để bắt Drizzle chains dài
# Drizzle-specific: chỉ flag khi line hoặc 2 lines trước có db./tx. (xác nhận là DB call)
RULE_ID="backend-upsert-insert-no-returning-candidate"
for file in "$@"; do
  [[ "$file" =~ -(repository|repo|service)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "\.(insert|update|upsert)\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Verify it's a Drizzle DB call: db./tx./database. must appear within 3 lines before
    context_before=$(sed -n "$((line_num > 3 ? line_num - 3 : 1)),$((line_num))p" "$file" 2>/dev/null)
    if ! echo "$context_before" | grep -qE "(db|tx|database|trx)\.[a-zA-Z]"; then
      continue
    fi
    # Check next 15 lines for .returning() — Drizzle chains thường dài 5-12 lines
    context_after=$(sed -n "${line_num},$((line_num + 15))p" "$file" 2>/dev/null)
    if ! echo "$context_after" | grep -qE "\.returning\s*\(|returning:"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
