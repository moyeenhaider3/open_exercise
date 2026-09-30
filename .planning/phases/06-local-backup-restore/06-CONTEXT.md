# Phase 6: Local Backup & Restore - Context

**Gathered:** 2026-09-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Keep the user's data safe on the device without any server. The app writes full-state JSON backups
into a device folder the user picks, both automatically and on demand from Settings. Importing a
backup file (on this device or a fresh install) restores all user data exactly, and the file
replaces everything already there. No user data ever leaves the device except through a share
sheet the user opens themselves.

Requirements: BAK-01, BAK-02, BAK-03, BAK-04, IMP-04 (IMP-04 is delivered by BAK-01..04).

Not in this phase: importing from other apps (FitNotes/Strong/Hevy/CSV/XML are IMP-01..03, Phase 8),
plan-file share/import (`planToolsSheet`), cloud/server sync (out of scope, see P5 D-01/D-02).

</domain>

<decisions>
## Implementation Decisions

### Carried forward (locked in earlier phases)
- Guest-only app, no user data sent online (P5 D-01, D-02). Phase 5 left room for this phase's
  Settings rows (P5 D-08).
- No tests of any kind (CLAUDE.md, enforced by a hook). Verify with `flutter analyze`, source/CLI
  checks and on-device checks.
- No domain math in Dart (JS-04). Backup/restore is plain serialization, so this is not affected.

### Backup folder
- **D-01:** The user picks the folder with the **system folder picker**. On Android that is the
  Storage Access Framework tree picker (`ACTION_OPEN_DOCUMENT_TREE`) with a persisted URI
  permission, so any folder works, including Drive/Syncthing/SD card folders. On iOS it is the
  folder document picker with a security-scoped bookmark. It is NOT a fixed app Documents folder.
- **D-02:** "First use" (BAK-01) = **right after the user's first finished workout**. The app
  prompts "Choose a backup folder" and the user can skip. If they skip, Settings keeps showing the
  unset folder row so they can choose later. The user is never asked on first launch before
  there is any data. The fresh-install restore offer in D-14 is separate.
- **D-03:** The folder can be changed any time from Settings → Data → **Backup folder** (tap to
  re-pick).
- **D-04:** If the folder disappears or loses permission (deleted, SD card removed, permission
  revoked, bookmark stale), a background auto-backup **fails quietly** (it never interrupts a
  workout). Settings then shows a warning row ("Backup folder unavailable, choose again") and a
  **one-time snackbar** appears on the next launch. There is no silent fallback to another folder.
- **D-05:** The Backup folder row shows the **folder name** as subtitle and **"Last backup: <date time>"**.

### Auto-backup cadence
- **D-06:** Triggers: openGym's `autoBackupNow()` moments, which are (a) after finishing a workout
  (`sheets.jsx` finishWorkout) and (b) after leaving the routine editor (`RoutineEdit.jsx` unmount).
  **Plus (c)** when the app goes to the background, if the state changed since the last backup,
  so check-ins, body weight and settings edits are covered too.
- **D-07:** File naming and retention follow openGym exactly: **`opengym-backup-YYYY-MM-DD.json`,
  one file per day**. Later backups on the same day overwrite that day's file, and **old files are
  never deleted**.
- **D-08:** The file content is the full state document, the same as openGym's `JSON.stringify(S)`,
  so openGym and this port can read each other's backup files.
- **D-09:** Auto-backup is **on once a folder is chosen**. Choosing a folder sets it on, and a
  switch in Settings can turn it off.
- **D-10:** The on/off setting reuses openGym's **`S.autoBackup`** field (already in `GymState` /
  `default_state.dart`). The folder URI/bookmark and the last-backup time are **device-local**.
  They are not in the state document or the backup file, because they mean nothing on another device.

### Manual backup (Settings)
- **D-11:** There are two rows. **"Back up now"** writes today's file to the chosen folder, or asks
  for a folder first if none is set. **"Export backup (JSON)"** opens the OS share sheet
  (openGym `doExport` / `shareExport`, file name `opengym-backup-YYYY-MM-DD.json`). The share sheet is
  something the user starts, so it keeps D-02 "no data sent online" intact.
- **D-12:** Settings → Data keeps openGym's order, with the backup rows where openGym's mobile-only
  "Auto-backup on changes" row is: Load starter plan → Import backup → Export backup (JSON) →
  Backup folder → Auto-backup switch → Back up now → Reset everything. The openGym rows for other-app
  imports (Import from another app / Import from Hevy) belong to Phase 8 and are not added here.
- **D-13:** After a manual backup, a **"Backup saved"** snackbar shows (openGym's `Backup exported`
  toast wording for Export) and the last-backup subtitle refreshes. A failure shows
  **"Backup failed: <reason>"**.

