#!/bin/bash
# CANDIDATE: RHF component dùng field.value as T[] nhưng thiếu generic constraint trên TName
# CONFIDENCE: Medium — false positive khi cast đã an toàn do caller guarantee
# FALSE POSITIVES: ~30% — component có constraint nhưng ở dạng khác
# FIX: Thêm generic constraint: TName extends FieldPath<T> & string
#   sao cho TName trỏ đúng kiểu T[field] = expected array type
# EXAMPLES:
#   ❌ function Field<T, TName>(...) { const val = field.value as Foo[]; }
#   ✅ function Field<T extends FieldValues, TName extends FieldPath<T>>(...)
#      — với constraint đảm bảo field.value có type đúng, không cần cast
RULE_ID="ts-rhf-generic-constraint-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Detect: field.value cast (với hoặc không có ?? [])
  grep -nE "field\.value(\s*\?\?\s*\[\])?\s+as\s+[A-Z][a-zA-Z]*(\[\])?" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:.*[/][/]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
