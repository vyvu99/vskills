# General Engineering Rules

A generic starter `CLAUDE.md` — the rule set that `vreview`, `vcook`, and `vrules` read from and write to. Installed only with `--with-claude-md`, and only if you don't already have one (see `install.sh`). Edit this freely once installed; it is copied, not symlinked, so changes here are yours and won't be overwritten by future `vskills` updates.

## Principles

- **KISS / YAGNI / DRY** — the simplest solution that works is the right one, not the most "complete" one. Don't build for hypothetical future requirements.
- Root cause over symptom — a bug fix touches one place: where the broken logic actually lives, not every caller that happens to trip over it.
- Don't add abstractions, config, or flexibility for a single current usage. Extract only once something is genuinely reused (2+ usages).
- Don't refactor unrelated code just to land a small bug fix — fix the bug, clean up only what the fix itself touched.
- Delete dead code, commented-out code, and unused exports instead of leaving them "just in case". No backward-compat shims unless the user explicitly asked for one.
- Comments must explain **WHY**, never **WHAT** — the code already says what it does; a comment earns its place only by capturing a non-obvious reason.
- A comment/docstring that says A while the code does B must be fixed immediately — a wrong comment is worse than no comment.
- Self-check before finishing: would a senior engineer call this overcomplicated? If yes, simplify before moving on.

## Hard Gates — Stop and Ask

Before doing any of the following, stop and ask the user instead of deciding alone:

- About to run a dev/local server command.
- About to edit an auto-generated file — edit the source/schema and regenerate instead.
- About to add a new dependency — check whether the codebase already has something that does this first.
- About to introduce a new abstraction (class/function/util/config) — check existing code for something that already fits.
- About to write raw SQL — list ORM/query-builder alternatives first; raw SQL only once the user confirms there's no other way.
- You noticed a real trade-off — present the options, don't pick one silently.
- The task has 2+ reasonable interpretations — list them, don't guess which one was meant.

## Commands & Safety

- Never run database migrations against a real database on your own, in any mode (including autonomous/unattended) — always require explicit user action for that step.
- Always run code-generation steps (schema → types, OpenAPI → client, etc.) right after a change to the thing they're generated from — don't leave the generated output stale.
- Always run the project's formatter/linter before declaring a task done.
- Destructive git operations (`reset --hard`, `push --force`, `branch -D`, `checkout .`) always require confirmation first.

## Code Review — Priority: security > bug > perf > style

- Root cause analysis — don't accept a fix that only patches the symptom.
- Clear names, one function one responsibility.
- No copy-paste, no dead code, no commented-out code, no forgotten TODOs, no empty try/catch, no hardcoded secrets.
- Auth checks must cover both authentication AND authorization (correct scope, not just "logged in").
- An endpoint or query that accepts a resource ID must verify the resource actually belongs to the requesting user/tenant — confirming the ID exists is not enough (this is how cross-tenant IDOR bugs happen).
- Tests should cover the happy path AND edge cases.
- Keep PRs small and focused — don't mix refactors with feature work in the same PR. Before opening a PR, review your own diff and split out unrelated changes into a separate commit/PR.
- A PR's description must match what the code actually does — if they diverge, fix the description or fix the code, don't leave the mismatch.

## Backend

- No N+1 queries — batch instead of querying inside a loop; sequential queries outside a loop are fine.
- Two independent DB queries with no dependency between them → `Promise.all([q1, q2])`, not sequential awaits.
- Parameterized SQL for all user input — never string-concatenate a query.
- Use the correct HTTP status code via an error classifier — don't hardcode status numbers.
- Consistent error response shape across the whole API.
- Wrap multi-write operations in a transaction.
- Never expose a stack trace, internal ID, or other sensitive detail when the client only needs a boolean/derived value.
- Paginate and rate-limit list endpoints.
- If an entity has a soft-delete column, every query touching it must filter it out.
- Error handling by layer:
  - **Repository** — don't throw; return `null`/`undefined`, let DB errors bubble up naturally.
  - **Service** — throw a typed application error (e.g. `NotFoundError`, `ForbiddenError`, `ConflictError`, `ValidationError`); a global handler formats the response.
  - **Route/controller** — no try/catch needed; call the service, return the response, let the global error handler handle exceptions.
- Log errors with the actual `Error` object, not wrapped in a plain object (wrapping loses the stack trace).

## Frontend

- No leftover `console.log` in committed code.
- No hardcoded color/spacing/text — pull from the project's design tokens/theme.
- Loading, error, and empty states for both queries and mutations. A button that triggers a mutation needs a visible loading indicator (spinner or text change), not just `disabled`.
- `key` must be a stable unique value — never array index for a list that can reorder.
- Clean up subscriptions/listeners/timers on unmount.
- Alt text + accessible label for every interactive element.
- Go through the shared API client layer — no bypassing it with raw `fetch`/`axios`. A stateless HTTP client should be created once at module level, not re-created inside a function/component/handler body.
- Scope cache invalidation to the specific query key affected — don't invalidate everything.
- A `useEffect` that reads a variable not in its dependency array is a bug (stale closure) — add it to the deps or move the variable out of the effect.
- `eslint-disable` needs a comment explaining why, never a bare disable.

## TypeScript

- No `any`, no `unknown` used as an escape hatch, no `@ts-ignore`/`@ts-expect-error`, no non-null assertion (`!`) to paper over a type error — fix the root type instead.
- No `as` casting to force a type — the one exception is a true external 3rd-party boundary that doesn't expose a typed output, and even then it needs a comment explaining why.
- Prefer letting TypeScript infer return types on functions/callbacks; only annotate when inference is wrong or needs narrowing.
- No floating promises — always `await` or `.catch()`.
- A domain type should live in exactly one place in the codebase, not be redefined per-file.

## Styling & UX

- Use the project's design tokens/theme for color, spacing, and typography — never a raw hex/rgb value or a magic number.
- Use one consistent icon library/set across the project — not a mix of inline SVGs, emoji, and ASCII characters as icons.
- Minimize clicks, maximize automation — prefer bulk/multi-select actions and "copy all" over one-at-a-time when it's cheap to offer.
- Any UI action that creates or modifies data needs a clear place to see the result — never ship a "create" button with no way to view what got created.

## Convention

- Commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`. No AI-tool references in commit messages or PR descriptions. Keep commits focused on the actual code change — no unrelated formatting/refactor noise mixed in.
- Branch names describe the actual goal of the work — no tool/agent-name prefixes unless the repo's own convention requires one.
- File naming: components in PascalCase, everything else kebab-case (adjust to match whatever the project already does).
- Don't add a dependency the codebase already has an equivalent for; remove dependencies that are no longer used.
- Export style (default vs. named) must be consistent across the project.
- Access environment variables through one centralized config module, validated at startup — not `process.env.X` scattered across the codebase.

## File & Folder Structure

- Co-locate: a type/constant/util used in one file lives in that file, not in a separate `types.ts`/`constants.ts` just for it.
- Test files live next to the source file they test, unless the project already has a `__tests__/` convention.
- Before creating a new file: grep for existing logic/types/utils that already do this — don't duplicate. Check whether it belongs in an existing file (same concern, same layer) before creating a new one.
- Flat over deeply nested — prefer `components/UserCard.tsx` over `components/user/card/index.tsx`.
