#!/bin/bash
# CONFIRMED: hardcoded role/status/type string trong comparison
# CONFIDENCE: High — gần như không có false positive
# FIX: Dùng Zod schema enum value — KHÔNG phải string constant hay satisfies
#   ❌ clientStatus === 'archived'
#   ❌ clientStatus === ('archived' satisfies ClientStatus)  ← satisfies vẫn là hardcode
#   ✅ clientStatus === clientStatusSchema.enum.archived
#   ✅ clientStatus === MemberRoles.OWNER  ← nếu dùng TS enum thay Zod
# NOTE: grep cả pattern satisfies để catch false-safe pattern
RULE_ID="ts-hardcode-role-status-string"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "===\s*\(?\s*'(admin|user|member|owner|manager|guest|viewer|editor|moderator|active|inactive|pending|draft|published|archived|deleted|approved|rejected|completed|failed|cancelled|processing|paid|unpaid|free|pro|enterprise)'" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
