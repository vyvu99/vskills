#!/bin/bash
# Raw <FormField render={...}><FormControl><Input> boilerplate trong JSX
# Rule: dùng Form* wrapper từ UI component library — NEVER viết raw FormField + FormControl + Input
RULE_ID="jsx-raw-form-field-boilerplate"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "<FormField\s" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    context=$(sed -n "${line_num},$((line_num + 8))p" "$file" 2>/dev/null)
    if echo "$context" | grep -qE "<FormControl>"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
