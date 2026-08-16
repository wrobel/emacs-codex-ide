# Add status title slots and thread archive management

## Task

Extend the package-neutral Codex status API with symmetric before-title and
after-title providers, and add project/global archived-thread management that
is useful without an Org integration.

## Approach

- Verified the current Codex app-server archive, unarchive, and archived-list
  request contracts against the official OpenAI documentation.
- Extended protocol, normalized row, status rendering, command, and transient
  layers while preserving the legacy after-title annotation hook.
- Added focused ERT coverage for protocol parameters, public operations,
  rendering order, archived inventory views, and the archive toggle.

## Result

- Status integrations can independently render content before or after titles.
- Active and archived inventories remain separate and can be opened per project
  or globally.
- `A` archives in active status views and unarchives in archived status views.
- Archive state is exposed through the public normalized-row API and does not
  imply a project-management workflow state.

## Relevant files

- [Status extension API](../../../codex-ide-status-api.el)
- [Status mode](../../../codex-ide-status-mode.el)
- [Protocol helpers](../../../codex-ide-protocol.el)
- [User documentation](../../../README.md)
