# Implement under ub-mode

Implement the approved decomposition with the inherited artifact root, context
path, drain policy, implementation target, iteration limit, push flag, and open
PR flag. Store the implementation summary path and outcome on the workflow root
bead.

Load the `ub-mode` skill first (`/ub-mode`). Every unit you implement follows it.

## Per unit

1. **TDD.** Write the failing test before the code. See it fail for the reason you
   expect. Make the smallest change that makes it pass. If an honest test is
   impractical, do not write a bad one.
2. **Sequence into verifiable units.** Finish one small unit and check it before
   starting the next.
3. **Subtract before you add.** Take complexity out before adding anything.
4. **Fix root causes.** If something breaks, reproduce it, fix the cause, and
   refuse a guard that only hides the crash.

## Quality gates

Run these from the project root after each unit where they apply. They are
Python tools installed under `~/.gc/cache` by the pack's doctor checks.

- `~/.gc/cache/bin/crapper` — keep every function under CRAP 10, by splitting it,
  by testing it, or both. Consider whether long case statements are worth reducing.
- `~/.gc/cache/bin/dryer` — eliminate duplication at 0.8 or above.
- `~/.gc/cache/bin/mutator` — cover the uncovered, kill the survivors, delete dead
  code. Start with the file you are working on.

If a tool is missing or cannot run, say so in the log and continue. Do not block
the build on it, and do not claim a gate passed when it did not run.
Results land in `.metrics/`; do not commit that directory.

## Practice

- **Keep a log.** Record every action and why, and report the log when the unit
  closes.
- **Guard the context window.** Keep the main thread small; send bulk work
  elsewhere and keep the summary.
- **Commit and push.** Small ordered commits; each says why, what changed, and how
  you proved it.
- **Worktree cleanup.** Reclaim disk only after confirming nothing in use needs it.
  Leave uncommitted work for a decision.

Close this step only after implementation reports a clean result or an explicit
failure artifact.
