# General Engineering Rules

A generic starter `CLAUDE.md` — the rule set that `vreview`, `vcook`, and `vrules` read from and write to. Installed only with `--with-claude-md`, and only if you don't already have one (see `install.sh`). Edit this freely once installed; it is copied, not symlinked, so changes here are yours and won't be overwritten by future `vskills` updates.

## Principles

- **KISS / YAGNI / DRY** — the simplest solution that works is the right one, not the most "complete" one. Don't build for hypothetical future requirements.
- Root cause over symptom — a bug fix touches one place: where the broken logic actually lives, not every caller that happens to trip over it.
- Don't add abstractions, config, or flexibility for a single current usage. Extract only once something is genuinely reused.
- Delete dead code, commented-out code, and unused exports instead of leaving them "just in case".

## Code Review — Priority: security > bug > perf > style

- Root cause analysis — don't accept a fix that only patches the symptom.
- Clear names, one function one responsibility.
- No copy-paste, no dead code, no commented-out code, no forgotten TODOs, no empty try/catch, no hardcoded secrets.
- Auth checks must cover both authentication AND authorization (correct scope, not just "logged in").
- Tests should cover the happy path AND edge cases.
- Keep PRs small and focused — don't mix refactors with feature work in the same PR.

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
- Loading, error, and empty states for both queries and mutations.
- `key` must be a stable unique value — never array index for a list that can reorder.
- Clean up subscriptions/listeners/timers on unmount.
- Every interactive element needs an accessible label / alt text.
- Go through the shared API client layer — no bypassing it with raw `fetch`/`axios`.
- Scope cache invalidation to the specific query key affected — don't invalidate everything.
- `eslint-disable` needs a comment explaining why, never a bare disable.

## TypeScript

- No `any`, no `unknown` used as an escape hatch, no `@ts-ignore`/`@ts-expect-error`, no non-null assertion (`!`) to paper over a type error — fix the root type instead.
- Prefer letting TypeScript infer return types on functions/callbacks; only annotate when inference is wrong or needs narrowing.
- No floating promises — always `await` or `.catch()`.
- A domain type should live in exactly one place in the codebase, not be redefined per-file.

## File & Folder Structure

- Co-locate: a type/constant/util used in one file lives in that file, not in a separate `types.ts`/`constants.ts` just for it.
- Test files live next to the source file they test, unless the project already has a `__tests__/` convention.
- Before creating a new file: grep for existing logic/types/utils that already do this — don't duplicate.
- Flat over deeply nested — prefer `components/UserCard.tsx` over `components/user/card/index.tsx`.

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`.
- No AI-tool references in commit messages or PR descriptions.
- Keep commits focused on the actual code change — no unrelated formatting/refactor noise mixed in.
