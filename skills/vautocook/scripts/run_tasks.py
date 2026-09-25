#!/usr/bin/env python3
"""
Usage: python3 run_tasks.py

Executes tasks from tasks.json in order. Supports resume across interrupts.
- A task left "running" (interrupted mid-run) is reset to "pending" and retried.
- Fail-fast: the pipeline stops as soon as one task fails.

Each task shells out to `claude -p <prompt> --dangerously-skip-permissions`, which
runs /vcook on the task's issue in headless mode. /vcook is expected to create its
own commit + PR (its own Step 9); this script only verifies a PR exists afterwards
and falls back to opening a minimal one itself if /vcook didn't manage to.
"""

import json
import os
import pty
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

_ANSI_RE = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b.')

_C = {
    'reset':  '\033[0m',
    'bold':   '\033[1m',
    'dim':    '\033[2m',
    'cyan':   '\033[36m',
    'green':  '\033[32m',
    'yellow': '\033[33m',
    'gray':   '\033[90m',
    'red':    '\033[31m',
}


def _c(color: str, text: str) -> str:
    return f"{_C.get(color, '')}{text}{_C['reset']}"


# Dedup: track which content blocks were already printed, per message id
_printed_blocks: dict[str, set] = {}


def _print_stream_event(event: dict) -> bool:
    """Print a stream-json event in a readable, colored form. Returns True on a
    'result' event (session finished)."""
    t = event.get('type', '')

    if t == 'assistant':
        msg = event.get('message', {})
        msg_id = msg.get('id', '')
        seen = _printed_blocks.setdefault(msg_id, set())
        for block in msg.get('content', []):
            bt = block.get('type', '')
            if bt == 'thinking':
                key = 'thinking'
                if key not in seen:
                    seen.add(key)
                    preview = block.get('thinking', '')[:120].replace('\n', ' ')
                    print(_c('gray', f"  \U0001f4ad {preview}…"), flush=True)
            elif bt == 'text':
                text = block.get('text', '').strip()
                key = f"text:{text[:40]}"
                if key not in seen and text:
                    seen.add(key)
                    print(_c('green', f"  ✦ {text}"), flush=True)
            elif bt == 'tool_use':
                name = block.get('name', '?')
                inp = block.get('input', {})
                key = f"tool:{name}:{list(inp.values())[:1]}"
                if key not in seen:
                    seen.add(key)
                    arg = next(iter(inp.values()), '') if inp else ''
                    arg_str = str(arg)[:80].replace('\n', '↵')
                    print(_c('cyan', f"  ⚙ {_c('bold', name)} {_c('dim', arg_str)}"), flush=True)

    elif t == 'user':
        msg = event.get('message', {})
        for block in msg.get('content', []):
            if block.get('type') == 'tool_result':
                is_err = block.get('is_error', False)
                content = str(block.get('content', ''))[:100].replace('\n', ' ')
                if is_err:
                    print(_c('red', f"  ✗ {content}"), flush=True)
                # Non-error tool results → skip (too noisy)

    elif t == 'result':
        cost = event.get('cost_usd')
        turns = event.get('num_turns')
        subtype = event.get('subtype', '')
        color = 'green' if subtype == 'success' else 'red'
        suffix = f"  turns={turns}" + (f"  cost=${cost:.4f}" if cost else '')
        print(_c(color, f"\n  {'✓' if subtype == 'success' else '✗'} done{suffix}"), flush=True)
        return True  # session finished, caller should break

    elif t == 'system' and event.get('subtype') == 'init':
        tools = event.get('tools', [])
        print(_c('dim', f"  session init — {len(tools)} tools"), flush=True)

    return False


SCRIPT_DIR = Path(__file__).parent
TASKS_FILE = SCRIPT_DIR / "tasks.json"
PROMPT_FILE = SCRIPT_DIR / "prompt.md"


def load_tasks() -> dict:
    with open(TASKS_FILE, encoding='utf-8') as f:
        return json.load(f)


def save_tasks(config: dict) -> None:
    with open(TASKS_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)


def find_task(config: dict, number: int) -> dict | None:
    return next((t for t in config['tasks'] if t['number'] == number), None)


def _parse_owner_repo(task_url: str) -> tuple[str, str]:
    """Split owner/repo out of a task's issue URL."""
    match = re.search(r'github\.com/([^/]+)/([^/]+)/issues/\d+', task_url)
    if not match:
        raise ValueError(f"Invalid GitHub issue URL: {task_url}")
    return match.group(1), match.group(2)


