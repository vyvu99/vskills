Headless run — no user is present to answer questions. Every sub-issue of epic {{EPIC_URL}} has been implemented and committed on branch {{BRANCH_NAME}} (already pushed). Open the ONE pull request for the whole epic.

Run `gh pr create --base {{BASE_BRANCH}} --head {{BRANCH_NAME}}`. Follow `/vcook`'s Step 9 PR rules: if `.github/pull_request_template.md` exists the body must follow it exactly, else use Summary / Changes / Test plan. Review `git log --oneline origin/{{BASE_BRANCH}}..{{BRANCH_NAME}}` and the diff first so the description reflects what actually changed across all sub-issues, grouped per sub-issue. If any commit body carries a `Technical decisions:` paragraph, gather them into a `## Technical decisions` section of the PR body.

Title: English, concise. Body: in the project's communication language (project `CLAUDE.md`'s `## Ngôn ngữ`/`## Language` section, else the global one, else English), non-technical, focused on user/business impact — do not default to English just because the run is autonomous.

Put these lines at the TOP of the PR body, verbatim, so merging closes every sub-issue:

{{CLOSES}}

Then append a link to the PR at the end of the epic issue's body (`gh issue edit`). Do not change any code.
