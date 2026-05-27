#!/bin/bash
# CANDIDATE: 2 await DB calls liên tiếp — có thể dùng Promise.all nếu độc lập
RULE_ID="backend-sequential-await-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  prev_was_await=0
  prev_line=0
  prev_content=""
  while IFS= read -r numbered_line; do
    line_num="${numbered_line%%:*}"
    content="${numbered_line#*:}"
    if echo "$content" | grep -qE "^\s*const [a-zA-Z_]+ = await (db|.*repository\.|.*service\.|.*Repository\.|.*Service\.)"; then
      if [[ $prev_was_await -eq 1 && $((line_num - prev_line)) -le 2 ]]; then
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$prev_line" "$prev_content"
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "$content"
      fi
      prev_was_await=1
      prev_line=$line_num
      prev_content="$content"
    else
      # Reset if non-await line in between (allows 1 blank line)
      echo "$content" | grep -qE "^\s*$" || prev_was_await=0
    fi
  done < <(grep -nE "^\s*const [a-zA-Z_]+ = await " "$file" 2>/dev/null)
done
