#!/bin/bash
# React key từ field không unique (icon, emoji, color, label) → duplicate key khi list có trùng
# FIX: key={item.id} hoặc key={i} cho static lists
# EXAMPLES:
#   ❌ <g key={item.icon}>     // '📝' có thể xuất hiện 2 lần
#   ❌ <div key={item.color}>  // '#3b82f6' dùng nhiều lần
#   ✅ <g key={i}>             // static list, không reorder → index là safe
RULE_ID="jsx-key-non-unique-field"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  # icon/emoji/color are display-only fields that commonly duplicate → key collision
  # name/label/id/slug are excluded — usually unique identifiers within a list
  grep -nE 'key=\{[a-zA-Z_$][a-zA-Z0-9_$.]*\.(icon|emoji|color)\}' "$file" 2>/dev/null \
    | grep -vE "^\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
