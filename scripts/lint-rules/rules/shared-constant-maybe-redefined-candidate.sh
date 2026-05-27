#!/bin/bash
# CANDIDATE: constant UPPER_CASE định nghĩa lại trong non-shared file trong khi đã exported từ packages/shared
# CONFIDENCE: Medium — có thể là intentional local override hoặc tên trùng không liên quan
# FALSE POSITIVES: ~20% — tên trùng nhưng khác semantic (e.g. local STATUS vs shared STATUS)
# EXAMPLES:
#   ❌ const STATUS_LABELS = { ... }  trong app file khi shared package đã export STATUS_LABELS
#   ✅ import { STATUS_LABELS } from '<shared-package>'
RULE_ID="shared-constant-maybe-redefined-candidate"

# Locate git root để tìm packages/shared
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[[ -z "$GIT_ROOT" ]] && exit 0

# Tìm shared package dir (thử các path phổ biến)
SHARED_DIR=""
for candidate in "packages/shared/src" "packages/shared" "libs/shared/src" "libs/shared"; do
  if [[ -d "$GIT_ROOT/$candidate" ]]; then
    SHARED_DIR="$GIT_ROOT/$candidate"
    break
  fi
done
[[ -z "$SHARED_DIR" ]] && exit 0

# Build danh sách tên constants được export từ shared (chạy 1 lần, cache trong /tmp)
CACHE_KEY="$(echo "$SHARED_DIR" | md5 2>/dev/null || echo "$SHARED_DIR" | md5sum 2>/dev/null | cut -c1-8)"
SHARED_CONSTS_FILE="/tmp/lint-shared-consts-${CACHE_KEY}.txt"
if [[ ! -f "$SHARED_CONSTS_FILE" ]]; then
  grep -r -hE "^export (const|enum) [A-Z][A-Z_0-9]+" "$SHARED_DIR" --include="*.ts" 2>/dev/null \
    | grep -oE "(const|enum) [A-Z][A-Z_0-9]+" \
    | grep -oE "[A-Z][A-Z_0-9]+" \
    | sort -u > "$SHARED_CONSTS_FILE"
fi
[[ -s "$SHARED_CONSTS_FILE" ]] || exit 0

for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Bỏ qua shared package và ui package
  [[ "$file" =~ packages/(shared|ui)/ ]] && continue

  # Match cả có và không có type annotation: const FOO = ... hoặc const FOO: Type = ...
  grep -nE "^(export\s+)?const [A-Z][A-Z_0-9]+(\s*:[^=]+)?=" "$file" 2>/dev/null \
    | while IFS= read -r hit; do
        const_name=$(echo "${hit#*:}" | grep -oE "[A-Z][A-Z_0-9]+" | head -1)
        if [[ -n "$const_name" ]] && grep -qxF "$const_name" "$SHARED_CONSTS_FILE" 2>/dev/null; then
          printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
        fi
      done
done
