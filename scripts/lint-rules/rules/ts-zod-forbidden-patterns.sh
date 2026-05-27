#!/bin/bash
RULE_ID="ts-zod-forbidden-patterns"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # z.any(), z.unknown(), deprecated z.string().datetime(), z.record(z.string(), z.unknown())
  grep -nE "z\.any\(\)|z\.unknown\(\)|\.string\(\)\.datetime\(\)|z\.record\(z\.string\(\), z\.unknown\(\)\)" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
