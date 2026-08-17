# Enable archived thread deletion

## Task

Make the `D` command permanently delete archived threads as well as active
threads, and audit the other archived-status shortcuts for comparable active
inventory assumptions.

## Approach

- Extended persisted-thread lookup to both `sessions/` and
  `archived_sessions/` below the active `CODEX_HOME`.
- Kept deletion constrained to those two storage roots and retained the full
  interactive confirmation for active and archived threads.
- Added focused tests for active lookup, archived lookup, archived deletion,
  and rejection of paths outside Codex session storage.
- Reviewed every status-mode shortcut in the archived view.

## Result

- `D` now supports individual and region-based deletion from active and
  archived status views.
- `A`, `l`, extension action `a`, and navigation already handle archived rows
  correctly.
- `RET` and its other-window variants intentionally require unarchiving first;
  `K` remains limited to live buffers. No additional repairs were needed.
- The direct filesystem deletion remains isolated and guarded because Codex
  does not expose the operation through the app-server API used here.
- The focused deletion/status suites passed 56 of 56 tests and the complete
  suite passed 735 of 735 tests under Emacs 30.2.
- Automated live reload could not reach an Emacs server socket. Its fallback
  default-profile start failed on unrelated local package and socket setup, so
  the running agents profile must load the verified change through `C-x R`.

## Relevant files

- [`codex-ide-delete-session-thread.el`](../../../codex-ide-delete-session-thread.el)
- [`tests/codex-ide-delete-session-thread-tests.el`](../../../tests/codex-ide-delete-session-thread-tests.el)
- [`README.md`](../../../README.md)
