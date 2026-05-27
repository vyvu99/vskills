#!/bin/bash
# URL/host env var với empty string default → '' là invalid URL, silent failure thay vì startup error
# FIX: z.string().url() hoặc z.string().min(1) để fail fast khi không được set
# EXAMPLES:
#   ❌ STORAGE_URL: z.string().default(''),
#   ❌ API_BASE_URL: z.string().optional().default(''),
#   ✅ STORAGE_URL: z.string().url(),
RULE_ID="backend-env-url-empty-default"
for file in "$@"; do
  [[ "$file" =~ \.(ts|mjs|js)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Only canonical env config files
  [[ "$file" =~ (^|/)env\.(ts|mjs|js)$ ]] || continue
  # URL/host/endpoint vars with empty default
  grep -nE "[A-Z_]*(URL|HOST|ENDPOINT|BASE|ORIGIN|DOMAIN)[A-Z_]*.*z\.string\(\)(\.optional\(\))?\.default\s*\('" "$file" 2>/dev/null \
    | grep -E "\.default\s*\(''\)" \
    | grep -vE "^\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
