# Format REPORT.md

Phase 3 ghi `.code-review/REPORT.md` theo dạng này. Phase 4.5 và Phase 5 append vào nó. Giữ nguyên tên section; fix mode parse các dòng `Status:`.

```
CODE REVIEW SUMMARY

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base}
  [or: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base}]
  [or: SINCE: {duration}  |  or: HEAD → {base}]
FILES CHANGED: X (excluded: {excluded_patterns_or_none})
GROUPS REVIEWED: N
TOTAL ISSUES: M (Critical: A, Warning: B, Suggestion: C)
REVIEW CONFIDENCE: {HIGH/MEDIUM/LOW} — {reason}
REVIEWED_COMMIT: {current HEAD sha}  [previous: {prev_sha[:8] or "none"}]

CRITICAL ISSUES (fix before merge)

  1. [CRITICAL] {Title}
     File: path/file.ts:45-52
     Source: Group A
     Issue: {description}
     Fix:
       {code}
     Conflict check: {No conflict / Conflicts with Group B — confirmed this issue is correct because...}
     Status: PENDING

WARNING ISSUES (should fix)

  1. [WARNING] ...   (same format)

SUGGESTIONS (nice to have)

  1. [SUGGESTION] ...

CROSS-GROUP ISSUES

  {Title}
    Related groups: Group A + Group B
    Issue: {description of the issue between the 2 groups}
    File: fileA.ts:10 ↔ fileB.ts:25
    Status: PENDING

RULES COMPLIANCE SUMMARY (aggregated from subagents' FAIL reports; a rule not listed passed)

  {N}. {rule} — FAIL — Group {X} — file.ts:30

FILES NOT REVIEWED
  Boilerplate (auto-skipped):
    {files, or "none"}
  User-excluded (--exclude):
    {files, or "none"}
  Comment/whitespace-only:
    {files, or "none"}

MIGRATIONS — not semantically reviewed
  {list from CONTEXT.txt MIGRATIONS SKIPPED, or "none"}
  Manual check recommended for schema and data-loss risk (see vrollback).

CONFIDENCE NOTES
  {Any file a subagent could not read, missing dependency, uncovered scope, degraded step, or dropped finding}
```

`REVIEW CONFIDENCE` là HIGH khi mọi group đều do subagent review và các spot-check đều đứng vững, MEDIUM khi có group phải quay về main agent hoặc có finding bị bỏ, LOW khi một bước như lint scan hoặc việc đọc dependency không khả dụng và diff lớn.

Report của trường hợp rỗng-sau-khi-lọc chỉ giữ header block, `TOTAL ISSUES: 0` và ghi chú một dòng từ `context-gathering.md`.
