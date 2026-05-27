#!/bin/bash
# CANDIDATE: useQuery/useSuspenseQuery không có loading/error handling gần đó
RULE_ID="frontend-usequery-no-loading-state-candidate"
for file in "$@"; do
  [[ "$file" =~ \.tsx$ ]] || continue
  [[ -f "$file" ]] || continue
  grep -nE "\buseQuery\s*\(|\buseSuspenseQuery\s*\(" "$file" 2>/dev/null | while IFS= read -r hit; do
    line_num="${hit%%:*}"
    # Check toàn file — component nhỏ thường <150 lines, loading state thường ở JSX phía dưới
    context=$(cat "$file" 2>/dev/null)
    if ! echo "$context" | grep -qE "isLoading|isPending|isError|error|isFetching|Skeleton|Spinner|Loading|ErrorState|EmptyState"; then
      printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "$line_num" "${hit#*:}"
    fi
  done
done