### Restore
- **D-15:** "Import backup" opens the **system file picker for any `.json` file** (the backup folder,
  Downloads, email attachments, another device's copy), the same as openGym.
- **D-16:** Import behaves **exactly like openGym `doImport`**: parse the JSON; if it has no
  `workouts` or no `routines`, fail with "Import failed: not an openGym backup". Otherwise ask
  "Import backup?" / "This replaces all current data with the backup file." (danger button
  "Import"), then `replaceState(DEF overlaid with the file)` and show the "Backup imported" toast.
  **Nothing is merged. The file is the master copy.** There is no safety backup before import.
- **D-14:** On a **fresh install with no data yet**, the first launch offers **"Restore from a
  backup?"** with **Pick file** / **Start fresh**. Pick file runs the same D-15/D-16 flow. This is
  the "like signing in again after a logout" moment.
- **D-17:** A restore **keeps this device's backup folder setting** (it is device-local, D-10). On a
  fresh install no folder is set, so the normal "after first workout" ask (D-02) applies.
- **D-18:** Success criterion 4: importing a backup on a fresh install restores the data
  **round-trip equivalent**. Exporting right after importing gives back the same document, apart
  from the fields openGym itself stamps (`_ts` and similar).

### Dependencies
- **D-19:** Native file access (folder picker with persisted permission / security-scoped
  bookmark, file picker, share sheet, writing into a SAF tree) is not covered by the mandated stack.
  **Research proposes** pub.dev packages or a small platform channel, and the plan lists every new
  package for the user to approve before it is installed (as in Phase 1). No test dev-dependencies.

### Claude's Discretion
- Where device-local backup settings live (a small sqflite table vs another local store). No
  `shared_preferences` is in the stack now. Prefer reusing sqflite/`AppDatabase`.
- Bloc layout for backup (a `backup` feature folder vs extending `SettingsBloc`), following the
  `bloc/ data/ view/` conventions.
- How the app-background trigger detects "changed since the last backup" (e.g. comparing `_ts` or a
  dirty flag on `GymStateCubit`).
- The exact wording of the new strings that have no openGym source ("Back up now", "Backup folder",
  "Backup folder unavailable, choose again", "Restore from a backup?"), keeping openGym's tone.
- How the "Choose a backup folder" prompt after the first workout is shown (a sheet after the finish
  summary vs a snackbar action), as long as it never blocks the finish summary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### openGym backup/restore source (behaviour to replicate)
- `../openGym/frontend/src/views/Settings.jsx` §122-145 (`doExport`, `doImport`), §385-400 (Data section rows and order)
- `../openGym/frontend/src/lib/mobile.js` §176-212 (`shareExport`, `writeAutoBackup`: dated file name, overwrite per day)
- `../openGym/frontend/src/store/useStore.js` §43 (`autoBackup` default), §340-348 (`replaceState`, `autoBackupNow`)
- `../openGym/frontend/src/sheets.jsx` §2224 (auto-backup after finishWorkout)
- `../openGym/frontend/src/views/RoutineEdit.jsx` §317 (auto-backup on leaving routine editor)

### Project scope and prior decisions
- `.planning/ROADMAP.md` §Phase 6 (goal, success criteria, scope change replacing SYNC-01..03)
- `.planning/REQUIREMENTS.md` (BAK-01..04, IMP-04, Out of Scope: AUTH/SYNC)
- `.planning/phases/05-timers-guest-mode/05-CONTEXT.md` (D-01/D-02 guest-only + no data online, D-08 Phase 6 hand-off)
- `CLAUDE.md` (stack, conventions, no-tests rule)
- `.claude/skills/port-from-opengym/SKILL.md` (porting workflow)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/state/gym_state_cubit.dart`: `replaceState(GymState)` mirrors `useStore.replaceState`
  (stamps `_ts`, persists), and `flush()` waits for pending saves. This is the import target and
  the source of state for a backup.
- `lib/core/data/gym_state_repository.dart`: `exportState(uid)` / `importState(uid, doc)` round-trip
  the raw document without the `kDefaultState` overlay (FND-04, tri-state `*_present` columns). This
  is the basis for D-08/D-18 round-trip equivalence.
- `lib/core/models/gym_state.dart` + `default_state.dart`: `autoBackup` field already modelled (default false).
- `lib/features/settings/view/sections/data_section.dart`: the existing Data section (Load starter
  plan, Reset everything with confirm dialog). The new rows go here.
- `lib/features/settings/bloc/settings_bloc.dart`: already calls `_gymState.replaceState` for
  reset/unit conversion, so it is the pattern for the import flow.

### Established Patterns
- `AppLifecycleListener` used in `lib/core/wakelock/wakelock_sync.dart` and
  `lib/core/notifications/reminder_sync.dart`. Reuse it for the D-06(c) app-background trigger.
- Workout finish in `lib/features/workout/bloc/workout_bloc.dart` `_onFinishConfirmed` is the hook
  point for D-06(a) and the D-02 first-workout folder prompt.
- Sealed Equatable Bloc states/events, one sequential `on<Event>`, repository injected by
  constructor, wired in `lib/app/app.dart` / `lib/app/dependencies.dart`.

### Integration Points
- `lib/app/dependencies.dart` / `app.dart`: register a backup service/repository.
- The routine editor exit (Plan/RoutineEdit feature) is the D-06(b) trigger.
- App start (`lib/main.dart` / shell) is where the D-14 fresh-install restore offer and the D-04
  one-time "folder unavailable" snackbar go.
- `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`: may need file-provider or
  document-picker entries depending on the packages chosen (D-19).

</code_context>

<specifics>
## Specific Ideas

- The backup file must be interchangeable with openGym's (same name pattern, same full-state JSON),
  so a user can move between openGym and this port.
- "The backup is the master copy, like signing in again after a logout": restore replaces everything
  and never merges.

</specifics>

<deferred>
## Deferred Ideas

None. Discussion stayed within phase scope. (Other-app imports and Hevy import are already on the
roadmap as IMP-01..03 in Phase 8.)

</deferred>

---

*Phase: 06-local-backup-restore*
*Context gathered: 2026-09-30*
