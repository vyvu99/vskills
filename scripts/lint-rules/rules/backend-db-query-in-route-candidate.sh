#!/bin/bash
# CANDIDATE: DB query trực tiếp trong route/handler file — business logic phải ở service
RULE_ID="backend-db-query-in-route-candidate"
for file in "$@"; do
  [[ "$file" =~ -(route|handler|controller|router)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "await (db|drizzle)\.|\.from\(tables\.|\.select\(|\.insert\(|\.update\(|\.delete\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
