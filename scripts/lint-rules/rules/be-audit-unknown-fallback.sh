#!/usr/bin/env bash

## RULE: be-audit-unknown-fallback
## PROBLEM: Audit-sensitive fields (signerName, unlockerName, signedByName) fall back to 'Unknown'
##   hardcode — makes audit trail non-distinguishable across multiple sign events
## FIX: Throw ValidationError when identity cannot be resolved instead of silent 'Unknown' fallback
## HARVESTED FROM: .code-review/ — A1: signerName 'Unknown' in audit trail (note.routes.ts)

## SCOPE: *route*.ts, *routes*.ts, *service*.ts

## EXAMPLES:
## ❌ const signerName = body.name ?? currentUser.name ?? currentUser.email ?? 'Unknown'
## ❌ const unlockerName = currentUser.name ?? currentUser.email ?? 'Unknown'
## ✅ const signerName = body.name ?? currentUser.name ?? currentUser.email;
##    if (!signerName?.trim()) throw new ValidationError('...')

RULE_ID="be-audit-unknown-fallback"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ (route|service) ]] || continue
  grep -nE "\?\?\s*['\"]Unknown['\"]" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
