#!/usr/bin/env python3
"""
Usage: python3 plan_tasks.py <epic_url>

Reads a GitHub epic's sub-issues, asks the Claude CLI to order them into a
sequential dependency chain, and writes tasks.json for run_tasks.py.
"""

import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent


def parse_issue_url(url: str) -> tuple[str, str, int]:
    """Parse owner, repo, number from a GitHub issue URL."""
    match = re.search(r'github\.com/([^/]+)/([^/]+)/issues/(\d+)', url)
    if not match:
        raise ValueError(f"Invalid GitHub issue URL: {url}")
    return match.group(1), match.group(2), int(match.group(3))


def get_default_branch(owner: str, repo: str) -> str:
    result = subprocess.run(
        ['gh', 'repo', 'view', f'{owner}/{repo}', '--json', 'defaultBranchRef',
         '-q', '.defaultBranchRef.name'],
        capture_output=True, text=True
    )
    branch = result.stdout.strip()
    return branch if result.returncode == 0 and branch else 'main'


def fetch_sub_issues(owner: str, repo: str, epic_number: int) -> list[dict]:
    query = """
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          title
          subIssues(first: 50) {
            nodes {
              number
              title
              body
              url
              state
              labels(first: 10) { nodes { name } }
              closedByPullRequestsReferences(first: 1, includeClosedPrs: true) {
                nodes {
                  url
                  merged
                  mergedAt
                  baseRefName
                }
              }
            }
          }
        }
      }
    }
    """
    result = subprocess.run(
        ['gh', 'api', 'graphql',
         '-f', f'query={query}',
         '-f', f'owner={owner}',
         '-f', f'repo={repo}',
         '-F', f'number={epic_number}'],
        capture_output=True, text=True, check=True
    )
    data = json.loads(result.stdout)
    if data.get('errors'):
        raise RuntimeError(f"GraphQL errors: {data['errors']}")
    repo_data = data['data']['repository']['issue']
    return repo_data['subIssues']['nodes']


