#!/bin/bash
# CANDIDATE: try/catch trong route/handler file — không cần thiết vì global error handler xử lý
# Rule: Route/Controller chỉ gọi service và return response; global handler bắt mọi exception
RULE_ID="backend-trycatch-in-route-candidate"
for file in "$@"; do
  [[ "$file" =~ -(route|handler|controller|router)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "^\s+try\s*\{" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
