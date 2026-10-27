# Resume mode: implementing logged decisions

Use when the user returns with terse answers to the pending items a sweep logged. The steps are written for code. For other kinds of work keep the intent (a fresh read of the current state, the same pattern as sibling items, a check that fails before and passes after, a real verification, a final whole-set re-check) and swap the tooling. Scope is the logged items the user answered, nothing else.

1. Match each answer to its logged item by content, not assumed order. Ask once if a mapping is truly ambiguous.
2. Per item, read the current code fresh; the earlier write-up may be stale. Reuse the existing pattern for the same class of problem. If the straightforward mechanism does not apply (for example a field is encrypted and cannot be a database-level filter), use the minimal variant and leave a comment explaining the trade-off.
3. Extend the existing test file or helper for that area (parametrize it, do not add a parallel one) with the regression case and a case that would have failed before the change.
4. Verify end to end (the real app, a build, a preview, whatever proves it) in both directions before the next item.
5. If verification wrote rows into a shared or dev dataset, rerun the full suite, because a same-environment test can assert exact live counts. If that broke it, delete only the exact rows this run created, never anything older, and reconfirm green.
6. Trace each new error path to the message the user actually sees, through the real response layer, since the human string is often not what the backend returns verbatim. Replace a generic catch-all with one specific to the new case, consistent with sibling cases, and watch for a duplicate toast when a callback and a separate manual check can both fire for the same error.
7. When every item is done, run lint and format plus the full regression suite across everything touched before reporting done. If any gate cannot run, say so.
