# Phase 6: Local Backup & Restore — Research

**Date:** 2026-10-07
**Phase:** 06-local-backup-restore
**Status:** Complete

## Package Legitimacy Audit

### New Runtime Dependencies

| Package | Version | Publisher | Likes | Purpose | Status |
|---------|---------|-----------|-------|---------|--------|
| `file_picker` | ^12.0.0 | miguelpruivo.com | 4.5k+ | Folder picker (SAF tree + iOS folder picker), file picker for import | [ASSUMED] |
| `share_plus` | ^11.0.0 | flutter.dev (Flutter Community+) | 3.5k+ | OS share sheet for export backup (D-11) | [ASSUMED] |
| `path_provider` | ^2.1.0 | flutter.dev | 3k+ | Cache dir for share temp file | Already in pubspec (transitive via sqflite) — verify |

**Note:** `file_picker` 12.0.0+ supports `AndroidSAFOptions` / `AndroidSAFHandle` for persistent
URI grants across reboots. On iOS, security-scoped bookmarks require a small native Method Channel
(~30 lines Swift) because `file_picker` does not expose bookmark creation/resolution directly.

### Packages NOT Needed

| Package | Reason |
|---------|--------|
| `shared_preferences` | D-19 says prefer sqflite. Device-local backup settings go in a small `backup_settings` table |
| `saf` / `saf_util` | `file_picker` 12+ covers SAF persistence natively |
| `directory_bookmarks` | Too niche; a small Method Channel is cleaner for iOS bookmarks |

## Platform-Specific Notes

### Android (SAF)

- `file_picker.getDirectoryPath()` with `AndroidSAFOptions` returns a SAF content URI
- Call `takePersistableUriPermission` (handled by file_picker 12+ internally)
- Writing files: use `DocumentFile.createFile` via SAF — file_picker provides `AndroidSAFHandle`
  for read/write operations on the persisted tree
- No `WRITE_EXTERNAL_STORAGE` or `READ_EXTERNAL_STORAGE` needed (SAF grants are scoped)
- File name pattern: `opengym-backup-YYYY-MM-DD.json` — overwrite same-day file

### iOS (Security-Scoped Bookmarks)

- `file_picker.getDirectoryPath()` opens `UIDocumentPickerViewController` for folders
- The returned path is a security-scoped URL — temporary until bookmarked
- Method Channel needed:
  - `createBookmark(path)` → Base64 bookmark data string
  - `resolveBookmark(data)` → resolved path + `startAccessingSecurityScopedResource()`
  - `stopAccessing()` → `stopAccessingSecurityScopedResource()`
- Store bookmark Base64 string in the `backup_settings` sqflite table
- Handle stale bookmarks: if `bookmarkDataIsStale`, show "Backup folder unavailable" (D-04)

### Share Sheet (Export)

- `share_plus` `SharePlus.instance.share(ShareParams(files: [XFile(...)]))` 
- Write JSON to cache dir first, share the temp file
- iPad: must provide `sharePositionOrigin` to prevent crash

## Existing Code Integration Points

### State Serialization (D-08, D-18)

- `GymStateRepository.exportState(uid)` returns the raw `Map<String, Object?>` document
- `JSON.encode(doc)` with 2-space indent = the backup file content
- Must match openGym's `JSON.stringify(S, null, 2)` output

### Import / replaceState (D-16)

- Parse JSON, validate `workouts` and `routines` keys exist
- Overlay on `kDefaultState`: `GymState.fromJson(Map.from(kDefaultState)..addAll(parsed))`
- Call `GymStateCubit.replaceState(newState)` — already stamps `_ts` and persists

### Auto-Backup Triggers (D-06)

1. **Workout finish** — `workout_bloc.dart:_onFinishConfirmed` (line 438). Already has a
   `// Note: autoBackupNow is deferred to Phase 8.` comment (actually Phase 6)
2. **Routine editor exit** — `RoutineEdit` widget dispose / pop. Port openGym's
   `useEffect(() => () => autoBackupNow(), [])` unmount cleanup
3. **App background** — `AppLifecycleListener.onInactive` in `app.dart` (line 73). Check
   dirty flag on `GymStateCubit` (compare `_ts` or a monotonic counter vs last-backup-ts)

### Device-Local Settings (D-10, D-19)

- New `backup_settings` table in `AppDatabase`:
  - `folder_uri TEXT` (Android SAF URI string)
  - `folder_bookmark TEXT` (iOS Base64 bookmark)
  - `folder_name TEXT` (display name for Settings row)
  - `last_backup_at INTEGER` (epoch ms)
  - `auto_backup_enabled INTEGER DEFAULT 1` (on once folder chosen, D-09)
- Single row, upsert on change

### UI Integration (D-12)

- `data_section.dart` currently has: Load starter plan → Reset everything
- Phase 6 inserts between them: Import backup → Export backup (JSON) → Backup folder →
  Auto-backup switch → Back up now
- Then Reset everything stays last

---

*Research complete. Ready for planning.*
