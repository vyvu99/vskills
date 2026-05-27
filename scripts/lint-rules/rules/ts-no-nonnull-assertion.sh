#!/bin/bash
RULE_ID="ts-no-nonnull-assertion"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Catches: foo!, arr[0]!, fn()!, ?.field! — excludes !=, !==, "string!", comment lines
  grep -nE "[a-zA-Z0-9_\])]!(\.|,|\)|\]|\s|;|$)|\?\.[a-zA-Z_]+!" "$file" 2>/dev/null \
    | grep -vE "^\s*//|!=|!==|[\"'][^\"']*![^\"']*[\"']" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
