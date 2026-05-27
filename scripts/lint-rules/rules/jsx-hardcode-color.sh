#!/bin/bash
RULE_ID="jsx-hardcode-color"
for file in "$@"; do
  [[ "$file" =~ \.(tsx|ts|css)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Hardcode hex/rgb in Tailwind arbitrary value brackets or style props
  grep -nE "\[#[0-9a-fA-F]{3,8}\]|rgb\s*\(|rgba\s*\(|hsl\s*\(" "$file" 2>/dev/null \
    | grep -vE "^\s*//|^\s*\*" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
