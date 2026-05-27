#!/usr/bin/env bash

## RULE: fe-duplicate-query-key-factory
## PROBLEM: Local *_KEYS constant defined outside lib/query-client.ts — cache invalidation misses across components
## FIX: remove local key factory, import queryKeys from lib/query-client.ts
## HARVESTED FROM: .code-review/ — C8: NOTE_TEMPLATE_KEYS vs queryKeys.noteTemplates stale cache

## SCOPE: *.ts, *.tsx (feature hooks — not query-client.ts itself)

## EXAMPLES:
## ❌ const NOTE_KEYS = { all: ['notes'] as const, ... }  (in use-notes.ts)
## ✅ import { queryKeys } from '@/lib/query-client'

RULE_ID="fe-duplicate-query-key-factory"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ query-client ]] && continue
  grep -nE 'const [A-Z_]+KEYS\s*=\s*\{' "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
