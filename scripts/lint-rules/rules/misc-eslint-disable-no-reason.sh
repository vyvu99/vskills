#!/bin/bash
RULE_ID="misc-eslint-disable-no-reason"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx|js|jsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # eslint-disable without a WHY explanation after the rule name
  # Valid:   // eslint-disable-next-line rule-name -- because of X
  # Valid:   // eslint-disable-next-line rule-name // why X
  # Invalid: // eslint-disable-next-line rule-name  (nothing after)
  grep -nE "//[[:space:]]*(eslint-disable(-next-line|-line)?)[[:space:]]+[a-z/@]" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        line="${hit#*:}"
        # Skip lines that already have explanation
        echo "$line" | grep -qEi "NOSONAR" && continue
        echo "$line" | grep -qE " -- | why | because " && continue
        # Flag if no comment text appears after the rule name(s)
        if ! echo "$line" | grep -qE "[a-z/@-]+[[:space:]]+//[[:space:]]*.+"; then
          printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "$line"
        fi
      done
done
