#!/bin/bash
# DB .update() trong catch block không có .catch() → nếu update lỗi, record kẹt state cũ vĩnh viễn
# FIX: await db.update(...).catch(err => logger.error(err, 'failed to update status'))
# EXAMPLES:
#   ❌ } catch (err) { await db.update(table).set({ status: 'FAILED' }); }
#   ✅ } catch (err) { await db.update(table).set({ status: 'FAILED' }).catch(e => logger.error(e)); }
RULE_ID="backend-db-update-no-catch-in-catch"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Scope: backend files only
  [[ "$file" =~ (service|handler|consumer|worker|job|repository|repo)\.(ts|tsx)$ ]] || continue
  grep -nE "\.(update|updateMany)\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check same statement (next 3 lines) for .catch(
    fwd_context=$(sed -n "${line_num},$((line_num + 3))p" "$file" 2>/dev/null)
    if ! echo "$fwd_context" | grep -qE "\.catch\s*\("; then
      # Check if we're in a catch block by scanning backwards
      back_start=$((line_num - 8)); [[ $back_start -lt 1 ]] && back_start=1
      back_context=$(sed -n "${back_start},${line_num}p" "$file" 2>/dev/null)
      if echo "$back_context" | grep -qE "}\s*catch\s*[\({]|catch\s*\("; then
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
      fi
    fi
  done
done
