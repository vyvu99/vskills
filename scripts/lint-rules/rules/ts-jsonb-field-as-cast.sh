#!/bin/bash
# `as` cast trên JSONB field đã có .$type<T>() trong Drizzle schema → mask union branches
# FIX: Xóa cast, dùng trực tiếp — Drizzle infer type đúng từ .$type<T>()
# EXAMPLES:
#   ❌ const family = profile.familyData as StudentFamilyData | null;
#   ✅ const family = profile.familyData;  // Drizzle infer: FamilyData = Student | Professional
RULE_ID="ts-jsonb-field-as-cast"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Known JSONB field names in eTARO schema
  grep -nE "\.(academicData|healthData|familyData|aspirationData|answers|scores|recommendations|settings|content|metadata|resultData|quizData)\s+as\s+[A-Z]" "$file" 2>/dev/null \
    | grep -vE "^\s*//" \
    | grep -vE "(schema|schemas?|Schema)\.(ts|tsx)$" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
