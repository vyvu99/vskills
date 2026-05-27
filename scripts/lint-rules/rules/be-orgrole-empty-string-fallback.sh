#!/usr/bin/env bash

## RULE: be-orgrole-empty-string-fallback
## PROBLEM: c.get('orgRole') ?? '' — empty string silently bypasses MEMBER role check
## FIX: const orgRole = c.get('orgRole'); if (!orgRole) throw new ForbiddenError(...)
## HARVESTED FROM: .code-review/ — W1: orgRole fallback '' bypasses MEMBER scope

## SCOPE: *route*.ts, *routes*.ts

## EXAMPLES:
## ❌ const orgRole = c.get('orgRole') ?? ''
## ✅ const orgRole = c.get('orgRole'); if (!orgRole) throw new ForbiddenError('orgRole missing')

RULE_ID="be-orgrole-empty-string-fallback"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ route ]] || continue
  grep -nE "c\.get\('orgRole'\)\s*\?\?\s*''" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
