# Implement in one shared session under ub-mode

Drain the approved decomposition in one shared worktree with the inherited
artifact root, context path, implementation target, iteration limit, push flag,
and open PR flag. Store the implementation summary path and outcome on the
workflow root bead.

Load the `ub-mode` skill first (`/ub-mode`). Every work item follows it. Because
all items share one session:

- Finish one item completely, including its quality gates, before touching the
  next. Shared state is exercised by sequential work; two items editing the same
  mutable thing at once is the failure this mode exists to prevent.
- Keep per-item notes in the log so a skipped or failed item (`skip_remaining` is
  on) is visible downstream.
- Do not carry half-finished refactors across items.

## Per item

1. **TDD.** Failing test first, smallest change to pass.
2. **Sequence into verifiable units.** Check each unit before the next.
3. **Subtract before you add.**
4. **Fix root causes**, never hide the crash.

## Quality gates

Run from the project root after each item where they apply:

- `~/.gc/cache/bin/crapper` — functions under CRAP 10.
- `~/.gc/cache/bin/dryer` — no duplication at 0.8 or above.
- `~/.gc/cache/bin/mutator` — cover the uncovered, kill survivors, delete dead code.

If a tool is missing, say so and continue; never claim a gate passed when it did
not run. `.metrics/` output is not committed.

## Practice

- Keep a log of actions and reasons; report it when the item closes.
- Small ordered commits, each saying why, what changed, and how you proved it.
- Reclaim worktree disk only after confirming nothing in use needs it.

Close this step only after implementation reports a clean result or an explicit
failure artifact.
