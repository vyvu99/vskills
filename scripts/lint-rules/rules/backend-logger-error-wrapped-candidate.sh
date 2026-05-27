#!/bin/bash
# CANDIDATE: logger.error/warn nhận Error object bọc trong object literal — mất stack trace
# Rule: logger.error(err, 'msg') hoặc logger.error({ ctx }, 'msg') — KHÔNG wrap err vào object
RULE_ID="backend-logger-error-wrapped-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "logger\.(error|warn)\s*\(\s*\{[^}]*(error|err)\s*:" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
