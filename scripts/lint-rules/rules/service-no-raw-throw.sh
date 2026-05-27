#!/bin/bash
RULE_ID="service-no-raw-throw"
for file in "$@"; do
  [[ "$file" =~ -(service|use-case)\.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Service layer must throw AppError subclasses only, not raw Error or HTTPException
  grep -nE "throw new (Error|HTTPException)\s*\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
