# Align the before-title status column

## Task

Give generic before-title status content a stable column width so compact Org
workflow values do not shift Codex titles horizontally.

## Approach

- Compute before-title values once per render alongside existing status and
  timestamp layout widths.
- Reserve a configurable minimum width only when visible rows contain such
  content, expanding rather than truncating longer values.
- Add an ERT assertion that differently sized values produce the same title
  column.

## Result

- Values such as `WIP`, `DONE`, and `UNLINKED` now form one aligned column.
- Integrations remain generic and no Org-specific layout enters the base
  package.

## Relevant files

- [Status mode](../../../codex-ide-status-mode.el)
- [Status mode tests](../../../tests/codex-ide-status-mode-tests.el)
- [User documentation](../../../README.md)
