#!/bin/bash
RULE_ID="test-case-not-english"
for file in "$@"; do
  [[ "$file" =~ \.(test|spec)\.(ts|tsx|js)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Test labels must be in English — flag Vietnamese characters in it/test/describe labels
  # Vietnamese character ranges in UTF-8
  grep -nE "(it|test|describe)\s*\(['\"]" "$file" 2>/dev/null | while IFS= read -r hit; do
    line="${hit#*:}"
    # Check for Vietnamese diacritics (extended Latin range)
    if echo "$line" | grep -qE "[àáâãèéêìíòóôõùúýăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝĂĐĨŨƠƯ]"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "$line"
    fi
  done
done
