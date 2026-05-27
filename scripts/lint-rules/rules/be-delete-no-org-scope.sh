#!/usr/bin/env bash

## RULE: be-delete-no-org-scope
## PROBLEM: db.delete().where(eq(entity.id, id)) without organizationId guard — cross-tenant delete risk
## FIX: add AND eq(entity.organizationId, organizationId) to WHERE clause
## HARVESTED FROM: .code-review/ — C3: deleteNote no organizationId scope

## SCOPE: *repository*.ts

## EXAMPLES:
## ❌ db.delete(note).where(eq(note.id, id))
## ✅ db.delete(note).where(and(eq(note.id, id), eq(note.organizationId, organizationId)))

RULE_ID="be-delete-no-org-scope"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ repository ]] || continue
  grep -nE '\.delete\([a-zA-Z]+\)\.where\(eq\([a-zA-Z]+\.id' "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
