#!/bin/bash
# CANDIDATE: Arrow function có explicit `: Promise<T>` return type annotation
# khi TS thường infer được từ callee — xóa annotation, để TS infer
# Chỉ flag arrow functions (`=> `) không flag regular function declarations
RULE_ID="ts-arrow-explicit-promise-return-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "\): Promise<[^>]*> =>" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
