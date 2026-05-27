#!/bin/bash
# Fire-and-forget async call không có .catch() → silent failure, HIPAA audit gap
# Pattern: method call không có await trên cùng dòng → caller không xử lý rejection
# FIX: Thêm .catch((err) => logAsyncFailure('context', err, { metadata }))
# EXAMPLES:
#   ❌ activityLog.logHistory(...)                        ← no await, no .catch()
#   ✅ activityLog.logHistory(...).catch((err) => logAsyncFailure('audit', err))
RULE_ID="backend-fire-forget-no-catch"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Scope: service, route, handler files — nơi fire-and-forget thường xảy ra
  [[ "$file" =~ -(service|route|handler|controller)\.(ts|tsx)$ ]] || continue
  # Detect: fire-and-forget method calls (no await, no .catch on same line)
  # Targets: common audit/notification methods that must not silently fail
  grep -nE "\.(logHistory|logEvent|logAccess|logCreate|logUpdate|logDelete|sendEmail|sendPushNotification|sendNotification|notifyUser|dispatchEvent)\s*\(" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | grep -vE "^\s*await\s+|^[0-9]+:\s*await\s+|^[0-9]+:\s*\w.*=\s*await" \
    | grep -vE "\.catch\s*\(" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
