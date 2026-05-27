#!/usr/bin/env bash

## RULE: be-ip-header-no-format-validate
## PROBLEM: x-forwarded-for header read without IP format validation — audit log IP can be spoofed
## FIX: validate with regex /^(\d{1,3}\.){3}\d{1,3}$|^[0-9a-fA-F:]+$/ before trusting value
## HARVESTED FROM: .code-review/ — ADV-A5: x-forwarded-for injection — audit log IP không đáng tin

## SCOPE: *route*.ts, *service*.ts

## EXAMPLES:
## ❌ const ip = req.header('x-forwarded-for')?.split(',')[0]?.trim().slice(0, 45)
## ✅ const raw = req.header('x-forwarded-for')?.split(',')[0]?.trim()
##    const ip = /^(\d{1,3}\.){3}\d{1,3}$|^[0-9a-fA-F:]+$/.test(raw ?? '') ? raw : undefined

RULE_ID="be-ip-header-no-format-validate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "x-forwarded-for" "$file" 2>/dev/null \
    | grep -v '\.test\(\|isValidIp\|regex' \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
