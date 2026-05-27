#!/bin/bash
# CANDIDATE: form file định nghĩa z.object({ inline thay vì import schema từ shared
# CONFIDENCE: Medium — form schema local là hợp lệ, nhưng cần verify constraints khớp shared schema
# FALSE POSITIVES: ~40% — form có thể dùng local schema với mapping hợp lệ
# EXAMPLES:
#   ❌ z.object({ signatureName: z.string().min(1) })  trong form.tsx — thiếu .max(200) từ shared schema
#   ✅ import { signTreatmentPlanSchema } from '<shared-package>/schemas'
RULE_ID="form-schema-not-shared-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Chỉ check form/modal/dialog components
  [[ "$file" =~ [Ff]orm\.(ts|tsx)$|-(form|modal|dialog|sheet)\.(ts|tsx)$ ]] || continue

  # Bỏ qua nếu file đã import một schema/validation symbol từ bất kỳ module nào
  # (scoped package, path alias, hoặc relative import — không hardcode tên project)
  if grep -E "^\s*import\b.*\bfrom\s+['\"]" "$file" 2>/dev/null \
      | grep -qiE "(schema|validation)"; then
    continue
  fi

  # Flag: định nghĩa z.object({ inline
  grep -nE "z\.object\s*\(\s*\{" "$file" 2>/dev/null \
    | grep -v "^[0-9]*:.*[/][/]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
