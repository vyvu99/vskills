#!/bin/bash
# process.env.X direct access outside canonical env config files
# FIX: Đọc qua config object tập trung (env.ts / config.ts)
# EXAMPLES:
#   ❌ const region = process.env.AWS_REGION;
#   ✅ const region = env.AWS_REGION;  // via env.ts
RULE_ID="ts-process-env-direct-access"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx|js|mjs)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Skip canonical config files — these ARE the allowed access points
  [[ "$file" =~ (^|/)env\.(ts|mjs|js)$ ]] && continue
  [[ "$file" =~ (^|/)config\.(ts|mjs|js)$ ]] && continue
  # Skip build tooling
  [[ "$file" =~ \.(config\.ts|config\.js|config\.mjs|config\.cjs)$ ]] && continue
  # Skip test files
  [[ "$file" =~ \.(test|spec)\.(ts|tsx|js)$ ]] && continue
  grep -nE "process\.env\.[A-Z_][A-Z0-9_]+" "$file" 2>/dev/null \
    | grep -vE "process\.env\.NODE_ENV" \
    | grep -vE "^\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
