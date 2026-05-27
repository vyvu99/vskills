#!/usr/bin/env bash

## RULE: fe-alert-dialog-action-no-disabled
## PROBLEM: <AlertDialogAction onClick=...> without disabled prop — double-submit risk during async mutations
## FIX: add disabled={isPending} to AlertDialogAction
## HARVESTED FROM: .code-review/ — W11: NoteTemplateEditWarningDialog confirm button not protected

## SCOPE: *.tsx

## EXAMPLES:
## ❌ <AlertDialogAction onClick={handleDelete}>
## ✅ <AlertDialogAction onClick={handleDelete} disabled={isPending}>

RULE_ID="fe-alert-dialog-action-no-disabled"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE '<AlertDialogAction\s+onClick=' "$file" 2>/dev/null \
    | grep -v 'disabled=' \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
