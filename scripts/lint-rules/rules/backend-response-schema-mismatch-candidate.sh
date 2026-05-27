#!/bin/bash
# CANDIDATE: c.json(rawVariable) trong route file — có thể expose DB fields không thuộc response schema
# CONFIDENCE: Medium — false positive khi variable đã được schema-filter trên dòng trước
# FALSE POSITIVES: ~30% — biến đã parse qua schema nhưng pattern không detect được
# EXAMPLES:
#   ❌ c.json(plan, 200)              — plan là DB entity raw, lộ clientSignedIp etc.
#   ✅ c.json(responseSchema.parse(plan), 200)
#   ✅ c.json({ id: plan.id, title: plan.title }, 200)
RULE_ID="backend-response-schema-mismatch-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ [-.](route|routes|handler|controller|router)\.(ts|tsx)$ ]] || continue
  # Pattern 1: c.json(bareVariable) — raw entity trực tiếp
  # Pattern 2: c.json({ data: bareVariable }) — raw entity wrapped trong object
  grep -nE "c\.json\s*\(\s*(\{[^}]*(data|result|record|item):\s*[a-z][a-zA-Z0-9_]+|[a-z][a-zA-Z0-9_]+)\s*[,)]" "$file" 2>/dev/null \
    | grep -vE "\.(parse|safeParse|omit|pick|strip|select)\s*\(" \
    | grep -vE "c\.json\s*\(\s*(null|true|false|undefined|0|1|\"|\[)" \
    | grep -v "^[0-9]*:.*[/][/]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
