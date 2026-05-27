#!/bin/bash
# CONFIRMED: InferSelectModel<typeof X> xuất hiện nhiều hơn 1 lần cho cùng table trong schema file
# CONFIDENCE: High — gần như không có false positive
# FIX: Chỉ InferSelectModel 1 lần, export ra — tất cả nơi khác import type đó
# EXAMPLES:
#   ❌ export type User = InferSelectModel<typeof users>;  (line 10)
#      type UserModel = InferSelectModel<typeof users>;   (line 45) — duplicate
#   ✅ export type User = InferSelectModel<typeof users>;  (1 lần duy nhất)
RULE_ID="ts-infer-select-model-duplicate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Tìm tất cả table names được InferSelectModel, detect duplicate
  grep -oE "InferSelectModel<typeof [a-zA-Z_0-9]+>" "$file" 2>/dev/null \
    | sort | uniq -d \
    | while IFS= read -r pattern; do
        grep -nF "$pattern" "$file" 2>/dev/null \
          | while IFS= read -r hit; do
              printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
            done
      done
done
