#!/bin/bash
# fetch() response không check res.ok → HTML error page được treat như valid response
# FIX: if (!res.ok) throw new Error(`fetch failed: ${res.status}`)
# EXAMPLES:
#   ❌ const res = await fetch(url); const blob = await res.blob();
#   ✅ const res = await fetch(url); if (!res.ok) throw new Error(...); const blob = await res.blob();
RULE_ID="frontend-fetch-no-ok-check"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Find lines with raw fetch() calls
  grep -nE "(await fetch\s*\(|=\s*fetch\s*\()" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check same line + next 5 lines for ok/status check
    context=$(sed -n "${line_num},$((line_num + 5))p" "$file" 2>/dev/null)
    if ! echo "$context" | grep -qE "\.ok\b|\.status\b|res\.ok|response\.ok|if.*ok"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
