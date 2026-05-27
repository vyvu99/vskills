#!/bin/bash
RULE_ID="ts-import-next-navigation-use-router"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # useRouter from next/navigation is forbidden — use nextjs-toploader/app
  grep -nE "useRouter.*from ['\"]next/navigation['\"]|from ['\"]next/navigation['\"].*useRouter" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
