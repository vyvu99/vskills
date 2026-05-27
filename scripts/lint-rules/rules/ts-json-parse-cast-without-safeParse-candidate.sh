#!/bin/bash
# CANDIDATE: JSON.parse() trong file không có safeParse — kết quả likely bị cast as T mà không validate shape
# CONFIDENCE: Medium — false positive khi file dùng manual type-guard thay Zod
# FALSE POSITIVES: ~20% — file có manual validation (typeof checks đủ fields)
# FIX: Dùng schema.safeParse(JSON.parse(raw)) thay vì JSON.parse + as T
# EXAMPLES:
#   ❌ const data = JSON.parse(raw) as MyType;
#   ❌ const data: unknown = JSON.parse(raw); return data as MyType;  ← không có safeParse
#   ✅ const result = mySchema.safeParse(JSON.parse(raw));
#      if (!result.success) return null;
#      return result.data;
RULE_ID="ts-json-parse-cast-without-safeParse-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Chỉ flag nếu file có JSON.parse nhưng không có safeParse hoặc Zod validation
  grep -q "JSON\.parse\b" "$file" 2>/dev/null || continue
  if grep -qE "\.safeParse\s*\(|safeParse\s*\(" "$file" 2>/dev/null; then
    continue
  fi
  grep -nE "\bJSON\.parse\s*\(" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:.*[/][/]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
