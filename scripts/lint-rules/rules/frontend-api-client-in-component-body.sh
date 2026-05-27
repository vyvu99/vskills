#!/bin/bash
# CANDIDATE: HTTP/API client khởi tạo bên trong function/component body thay vì module level
# CONFIDENCE: Medium — false positive khi client cần config động per-request
# FIX: Chuyển lên module level (singleton) — tránh re-allocate mỗi render/request
# SCOPE: Frontend files only — tránh false positive trên backend Map/Set constructors
# EXAMPLES:
#   ❌ function MyComponent() { const apiClient = new ApiClient(); ... }
#   ✅ const apiClient = new ApiClient();  ← module level
RULE_ID="frontend-api-client-in-component-body"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  # Scope: chỉ scan frontend directories — tránh false positive từ backend files
  [[ "$file" =~ /(components|hooks|app|pages|features)/ ]] || continue
  # Detect: indented const (≥2 spaces) với tên chứa Client/Api/Sdk/Http
  # Exclude:
  #   - React hook return values: = use[A-Z]... (useQueryClient, useApiClient, v.v.)
  #   - JS built-in constructors: Map, Set, Date, Error, URL, FormData, AbortController...
  #   - Commented lines
  grep -nE "^\s{2,}const\s+\w*(Client|Api|Sdk|Http)\w*\s*=" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | grep -vE "=\s*use[A-Z]" \
    | grep -vE "=\s*new\s+(Map|Set|Date|Error|URL|URLSearchParams|FormData|Promise|RegExp|AbortController)\s*[\(\[]" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