def fetch_merged_pr_for_branch(branch_name: str, owner: str, repo: str, default_branch: str) -> dict | None:
    """Return the PR merged into the default branch for this branch, or None."""
    result = subprocess.run(
        ['gh', 'pr', 'list',
         '--repo', f'{owner}/{repo}',
         '--head', branch_name,
         '--state', 'merged',
         '--json', 'url,baseRefName,mergedAt'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return None
    prs = json.loads(result.stdout)
    for pr in prs:
        if pr.get('baseRefName') == default_branch:
            return pr
    return None


def fetch_open_prs(owner: str, repo: str) -> list[dict]:
    """Return all open PRs with headRefName, url, and closingIssuesReferences."""
    result = subprocess.run(
        ['gh', 'pr', 'list',
         '--repo', f'{owner}/{repo}',
         '--state', 'open',
         '--json', 'headRefName,url,baseRefName,closingIssuesReferences'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    return json.loads(result.stdout)


def resolve_task_statuses(
    tasks: list[dict], sub_issues: list[dict], owner: str, repo: str, default_branch: str
) -> list[dict]:
    """
    For each task:
    - Issue CLOSED + PR merged into the default branch (via closedByPullRequestsReferences,
      or a branch-name lookup as fallback) → status="done"
    - Issue OPEN + has an open PR → status="pending", branch_name updated to the real branch,
      open_pr_url set
    - depends_on entries pointing at a done task are dropped, so step 2's get_parent_branch
      naturally falls back to the default branch
    """
    state_by_number = {issue['number']: issue['state'] for issue in sub_issues}

    # Prefer closedByPullRequestsReferences (accurate, doesn't rely on branch-name matching)
    pr_by_number: dict[int, dict | None] = {}
    for issue in sub_issues:
        closed_prs = issue.get('closedByPullRequestsReferences', {}).get('nodes', [])
        for pr in closed_prs:
            if pr.get('merged') and pr.get('baseRefName') == default_branch:
                pr_by_number[issue['number']] = pr
                break

    # Fallback: CLOSED but closedByPullRequestsReferences empty → look up by branch name
    fallback_tasks = [
        t for t in tasks
        if state_by_number.get(t['number']) == 'CLOSED' and t['number'] not in pr_by_number
    ]

    if fallback_tasks:
        print(f"Checking merged PRs by branch for {len(fallback_tasks)} closed issue(s) (fallback)...")
        with ThreadPoolExecutor(max_workers=min(len(fallback_tasks), 8)) as pool:
            futures = {
                pool.submit(fetch_merged_pr_for_branch, t['branch_name'], owner, repo, default_branch): t['number']
                for t in fallback_tasks
            }
            for future in as_completed(futures):
                pr_by_number[futures[future]] = future.result()

    done_numbers: set[int] = set()
    for task in tasks:
        pr = pr_by_number.get(task['number'])
        if pr:
            task['status'] = 'done'
            task['pr_url'] = pr['url']
            task['completed_at'] = pr.get('mergedAt')
            done_numbers.add(task['number'])
            print(f"  ✓ #{task['number']} already done — {pr['url']}")
        else:
            task['status'] = 'pending'

    # Drop deps already done, so step 2's get_parent_branch returns the default branch
    for task in tasks:
        if task['status'] == 'pending':
            task['depends_on'] = [d for d in task.get('depends_on', []) if d not in done_numbers]

    # Point pending tasks with an already-open PR at their real branch name
    open_prs = fetch_open_prs(owner, repo)
    open_pr_by_issue: dict[int, dict] = {}
    for pr in open_prs:
        # Prefer closingIssuesReferences (accurate, doesn't depend on branch naming)
        for ref in pr.get('closingIssuesReferences', []):
            open_pr_by_issue[ref['number']] = pr
        # Fallback: an issue-{number} pattern in the branch name
        if not pr.get('closingIssuesReferences'):
            m = re.search(r'issue-(\d+)', pr.get('headRefName', ''))
            if m:
                open_pr_by_issue[int(m.group(1))] = pr

    for task in tasks:
        if task['status'] == 'pending':
            pr = open_pr_by_issue.get(task['number'])
            if pr:
                actual_branch = pr['headRefName']
                task['open_pr_url'] = pr['url']
                if actual_branch != task['branch_name']:
                    print(f"  ~ #{task['number']} has an open PR → branch updated: {actual_branch}")
                    task['branch_name'] = actual_branch
                else:
                    print(f"  ~ #{task['number']} has an open PR — {pr['url']}")

    return tasks


def ask_claude_to_order(epic_url: str, epic_title: str, sub_issues: list[dict]) -> list[dict]:
    issues_text = ""
    for issue in sub_issues:
        labels = [lb['name'] for lb in issue.get('labels', {}).get('nodes', [])]
        body_preview = (issue.get('body') or '')[:500]
        issues_text += (
            f"\nIssue #{issue['number']}: {issue['title']}\n"
            f"URL: {issue['url']}\n"
            f"Labels: {', '.join(labels) if labels else 'none'}\n"
            f"Body:\n{body_preview}\n"
            "---"
        )

    prompt = f"""You are a tech lead. Analyze the following sub-tasks of a GitHub epic and decide a
sensible execution order.
Requirement: arrange them into a sequential chain — each task depends on exactly the one before it.
Branch name: feat/issue-{{number}}-{{slug}} (slug derived from the title, lowercase + hyphens, max 40 chars)

Epic: {epic_url}
Title: {epic_title}

Sub-tasks:
{issues_text}

Output ONLY a raw JSON array (no markdown, no explanation), sorted by execution order:
[
  {{
    "number": 136,
    "title": "Task title",
    "task_url": "https://github.com/.../issues/136",
    "branch_name": "feat/issue-136-task-slug",
    "order": 1
  }}
]"""

    result = subprocess.run(
        ['claude', '-p', prompt, '--dangerously-skip-permissions', '--output-format', 'json'],
        capture_output=True, text=True, check=True
    )

    outer = json.loads(result.stdout)
    raw_text = outer.get('result', '')

    # Extract the JSON array from Claude's response (may include markdown fences)
    json_match = re.search(r'\[.*\]', raw_text, re.DOTALL)
    if not json_match:
        raise ValueError(f"Claude did not return a valid JSON array:\n{raw_text}")

    tasks = sorted(json.loads(json_match.group(0)), key=lambda t: t.get('order', 999))

    # Enforce a sequential chain: task[i] depends only on task[i-1]
    for i, task in enumerate(tasks):
        task['depends_on'] = [tasks[i - 1]['number']] if i > 0 else []

    return tasks


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 plan_tasks.py <epic_url>")
        sys.exit(1)

    epic_url = sys.argv[1]
    owner, repo, epic_number = parse_issue_url(epic_url)
    default_branch = get_default_branch(owner, repo)

    print(f"Fetching sub-issues for epic #{epic_number} ({owner}/{repo}, default branch: {default_branch})...")
    sub_issues = fetch_sub_issues(owner, repo, epic_number)

    if not sub_issues:
        print("No sub-issues found!")
        sys.exit(1)

    epic_result = subprocess.run(
        ['gh', 'issue', 'view', str(epic_number), '--repo', f'{owner}/{repo}', '--json', 'title'],
        capture_output=True, text=True, check=True
    )
    epic_title = json.loads(epic_result.stdout)['title']

    print(f"Found {len(sub_issues)} sub-issues. Asking Claude to order them...")
    tasks = ask_claude_to_order(epic_url, epic_title, sub_issues)

    task_list = [
        {
            "number": t["number"],
            "title": t["title"],
            "task_url": t["task_url"],
            "branch_name": t["branch_name"],
            "depends_on": t.get("depends_on", []),
            "started_at": None,
            "completed_at": None,
        }
        for t in tasks
    ]

    task_list = resolve_task_statuses(task_list, sub_issues, owner, repo, default_branch)

    output = {
        "epic_url": epic_url,
        "default_branch": default_branch,
        "generated_at": datetime.now().isoformat(),
        "tasks": task_list,
    }

    output_path = SCRIPT_DIR / "tasks.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\nGenerated {output_path}:")
    for task in output["tasks"]:
        icon = "✓" if task['status'] == 'done' else "○"
        deps = f" (depends on: {', '.join(f'#{d}' for d in task['depends_on'])})" if task["depends_on"] else ""
        print(f"  {icon} #{task['number']}: {task['title']}{deps}")

    done_count = sum(1 for t in output["tasks"] if t['status'] == 'done')
    if done_count:
        print(f"\n{done_count} task(s) already done (will be skipped in step 2).")
    print("\nReview/edit tasks.json if needed, then run: python3 run_tasks.py")


if __name__ == "__main__":
    main()
