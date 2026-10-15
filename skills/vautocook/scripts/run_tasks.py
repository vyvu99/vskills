#!/usr/bin/env python3
"""
Usage: python3 run_tasks.py

Executes tasks from tasks.json in order. Supports resume across interrupts.
- A task left "running" (interrupted mid-run) is reset to "pending" and retried.
- Fail-fast: the pipeline stops as soon as one task fails.

All tasks share ONE epic branch. Each task shells out to a fresh
`claude -p <prompt> --dangerously-skip-permissions` (a new session, so context is
cleared between tasks) that runs /vcook on the task's issue in headless mode and
commits — /vcook does not open a PR. After every task this script pushes the branch;
once all tasks are done it opens the single PR for the whole epic.
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
PR_PROMPT_FILE = SCRIPT_DIR / "pr-prompt.md"
LOGS_DIR = SCRIPT_DIR / "logs"
PIPELINE_STATUS_FILE = SCRIPT_DIR / "pipeline_status.json"


def write_pipeline_status(state: str, **extra) -> None:
    """Sentinel a Claude session (e.g. the one that opened this run in a Warp
    tab) can poll for instead of asking the user whether the run is done.
    state: 'running' | 'completed' | 'stopped' | 'interrupted'."""
    with open(PIPELINE_STATUS_FILE, 'w', encoding='utf-8') as f:
        json.dump({'state': state, 'at': datetime.now().isoformat(), **extra}, f, indent=2)


def load_tasks() -> dict:
    with open(TASKS_FILE, encoding='utf-8') as f:
        return json.load(f)


def save_tasks(config: dict) -> None:
    with open(TASKS_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)


def find_task(config: dict, number: int) -> dict | None:
    return next((t for t in config['tasks'] if t['number'] == number), None)


def _parse_owner_repo(issue_url: str) -> tuple[str, str]:
    """Split owner/repo out of a GitHub issue URL."""
    match = re.search(r'github\.com/([^/]+)/([^/]+)/issues/\d+', issue_url)
    if not match:
        raise ValueError(f"Invalid GitHub issue URL: {issue_url}")
    return match.group(1), match.group(2)


def _find_open_pr_by_branch(owner: str, repo: str, branch: str) -> dict | None:
    result = subprocess.run(
        ['gh', 'pr', 'list',
         '--repo', f'{owner}/{repo}',
         '--head', branch,
         '--state', 'open',
         '--json', 'number,url'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return None
    prs = json.loads(result.stdout)
    return prs[0] if prs else None


def checkout_epic_branch(config: dict) -> None:
    branch = config['epic_branch']
    default_branch = config.get('default_branch', 'main')
    subprocess.run(['git', 'fetch', 'origin'], check=True)

    if subprocess.run(['git', 'rev-parse', '--verify', branch], capture_output=True).returncode == 0:
        subprocess.run(['git', 'checkout', branch], check=True)
        print(f"Resumed on existing branch: {branch}")
    elif subprocess.run(['git', 'rev-parse', '--verify', f'origin/{branch}'], capture_output=True).returncode == 0:
        # Pushed earlier but no local copy (fresh clone / deleted) — track it rather than
        # recreating from the default branch, which would diverge from the pushed history.
        subprocess.run(['git', 'checkout', '-b', branch, '--track', f'origin/{branch}'], check=True)
        print(f"Resumed on remote branch: origin/{branch}")
    else:
        subprocess.run(['git', 'checkout', '-b', branch, f'origin/{default_branch}'], check=True)
        print(f"Created branch: {branch} (from origin/{default_branch})")


def head_sha() -> str:
    return subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()


def fill_prompt(task: dict, config: dict) -> str:
    template = PROMPT_FILE.read_text(encoding='utf-8')
    return (
        template
        .replace('{{TASK_URL}}', task['task_url'])
        .replace('{{EPIC_URL}}', config['epic_url'])
        .replace('{{BRANCH_NAME}}', config['epic_branch'])
        .replace('{{ISSUE_NUMBER}}', str(task['number']))
    )


def run_claude(prompt: str, log_path: Path) -> int:
    """Run one headless claude session, streaming a readable summary and the raw
    transcript to log_path. Returns the exit code; re-raises KeyboardInterrupt."""
    print(f"  Full raw transcript (every bash command + full output, unfiltered): {log_path}", flush=True)
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
    with open(log_path, 'a', encoding='utf-8') as log_file:
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
                        log_file.write(line + '\n')
                        log_file.flush()
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
    return proc.returncode


def new_log_path(name: str) -> Path:
    LOGS_DIR.mkdir(exist_ok=True)
    return LOGS_DIR / f"{name}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.jsonl"


def run_task(task: dict, config: dict) -> bool:
    print(f"\n{'=' * 60}")
    print(f"Task #{task['number']}: {task['title']}")

    for dep_number in task['depends_on']:
        dep_task = find_task(config, dep_number)
        if dep_task is None or dep_task['status'] != 'done':
            print(f"ERROR: Dependency #{dep_number} is not done yet!")
            return False

    task['status'] = 'running'
    task['started_at'] = datetime.now().isoformat()
    log_path = new_log_path(f"task-{task['number']}")
    task['log_file'] = str(log_path)
    save_tasks(config)

    sha_before = head_sha()
    returncode = run_claude(fill_prompt(task, config), log_path)
    task['completed_at'] = datetime.now().isoformat()

    if returncode != 0:
        task['status'] = 'failed'
        print(f"  ✗ Task #{task['number']} FAILED (exit code: {returncode})")
        print(f"  Full transcript for debugging: {log_path}")
    elif head_sha() == sha_before:
        task['status'] = 'failed'
        print(f"  ✗ Task #{task['number']} FAILED — session exited cleanly but made no commit")
        print(f"  Full transcript for debugging: {log_path}")
    elif subprocess.run(['git', 'push', '-u', 'origin', config['epic_branch']]).returncode != 0:
        task['status'] = 'failed'
        print(f"  ✗ Task #{task['number']} FAILED — could not push {config['epic_branch']}")
    else:
        task['status'] = 'done'
        print(f"  ✓ Task #{task['number']} completed and pushed")

    save_tasks(config)
    return task['status'] == 'done'


def ensure_epic_pr(config: dict) -> str | None:
    """One PR for the whole epic: let a headless session write it (language/template rules
    live in its prompt), then fall back to a minimal PR if it didn't open one."""
    branch = config['epic_branch']
    default_branch = config.get('default_branch', 'main')
    owner, repo = _parse_owner_repo(config['epic_url'])

    existing = _find_open_pr_by_branch(owner, repo, branch)
    if existing:
        print(_c('green', f"  ✓ Epic PR already open: {existing['url']}"), flush=True)
        return existing['url']

    print(_c('bold', f"\n{'=' * 60}\nOpening the single PR for {branch} → {default_branch}"), flush=True)
    closes = '\n'.join(f"- Closes #{t['number']}: {t['title']}" for t in config['tasks'] if t['status'] == 'done')
    prompt = (
        PR_PROMPT_FILE.read_text(encoding='utf-8')
        .replace('{{EPIC_URL}}', config['epic_url'])
        .replace('{{BRANCH_NAME}}', branch)
        .replace('{{BASE_BRANCH}}', default_branch)
        .replace('{{CLOSES}}', closes)
    )
    run_claude(prompt, new_log_path('epic-pr'))

    existing = _find_open_pr_by_branch(owner, repo, branch)
    if existing:
        print(_c('green', f"  ✓ Epic PR opened: {existing['url']}"), flush=True)
        return existing['url']

    print(_c('yellow', "  Session did not open a PR — opening a minimal fallback one"), flush=True)
    result = subprocess.run(
        ['gh', 'pr', 'create', '--repo', f'{owner}/{repo}', '--base', default_branch, '--head', branch,
         '--title', f"Epic {config['epic_url'].rsplit('/', 1)[-1]}", '--body', closes],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(_c('red', f"  ✗ Fallback PR creation failed: {result.stderr.strip()}"), flush=True)
        return None
    print(_c('green', f"  ✓ Fallback PR created: {result.stdout.strip()}"), flush=True)
    return result.stdout.strip()


def main():
    if not TASKS_FILE.exists():
        print("tasks.json not found. Run plan_tasks.py first.")
        sys.exit(1)

    if not PROMPT_FILE.exists() or not PR_PROMPT_FILE.exists():
        print("prompt.md / pr-prompt.md not found.")
        sys.exit(1)

    write_pipeline_status('running')

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

    pending = [t for t in tasks if t['status'] == 'pending']
    print(f"Progress: {len(tasks) - len(pending)}/{len(tasks)} done, {len(pending)} pending")

    if pending:
        checkout_epic_branch(config)

    for task in pending:
        if not run_task(task, config):
            print(f"\nPipeline stopped. Fix task #{task['number']} and re-run.")
            write_pipeline_status('stopped', failed_task=task['number'])
            sys.exit(1)

    if any(t['status'] == 'done' for t in tasks):
        pr_url = ensure_epic_pr(config)
        if pr_url is None:
            print("\nAll tasks done but the epic PR could not be opened — open it manually.")
            write_pipeline_status('stopped', failed_task=None)
            sys.exit(1)
        config['epic_pr_url'] = pr_url
        save_tasks(config)

    print(f"\n{'=' * 60}")
    print(f"All {len(tasks)} tasks completed!")
    write_pipeline_status('completed')


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted.")
        write_pipeline_status('interrupted')
        sys.exit(130)
