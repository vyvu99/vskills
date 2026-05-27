#!/bin/bash
RULE_ID="ts-no-index-ts"
for file in "$@"; do
  # Flag any file named index.ts or index.tsx
  basename=$(basename "$file")
  if [[ "$basename" == "index.ts" || "$basename" == "index.tsx" ]]; then
    printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "1" "index.ts creation is forbidden"
  fi
done
