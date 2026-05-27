#!/bin/bash
# Template literal trong email subject/header → CRLF injection risk
# Attacker inject "\r\nBCC: victim@evil.com" qua user-controlled field
# FIX: sanitize bằng cách strip \r \n trước khi dùng trong header
# EXAMPLES:
#   ❌ subject: `Hi ${senderName}, you received...`   ← senderName có thể chứa \r\n
#   ✅ subject: `Hi ${sanitizeEmailHeader(senderName)}, you received...`
RULE_ID="backend-email-header-template-injection"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Scope: mail/email/notification service files
  [[ "$file" =~ (mail|email|notification|mailer)\.(service|handler|util)\.(ts)$ ]] || continue
  # Detect: template literal trực tiếp trong email header fields chứa user-controlled interpolation
  grep -nE '(subject|from|to|cc|bcc|replyTo|reply_to)\s*:\s*`[^`]*\$\{' "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