def get_parent_branch(config: dict, task: dict) -> str:
    """Branch to check out from: the default branch, or the dependency task's branch."""
    default_branch = config.get('default_branch', 'main')
    if not task['depends_on']:
        return f'origin/{default_branch}'
    dep_number = task['depends_on'][-1]
    dep_task = find_task(config, dep_number)
    if dep_task is None:
        raise ValueError(f"Dependency task #{dep_number} not found in tasks.json")
    # Dep already merged (pr_url set by plan_tasks.py) → base off the default branch
    if dep_task.get('pr_url'):
        return f'origin/{default_branch}'
    return f"origin/{dep_task['branch_name']}"


def _find_open_pr_by_branch(owner: str, repo: str, branch: str) -> dict | None:
    result = subprocess.run(
        ['gh', 'pr', 'list',
         '--repo', f'{owner}/{repo}',
         '--head', branch,
         '--state', 'open',
         '--json', 'number,title,url,headRefName,baseRefName'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return None
    prs = json.loads(result.stdout)
    return prs[0] if prs else None


def ensure_pr(task: dict, parent_branch: str) -> str | None:
    """Verify /vcook opened a PR for this branch; if not, open a minimal fallback one."""
    branch = task['branch_name']
    owner, repo = _parse_owner_repo(task['task_url'])
    base = parent_branch.removeprefix('origin/')

    existing = _find_open_pr_by_branch(owner, repo, branch)
    if existing:
        print(_c('green', f"  ✓ PR already open (created by /vcook): {existing['url']}"), flush=True)
        return existing['url']

    print(_c('yellow', "  /vcook did not open a PR — pushing branch and opening a fallback one"), flush=True)
    push_result = subprocess.run(['git', 'push', '-u', 'origin', branch], capture_output=True, text=True)
    if push_result.returncode != 0:
        print(_c('red', f"  ✗ Push failed: {push_result.stderr.strip()}"), flush=True)
        return None

    result = subprocess.run(
        ['gh', 'pr', 'create',
         '--repo', f'{owner}/{repo}',
         '--base', base,
         '--head', branch,
         '--title', task['title'],
         '--body', f"Closes #{task['number']}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(_c('red', f"  ✗ Fallback PR creation failed: {result.stderr.strip()}"), flush=True)
        return None

    pr_url = result.stdout.strip()
    print(_c('green', f"  ✓ Fallback PR created: {pr_url}"), flush=True)
    return pr_url


def checkout_branch(branch_name: str, parent_branch: str) -> None:
    subprocess.run(['git', 'fetch', 'origin'], check=True)

    check = subprocess.run(['git', 'rev-parse', '--verify', branch_name], capture_output=True)

    if check.returncode == 0:
        subprocess.run(['git', 'checkout', branch_name], check=True)
        print(f"  Resumed on existing branch: {branch_name}")
    else:
        resolved_parent = parent_branch
        verify = subprocess.run(['git', 'rev-parse', '--verify', parent_branch], capture_output=True)
        if verify.returncode != 0 and parent_branch.startswith('origin/'):
            local_fallback = parent_branch.removeprefix('origin/')
            print(f"  Warning: {parent_branch} not on remote, using local {local_fallback}")
            resolved_parent = local_fallback

        subprocess.run(['git', 'checkout', '-b', branch_name, resolved_parent], check=True)
        print(f"  Created branch: {branch_name} (from {resolved_parent})")


def fill_prompt(task: dict, config: dict, parent_branch: str) -> str:
    template = PROMPT_FILE.read_text(encoding='utf-8')
    return (
        template
        .replace('{{TASK_URL}}', task['task_url'])
        .replace('{{EPIC_URL}}', config['epic_url'])
        .replace('{{BRANCH_NAME}}', task['branch_name'])
        .replace('{{PARENT_BRANCH}}', parent_branch)
        .replace('{{ISSUE_NUMBER}}', str(task['number']))
    )


def run_task(task: dict, config: dict) -> bool:
    print(f"\n{'=' * 60}")
    print(f"Task #{task['number']}: {task['title']}")

    for dep_number in task['depends_on']:
        dep_task = find_task(config, dep_number)
        if dep_task is None or dep_task['status'] != 'done':
            print(f"ERROR: Dependency #{dep_number} is not done yet!")
            return False

    parent_branch = get_parent_branch(config, task)
    checkout_branch(task['branch_name'], parent_branch)

    prompt = fill_prompt(task, config, parent_branch)

    task['status'] = 'running'
    task['started_at'] = datetime.now().isoformat()
    save_tasks(config)

    print("  Running Claude CLI...", flush=True)
    master, slave = pty.openpty()
    proc = subprocess.Popen(
        ['claude', '-p', prompt, '--dangerously-skip-permissions',
         '--output-format', 'stream-json', '--verbose'],
        stdout=slave,
        stderr=slave,
        stdin=slave,
        # No setsid → child shares our process group → Ctrl+C propagates naturally
    )
    os.close(slave)

    buf = ''
    interrupted = False
    try:
        while True:
            try:
                chunk = os.read(master, 4096).decode('utf-8', errors='ignore')
                buf += _ANSI_RE.sub('', chunk)
                while '\n' in buf:
                    line, buf = buf.split('\n', 1)
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        if _print_stream_event(json.loads(line)):
                            raise StopIteration  # result event → exit the loop
                    except json.JSONDecodeError:
                        print(f"  {line}", flush=True)
            except OSError:
                break  # PTY closed when the process exits
    except StopIteration:
        pass
    except KeyboardInterrupt:
        interrupted = True
        proc.kill()  # SIGKILL → returns immediately, doesn't block
    finally:
        try:
            os.close(master)
        except OSError:
            pass
        proc.wait()

    if interrupted:
        raise KeyboardInterrupt

    if proc.returncode == 0:
        task['status'] = 'done'
        task['completed_at'] = datetime.now().isoformat()
        print(f"  ✓ Task #{task['number']} completed")
        save_tasks(config)
        pr_url = ensure_pr(task, parent_branch)
        if pr_url is None:
            task['status'] = 'failed'
            task['completed_at'] = datetime.now().isoformat()
            print(f"  ✗ Task #{task['number']} FAILED — no PR could be opened")
            save_tasks(config)
        else:
            task['open_pr_url'] = pr_url
            save_tasks(config)
    else:
        task['status'] = 'failed'
        task['completed_at'] = datetime.now().isoformat()
        print(f"  ✗ Task #{task['number']} FAILED (exit code: {proc.returncode})")
        save_tasks(config)

    return task['status'] == 'done' and task.get('open_pr_url') is not None


def _print_merge_order(config: dict) -> None:
    """Print the order stacked PRs should be merged into the default branch."""
    tasks = config['tasks']

    open_pr_tasks = [t for t in tasks if t.get('open_pr_url') and not t.get('pr_url')]
    if not open_pr_tasks:
        return

    remaining = {t['number']: t for t in open_pr_tasks}
    merged_set: set[int] = {t['number'] for t in tasks if t.get('pr_url')}
    levels: list[list[dict]] = []

    while remaining:
        ready = [t for t in remaining.values() if all(d in merged_set for d in t.get('depends_on', []))]
        if not ready:
            levels.append(list(remaining.values()))  # circular or missing — dump the rest as-is
            break
        levels.append(ready)
        for t in ready:
            merged_set.add(t['number'])
            del remaining[t['number']]

    default_branch = config.get('default_branch', 'main')
    print(_c('bold', f"\n{'=' * 60}"))
    print(_c('bold', f"MERGE ORDER — merge into {default_branch} top to bottom:"))
    print(_c('dim', "(after merging a level, rebase the next level's PRs before merging them)"))
    for i, level in enumerate(levels, 1):
        label = f"→ {default_branch} directly" if i == 1 else f"→ {default_branch} (after level {i - 1})"
        print(f"\n  Level {i} {_c('dim', label)}:")
        for t in level:
            pr = t.get('open_pr_url', '(no PR)')
            print(f"    {_c('cyan', pr)}  #{t['number']} {t['title']}")
    print()


def main():
    if not TASKS_FILE.exists():
        print("tasks.json not found. Run plan_tasks.py first.")
        sys.exit(1)

    if not PROMPT_FILE.exists():
        print("prompt.md not found.")
        sys.exit(1)

    config = load_tasks()
    tasks = config['tasks']

    to_reset = [t for t in tasks if t['status'] in ('running', 'failed')]
    for task in to_reset:
        print(f"Resetting {task['status']} task #{task['number']} → pending")
        task['status'] = 'pending'
        task['started_at'] = None
        task['completed_at'] = None
    if to_reset:
        save_tasks(config)

    done_count = sum(1 for t in tasks if t['status'] == 'done')
    pending = [t for t in tasks if t['status'] == 'pending']

    print(f"Progress: {done_count}/{len(tasks)} done, {len(pending)} pending")

    missing_pr = [
        t for t in tasks
        if t['status'] == 'done' and not t.get('open_pr_url') and not t.get('pr_url')
    ]
    if missing_pr:
        print(f"\nOpening missing PRs for {len(missing_pr)} done task(s)...")
        for task in missing_pr:
            parent_branch = get_parent_branch(config, task)
            pr_url = ensure_pr(task, parent_branch)
            if pr_url:
                task['open_pr_url'] = pr_url
                save_tasks(config)
            else:
                print(_c('yellow', f"  ⚠ Could not open a PR for #{task['number']} — create it manually"))

    if not pending:
        print("All tasks are done!")
        _print_merge_order(config)
        return

    for task in pending:
        success = run_task(task, config)
        if not success:
            print(f"\nPipeline stopped. Fix task #{task['number']} and re-run.")
            sys.exit(1)

    print(f"\n{'=' * 60}")
    print(f"All {len(tasks)} tasks completed!")
    _print_merge_order(config)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
