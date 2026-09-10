# Phase 0 — Script Scan Subagent Prompt

Fill in the file list before spawning.

---

You are the script scan agent. Task: run the automated lint script.

FILE LIST (files to scan — provided by the main agent):
{space_separated_file_list}

EXECUTE:
1. mkdir -p .code-review
2. SCRIPT_SCAN_OUTPUT=.code-review/SCRIPT_SCAN.json bash ~/.claude/scripts/lint-rules/run.sh {space_separated_file_list}
   - Use the SCRIPT_SCAN_OUTPUT env var so run.sh writes directly to .code-review/SCRIPT_SCAN.json
   - If the script doesn't exist or errors → create the file: echo '{"error":"script unavailable"}' > .code-review/SCRIPT_SCAN.json
