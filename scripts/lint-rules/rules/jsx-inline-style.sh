#!/bin/bash
RULE_ID="jsx-inline-style"
for file in "$@"; do
  [[ "$file" =~ \.(tsx|ts)$ ]] || continue
  [[ -f "$file" ]] || continue
  # style={{ ... }} prop or <style> tag — use Tailwind
  grep -nE "style=\{\{|<style(\s|>)" "$file" 2>/dev/null \
    | grep -vE "^\s*//|^\s*\*" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done
