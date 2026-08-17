# Diagnose archived thread deletion

## Task

Investigate why deleting a thread with `D` from an archived project status
view reports that no stored Codex thread can be found.

## Approach

- Traced the `D` binding from the status mode through the thread deletion
  command.
- Compared the deletion lookup path with the actual storage location of the
  reported archived thread.
- Reviewed the existing deletion and archive-related tests.

## Result

- `D` is available in both active and archived status views.
- The deletion implementation searches only the active `sessions/` tree below
  `CODEX_HOME`.
- The reported thread is stored below `archived_sessions/`, so the lookup
  incorrectly reports it as missing.
- This is an implementation bug rather than an intended restriction of the
  archived status view. No code change was made during this diagnostic task.

## Relevant files

- [`codex-ide-status-mode.el`](../../../codex-ide-status-mode.el)
- [`codex-ide-delete-session-thread.el`](../../../codex-ide-delete-session-thread.el)
