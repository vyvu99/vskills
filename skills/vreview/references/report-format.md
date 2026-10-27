# REPORT.md Format

Phase 3 writes `.code-review/REPORT.md` in this shape. Phase 4.5 and Phase 5 append to it. Keep the section names; fix mode parses the `Status:` lines.

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

`REVIEW CONFIDENCE` is HIGH when every group was reviewed by a subagent and the spot-checks all held, MEDIUM when a group fell back to the main agent or a finding was dropped, LOW when a step such as the lint scan or a dependency read was unavailable and the diff is large.

An empty-after-filter report keeps only the header block, `TOTAL ISSUES: 0`, and the one-line note from `context-gathering.md`.
