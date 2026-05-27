#!/usr/bin/env bash

## RULE: fe-dialog-finally-close
## PROBLEM: setOpen(false) inside finally block — dialog closes even on error, user loses entered input
## FIX: move setOpen(false) to onSuccess callback only
## HARVESTED FROM: .code-review/ — W9: setOpen(false) trong finally đóng dialog khi lỗi

## SCOPE: *.ts, *.tsx (dialogs, modals with mutation handlers)

## EXAMPLES:
## ❌ } finally { setOpen(false) }
## ✅ onSuccess: () => { setOpen(false) }

RULE_ID="fe-dialog-finally-close"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE '^\s*\} finally \{' "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        lineno="${hit%%:*}"
        if sed -n "${lineno},$((lineno+5))p" "$file" 2>/dev/null \
           | grep -qE 'set(Open|IsOpen|Visible|Show)\(false\)'; then
          printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$lineno" "${hit#*:}"
        fi
      done
done
