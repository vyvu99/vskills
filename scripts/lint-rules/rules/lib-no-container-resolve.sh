#!/bin/bash
RULE_ID="lib-no-container-resolve"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # container.resolve() outside DI-registered classes breaks testability
  [[ "$file" =~ /(lib|utils|helpers|tools|agent)/ ]] || continue
  grep -nE "container\.resolve\s*\(" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
