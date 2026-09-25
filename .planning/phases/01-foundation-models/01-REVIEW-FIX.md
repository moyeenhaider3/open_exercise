---
phase: 01-foundation-models
fixed_at: 2026-09-25T10:32:55Z
review_path: .planning/phases/01-foundation-models/01-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 11
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-25T10:32:55Z
**Source review:** .planning/phases/01-foundation-models/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (3 critical, 8 warning; Info findings out of scope)
- Fixed: 11
- Skipped: 0

Verification: `flutter analyze` reported "No issues found!" after every fix. No test files were created (NO-TESTS rule). The CR-02 and WR-03 behaviour was also checked with throwaway scripts in the session scratchpad, outside the repo and uncommitted.

## Fixed Issues

### CR-01: A failed load makes ShellBloc overwrite the whole profile with defaults (data loss)

**Files modified:** `lib/features/shell/bloc/shell_bloc.dart`
**Commit:** 5460a13 (superseded structurally by b10ed3a)
**Applied fix:** `_loadOrDefaults` is removed. "No stored state" (`null`) still starts from `GymState.defaults()`. A load that throws is now reported with `addError`, and the change is only emitted to the UI on top of the settings currently shown; nothing is saved. After CR-03 the shell no longer calls `saveState` at all. It uses `patchSettings`, which never touches the array tables and throws without writing if `doc_json` can't be read.
**Status:** fixed: requires human verification (state-handling logic)

### CR-02: `SetEntry.resolvedPhase` does not match openGym `phaseForSet`

**Files modified:** `lib/core/models/set_entry.dart`
**Commit:** 8f0c33c
**Applied fix:** Exact port of `normalizedPhase` and `phaseForSet(set, fallback)`. The new `resolvedPhaseOr([fallback])` reads raw `phase`/`warmup`, including wrong-typed values that were demoted to `extra`. `resolvedPhase` keeps the default `'work'` fallback. Checked with the real `workout-model.js` under node on 10 edge cases (`Warm-up`, `' warmup '`, `WARM_UP`, `cooldown`+warmup, numeric phase, empty phase, null phase, a non-bool warmup, `{}`, `work`+warmup) with both fallbacks: the Dart and JS outputs were identical.

### CR-03: ShellBloc handlers run concurrently and do whole-document read-modify-write

**Files modified:** `lib/features/shell/bloc/shell_bloc.dart`, `lib/core/data/gym_state_repository.dart`
**Commit:** b10ed3a
**Applied fix:**
- **One sequential handler:** every `ShellEvent` now goes through a single `on<ShellEvent>` handler with a local sequential transformer (`events.asyncExpand(mapper)`), so events run one at a time, in order. No `bloc_concurrency` dependency was added.
- **New `GymStateRepository.patchSettings(uid, {theme, accent})`:** reads and updates only `theme`/`accent` in `user_state.doc_json`, in one sqflite transaction, and never rewrites the workouts, routines or body-weight tables. If there is no stored state, it imports a defaults document inside the same transaction.
- **Refactor:** `importState`'s body was moved into `_importInTxn` so it can run inside that transaction.
**Status:** fixed: requires human verification (concurrency logic)

### WR-01: Unknown or missing theme falls back to dark, but openGym follows the system setting

**Files modified:** `lib/features/shell/data/theme_settings.dart`, `lib/features/shell/bloc/shell_bloc.dart` (doc comment only)
**Commit:** 26542a9
**Applied fix:** `_themeModeFromOpenGym(String?)` now maps `'light'` to light, `'dark'` to dark, and anything else (including null) to `ThemeMode.system`, matching `App.jsx` `resolveTheme`. `fromState(null)` still returns dark/lime (DEF). Doc comments are corrected.

### WR-02: User-initiated saves never stamp `_ts`

**Files modified:** `lib/core/data/gym_state_repository.dart`
**Commit:** 5f5d0f8
**Applied fix:** `patchSettings` stamps `_ts` with the current time in both `doc_json` and the `ts` column, mirroring `persist(S, push, stamp = true)`. `importState` still never stamps.

### WR-03: `copyWith` cannot clear nullable fields

**Files modified:** `lib/core/models/gym_state.dart`, `lib/core/models/workout.dart`, `lib/core/data/gym_state_repository.dart`, `lib/features/shell/bloc/shell_bloc.dart`
**Commit:** 4d15439
**Applied fix:** `copyWith` on `GymState` and `Workout` now uses a private sentinel:
- An omitted field is kept as it is.
- An explicit `null` clears the typed field and records `key: null` in `extra`, so `toJson` emits an explicit null (for example `active: null`).
- A non-null value sets the typed field and removes any stale `extra` entry for that key.

The two call sites that passed a possibly-null theme/accent now pass only the fields being changed. Checked with a scratch script: clearing `active`, replacing a demoted `theme`, chained copies, clearing `Workout.end`, and equality when no fields are passed.
**Status:** fixed: requires human verification. The parameters are now `Object?`, so type errors surface at runtime as casts instead of at compile time.

### WR-04: `exportState` reads without a transaction (torn document)

**Files modified:** `lib/core/data/gym_state_repository.dart`
**Commit:** 1976828
**Applied fix:** `exportState` now runs all its reads inside `_db.transaction`, and `_rebuildList` takes the `Transaction`.

### WR-05: `fetchState` and `pushState` treat unexpected responses as success

**Files modified:** `lib/core/api/open_gym_api_client.dart`
**Commit:** 0f4205e
**Applied fix:**
- **New `UnexpectedResponseException`:** thrown when the body is not a Map, when `state` is missing or neither null nor a Map, or when `rev` is present but not a number.
- **Deliberate deviation from the review:** a missing `rev` does not throw. `useStore.js` explicitly supports servers from before revisions, which send no `rev` (it drops its stored revision). So `FetchStateResult.rev` is now `int?`, and `pushState` returns `Future<int?>`, with null meaning "no revision". Previously this case was reported as rev 0 or `baseRev`.
- There are no callers yet, so nothing else needed to change.
**Status:** fixed: requires human verification (the API contract changed to nullable `rev`)

### WR-06: `ApiClientFactory.create` ignores `baseUrl` when `dio` is supplied

**Files modified:** `lib/core/api/open_gym_api_client.dart`
**Commit:** 402191b
**Applied fix:** `resolvedDio.options.baseUrl = baseUrl` is always applied, and the doc comment is updated.

### WR-07: A startup database failure crashes the app, and save errors escape the Bloc

**Files modified:** `lib/main.dart`
**Commit:** 0ba6427
**Applied fix:** The database open is wrapped in try/catch. On failure the error goes to `FlutterError.reportError` and a minimal `_StartupErrorApp` is shown, with a "Try again" button that re-runs `main`. The Bloc half was already fixed by CR-03: `_persistChange` catches errors, calls `addError`, and emits the UI-only change.

### WR-08: The "byte-for-byte" round-trip claim is false

**Files modified:** `lib/core/models/json_passthrough.dart`, `lib/core/models/default_state.dart`, `lib/core/data/gym_state_repository.dart`
**Commit:** 2aff7aa
**Applied fix:** Doc comments now say the round-trip is deep-equal only: key order and number formatting are not preserved. They also warn against comparing serialized strings.

---

_Fixed: 2026-09-25T10:32:55Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
