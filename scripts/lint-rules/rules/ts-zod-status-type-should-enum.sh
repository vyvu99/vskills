#!/bin/bash
# z.string() cho field tên status/type/role/kind/state/mode là quá lỏng lẻo
# Nên dùng z.enum([...]) để type-safe và catch unrecognized values tại parse time
# SCOPE: Schema files — nơi Zod schemas được định nghĩa
# EXAMPLES:
#   ❌ status: z.string()   → silent accept 'invalid-status'
#   ✅ status: z.enum(['active', 'archived', 'pending'])
RULE_ID="ts-zod-status-type-should-enum"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Scope: chỉ scan schema files (Zod schemas nên ở đây theo project convention)
  [[ "$file" =~ (-schema|schemas?|Schema)\.(ts)$ ]] || continue
  grep -nE '(status|type|role|kind|state|mode|category)\s*:\s*z\.string\(\s*\)' "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
