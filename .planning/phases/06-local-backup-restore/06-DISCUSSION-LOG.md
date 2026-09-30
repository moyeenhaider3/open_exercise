# Phase 6: Local Backup & Restore - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-30
**Phase:** 6-Local Backup & Restore
**Areas discussed:** Backup folder choice, Auto-backup cadence, Manual backup (Settings), Restore flow

---

## Backup folder choice

| Option | Description | Selected |
|--------|-------------|----------|
| System folder picker | Android SAF tree + persisted permission; iOS folder picker + security-scoped bookmark | ✓ |
| Fixed app Documents folder | Like openGym, no real choice | |
| Picker with Documents default | Default to Documents, allow switching | |

| Option | Description | Selected |
|--------|-------------|----------|
| On first app launch | One-time prompt with Skip | |
| After the first workout | Ask when there is real data | ✓ |
| Only from Settings | Never prompt | |

| Option | Description | Selected |
|--------|-------------|----------|
| Warn and re-ask | Settings warning row + one-time snackbar | ✓ |
| Fall back silently | Write to Documents instead | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Folder + last backup time | Folder subtitle + "Last backup" | ✓ |
| Folder name only | | |

---

## Auto-backup cadence

| Option | Description | Selected |
|--------|-------------|----------|
| openGym triggers + app background | Finish workout, leave routine editor, app background if changed | ✓ |
| openGym triggers only | 1:1 with openGym | |
| Every data change (debounced) | Most file writes | |

| Option | Description | Selected |
|--------|-------------|----------|
| One per day, keep last 14 | Prune older files | |
| One per day, keep all | Exactly openGym | ✓ |
| Single rolling file | No history | |

| Option | Description | Selected |
|--------|-------------|----------|
| On once a folder is chosen | Choosing a folder enables it | ✓ |
| Off by default, like openGym | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse openGym's S.autoBackup | Folder URI device-local | ✓ |
| You decide | | |

---

## Manual backup (Settings)

| Option | Description | Selected |
|--------|-------------|----------|
| Both, as two rows | "Back up now" to folder + "Export backup (JSON)" share sheet | ✓ |
| Folder only | | |
| Share sheet only | | |

| Option | Description | Selected |
|--------|-------------|----------|
| openGym Data order + backup rows | Backup rows where openGym's auto-backup row is | ✓ |
| Separate 'Backup' section | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Snackbar + updated time | "Backup saved" / "Backup failed: …" | ✓ |
| You decide | | |

---

## Restore flow

| Option | Description | Selected |
|--------|-------------|----------|
| Any-file picker | System picker for any .json, like openGym | ✓ |
| List backups in folder + picker | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Exactly openGym | Validate, confirm, replaceState, no merge | ✓ |
| openGym + safety backup first | Pre-restore backup | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, on first launch | "Restore from a backup?" when no data | ✓ |
| No, Settings only | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the device's folder | Folder is device-local | ✓ |
| You decide | | |

---

## Dependencies

| Option | Description | Selected |
|--------|-------------|----------|
| Research picks, I approve | Plan lists new packages for approval | ✓ |
| Platform channel only | | |
| Pre-approve packages | | |

## Claude's Discretion

- Device-local settings store, Bloc layout, change detection for the background trigger, wording
  of new strings, and how the first-workout folder prompt is shown.

## Deferred Ideas

None.
