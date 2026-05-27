#!/bin/bash
# CANDIDATE: repository layer throw — repository phải trả null/undefined, không throw
# Rule: Service throw AppError; Repository trả null và để DB error bubble up tự nhiên
RULE_ID="backend-repository-throws-candidate"
for file in "$@"; do
  [[ "$file" =~ -(repository|repo)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "^\s+throw new" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
