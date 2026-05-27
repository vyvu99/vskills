#!/bin/bash
# void operator trên async function call → floating promise, error bị nuốt hoàn toàn
# FIX: asyncFn().catch(() => setStatus('failed')) hoặc .catch(logAsyncFailure)
# EXAMPLES:
#   ❌ void downloadPdfFile(url);
#   ❌ void sendAnalytics(data);
#   ✅ downloadPdfFile(url).catch(() => setStatus('failed'));
RULE_ID="frontend-void-async-call"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE '\bvoid\s+[a-zA-Z_][a-zA-Z0-9_.]*\s*\(' "$file" 2>/dev/null \
    | grep -vE 'Promise<void>|\):\s*void\b|=>\s*void\b|void\s+0\b' \
    | grep -vE '^[0-9]+:\s*//' \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
