#!/usr/bin/env bash

## RULE: fe-mutation-fn-side-effect
## PROBLEM: setState call inside mutationFn body — side effects belong in onMutate/onSuccess/onSettled
## FIX: move setState to onMutate (set) / onSettled (clear)
## HARVESTED FROM: .code-review/ — C7: setCopyingId inside mutationFn kẹt khi retry/unmount

## SCOPE: *.ts, *.tsx (hooks, components with useMutation)

## EXAMPLES:
## ❌ mutationFn: async (x) => { setLoading(true); await api.call(x) }
## ✅ onMutate: (x) => { setLoading(true) }, onSettled: () => { setLoading(false) }

RULE_ID="fe-mutation-fn-side-effect"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE 'mutationFn\s*:\s*async' "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        lineno="${hit%%:*}"
        # Check next 8 lines for setState pattern
        if sed -n "$((lineno+1)),$((lineno+8))p" "$file" 2>/dev/null \
           | grep -qE '\bset[A-Z][a-zA-Z]+\('; then
          printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$lineno" "${hit#*:}"
        fi
      done
done
