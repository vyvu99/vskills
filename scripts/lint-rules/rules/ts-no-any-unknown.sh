#!/bin/bash
# catch(err: unknown) là idiomatic TypeScript 4.0+ — không phải violation
# Chỉ flag: parameter/variable declarations, function return types, cast expressions
RULE_ID="ts-no-any-unknown"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE ": any([^A-Za-z_0-9]|$)|: unknown([^A-Za-z_0-9]|$)|@ts-ignore|@ts-expect-error| as any([^A-Za-z_0-9]|$)| as unknown([^A-Za-z_0-9]|$)|Array<any>|Promise<any>|<any," "$file" 2>/dev/null \
    | grep -vE "catch\s*\(\s*\w+\s*:\s*(any|unknown)\s*\)" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
