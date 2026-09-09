#!/usr/bin/env bash

## RULE: fe-json-stringify-memo-deps
## PROBLEM: JSON.stringify(array/object) inside useMemo/useCallback/useEffect dependency array
##   creates a new string on every render — defeats memoization purpose
## FIX: Use stable reference, individual fields, or join() of primitive IDs as deps
## HARVESTED FROM: .code-review/ — W8: JSON.stringify deps in notes-container.tsx

## SCOPE: *.tsx, *.ts (React components and hooks)

## EXAMPLES:
## ❌ useMemo(() => ..., [JSON.stringify(list)])
## ❌ useCallback(() => ..., [JSON.stringify(ids)])
## ✅ useMemo(() => ..., [list.length, list[0]?.id])
## ✅ useMemo(() => ..., [ids.join(',')])

RULE_ID="fe-json-stringify-memo-deps"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE '(useMemo|useCallback|useEffect)\s*\(' "$file" 2>/dev/null | while IFS= read -r hit; do
    lineno="${hit%%:*}"
    # Check if JSON.stringify appears near this hook (within 10 lines)
    start=$lineno
    end=$((lineno + 10))
    context=$(sed -n "${start},${end}p" "$file" 2>/dev/null)
    if echo "$context" | grep -qE 'JSON\.stringify'; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$lineno" "${hit#*:}"
    fi
  done
done
