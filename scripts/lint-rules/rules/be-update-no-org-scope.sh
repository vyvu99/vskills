#!/usr/bin/env bash

## RULE: be-update-no-org-scope
## PROBLEM: db.update(entity).set(...).where(eq(entity.id, id)) without organizationId guard
##   allows cross-tenant update if caller passes wrong id
## FIX: add AND eq(entity.organizationId, organizationId) to WHERE clause (defense in depth)
## HARVESTED FROM: .code-review/ — C2: updateTemplate/deleteTemplate no org scope in repo

## SCOPE: *repository*.ts

## EXAMPLES:
## ❌ db.update(noteTemplate).set(data).where(eq(noteTemplate.id, id))
## ✅ db.update(noteTemplate).set(data).where(and(eq(noteTemplate.id, id), eq(noteTemplate.organizationId, organizationId)))

RULE_ID="be-update-no-org-scope"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ repository ]] || continue
  grep -nE '\.update\([a-zA-Z]+\)\.set\(' "$file" 2>/dev/null | while IFS= read -r hit; do
    lineno="${hit%%:*}"
    # Check WHERE clause within next 5 lines — flag if only eq(*.id, *) without organizationId
    end=$((lineno + 5))
    context=$(sed -n "${lineno},${end}p" "$file" 2>/dev/null)
    if echo "$context" | grep -qE '\.where\(' && ! echo "$context" | grep -qiE 'organizationId|orgId'; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$lineno" "${hit#*:}"
    fi
  done
done
