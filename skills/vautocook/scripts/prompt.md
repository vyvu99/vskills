Headless run — no user is present to answer questions. Implement GitHub issue {{TASK_URL}} (a sub-issue of epic {{EPIC_URL}}).

You are already on branch {{BRANCH_NAME}}, checked out from {{PARENT_BRANCH}}. Verify you're on it before doing anything else; if not, check it out yourself.

Run `/vcook` for this issue: if a plan file under `plans/` matches this issue's scope (check `plans/*/phase-*.md` and `plans/*/plan.md` for a match — this epic may have been created by `vtickets` from a `vplan` plan), pass that file as the plan-path argument; otherwise pass a one-line task description derived from the issue's title/body. Always pass `--issue {{ISSUE_NUMBER}}`.

This run is fully autonomous: you will NOT be asked to confirm anything, and no one is available to answer a clarifying question. Wherever `/vcook`'s own instructions say to stop and ask the user (a dirty working tree, a plan/codebase mismatch, 2+ valid interpretations, an unconfirmed trade-off) — do not stop. Decide it yourself, using root-cause analysis and KISS/DRY, pick the option a careful senior engineer would defend, and record what you decided and why in a `## Technical decisions` section of the PR body (add this section only if you actually had to make such a call).

Let `/vcook`'s own Step 9 create the commit and the PR — don't skip it and don't invent a different flow.

Before finishing: self-review the full diff once more (compile/type errors, logic gaps, anything inconsistent with the rest of the codebase) and fix anything you find. Only stop once you're confident the change is correct and complete.
