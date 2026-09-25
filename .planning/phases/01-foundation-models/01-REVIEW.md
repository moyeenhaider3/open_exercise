---
phase: 01-foundation-models
reviewed: 2026-09-25T10:10:41Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - analysis_options.yaml
  - pubspec.yaml
  - openapi_generator.yaml
  - tool/gen_api.sh
  - tool/fixtures/gen_state_fixture.mjs
  - lib/main.dart
  - lib/app/app.dart
  - lib/app/dependencies.dart
  - lib/core/api/open_gym_api_client.dart
  - lib/core/data/gym_state_repository.dart
  - lib/core/db/app_database.dart
  - lib/core/db/schema.dart
  - lib/core/models/bodyweight_entry.dart
  - lib/core/models/default_state.dart
  - lib/core/models/gym_state.dart
  - lib/core/models/json_passthrough.dart
  - lib/core/models/routine.dart
  - lib/core/models/set_entry.dart
  - lib/core/models/state_parts.dart
  - lib/core/models/workout.dart
  - lib/core/router/app_router.dart
  - lib/core/theme/accents.dart
  - lib/core/theme/app_theme.dart
  - lib/features/shell/bloc/shell_bloc.dart
  - lib/features/shell/bloc/shell_event.dart
  - lib/features/shell/bloc/shell_state.dart
  - lib/features/shell/data/theme_settings.dart
  - lib/features/shell/view/shell_page.dart
findings:
  critical: 3
  warning: 8
  info: 5
  total: 16
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-25T10:10:41Z
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

I reviewed the Phase 1 foundation: the passthrough JSON models, the `kDefaultState` overlay, the sqflite hybrid schema and repository, the Dio wrapper, and the themed shell with `ShellBloc`. I checked the ported behaviour against the openGym sources in `../openGym/frontend/src/`.

The passthrough core in `json_passthrough.dart` and the models built on it holds up. Tracing every reader type (`string`, `integer`, `number`, `boolean`, `map`, `list`, `stringList`, `objectList`) and `emit` showed that unknown keys, explicit nulls and wrong-typed values all survive into `extra`. `kDefaultState` matches `useStore.js` `DEF` and `WC_DEFAULT` key for key, and `kAccents` matches `format.js` `ACCENTS`.

The problems are elsewhere:
- **Data loss:** `ShellBloc` can overwrite the whole stored profile with defaults when a read fails (CR-01).
- **Lost updates:** `ShellBloc` does whole-document read-modify-write while handling events concurrently (CR-03).
- **Wrong port:** `SetEntry.resolvedPhase` does not match `phaseForSet` in openGym (CR-02).
- **Other divergences:** unknown-theme fallback (WR-01) and missing `_ts` stamping on user changes (WR-02).

## Critical Issues

### CR-01: A failed load makes ShellBloc overwrite the whole profile with defaults (data loss)

**File:** `lib/features/shell/bloc/shell_bloc.dart:38-61`
**Issue:** `_loadOrDefaults()` catches every exception from `loadState` and returns `GymState.defaults()`. `_onThemeChanged` and `_onAccentChanged` then call `_repository.saveState(uid, next)` with that result. `saveState` calls `importState`, which **deletes every row** for the uid in `user_state`, `workouts`, `routines` and `bodyweight`, then writes the defaults document.

Any read failure therefore wipes the user's entire workout history, routines and body-weight log the next time they change theme or accent. Examples of read failures:
- a transient `DatabaseException`
- a corrupt `doc_json` row that throws in `jsonDecode`
- a `raw_json` row that throws in `_rebuildList`
- a `TypeError` from the `as String` or `as Map` casts in `exportState`

The "boot with defaults" fallback (T-1-12) is fine for *rendering*. It must never be written back.
**Fix:** Separate "no state" from "load failed", and never persist after a failed load:
```dart
Future<void> _onThemeChanged(ShellThemeChanged event, Emitter<ShellState> emit) async {
  final GymState? stored;
  try {
    stored = await _repository.loadState(uid);
  } catch (e, st) {
    addError(e, st);
    // Show the choice in the UI, but do NOT persist over a profile we could not read.
    emit(ShellReady(settings: ThemeSettings.fromState(GymState.defaults().copyWith(theme: event.theme))));
    return;
  }
  final GymState next = (stored ?? GymState.defaults()).copyWith(theme: event.theme);
  await _repository.saveState(uid, next);
  emit(ShellReady(settings: ThemeSettings.fromState(next)));
}
```
A better long-term fix is a targeted repository method that patches only the `theme`/`accent` keys inside `doc_json` in one transaction, without rewriting the array tables.

### CR-02: `SetEntry.resolvedPhase` does not match openGym `phaseForSet`

**File:** `lib/core/models/set_entry.dart:153-160`
**Issue:** The getter says it "Mirrors `workout-model.js` `phaseForSet`", but it does not. The openGym code (`../openGym/frontend/src/lib/workout-model.js:7-19`):
```js
if (source.phase != null && source.phase !== '') return normalizedPhase(source.phase, fallback)
return source.warmup === true ? 'warmup' : normalizedPhase(undefined, fallback)
```
`normalizedPhase` trims and lower-cases the value, accepts `warmup`, `warm-up` and `warm_up`, and maps anything else to `work`. The port differs in three ways:
1. `phase: 'Warm-up'`, `'WARMUP'`, `' warmup '` and `'warm_up'` give `warmup` in openGym but fall through to the `warmup` boolean in the port, which usually gives `work`.
2. An explicit but unrecognised phase (`phase: 'cooldown'`) combined with `warmup: true` gives `work` in openGym (explicit phase wins) but `warmup` in the port.
3. A non-string, non-null `phase` (for example `phase: 1`) is demoted to `extra`, so the typed `phase` is null and the port falls back to `warmup`. openGym treats it as an explicit phase and returns `work`.

Warm-up sets are excluded from volume, 1RM and PR logic, so any consumer of this getter will produce different numbers from openGym. That breaks the project's core value.
**Fix:** Port the function exactly, including the `fallback` parameter, and read the raw value so demoted types are handled too:
```dart
static String _normalizedPhase(Object? value, [String fallback = 'work']) {
  final String token = value is String ? value.trim().toLowerCase() : '';
  if (token == 'warmup' || token == 'warm-up' || token == 'warm_up') return 'warmup';
  if (token == 'work') return 'work';
  return fallback == 'warmup' ? 'warmup' : 'work';
}

String resolvedPhaseOr([String fallback = 'work']) {
  final Object? raw = phase ?? extra['phase'];
  if (raw != null && raw != '') return _normalizedPhase(raw, fallback);
  final Object? wu = warmup ?? extra['warmup'];
  return wu == true ? 'warmup' : _normalizedPhase(null, fallback);
}
```
Alternatively, delete the getter and resolve phases only through the JS bridge (JS-04), so the logic cannot drift.

### CR-03: ShellBloc handlers run concurrently and do whole-document read-modify-write, so updates get lost

**File:** `lib/features/shell/bloc/shell_bloc.dart:25-50`
**Issue:** By default, `flutter_bloc` handlers registered with `on<E>` run **concurrently**. Each handler does load, then `copyWith`, then a full `saveState`. Here is what happens if a user changes theme and then accent quickly (or a future settings screen dispatches both):
1. Both handlers read the same old state.
2. The theme handler saves `theme=light`, `accent=old`.
3. The accent handler saves `theme=old`, `accent=sky`.

The theme change is silently reverted in storage, and the UI state emitted last disagrees with what the first handler emitted.

The same pattern also overwrites *any* other write made to the profile between load and save, because `importState` replaces all four tables. Once Phase 3 writes workouts through the same repository, a theme change that lands mid-workout can drop a logged set.
**Fix:** Process shell events one at a time, and stop rewriting the whole document for a single-key change:
```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
on<ShellThemeChanged>(_onThemeChanged, transformer: sequential());
on<ShellAccentChanged>(_onAccentChanged, transformer: sequential());
```
Combining theme and accent into one `sequential()` stream also works, for example with a single `on<ShellEvent>` that switches on the event type. Better still, keep the loaded `GymState` in the Bloc, or add a repository `patchSettings(uid, {theme, accent})` that updates `doc_json` in a single transaction.

## Warnings

### WR-01: An unknown or missing theme falls back to dark, but openGym follows the system setting

**File:** `lib/features/shell/data/theme_settings.dart:44-54` (also the doc comment at lines 12-13)
**Issue:** openGym `App.jsx:48-50`:
```js
const resolveTheme = theme => theme === 'light' || theme === 'dark' ? theme : (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
```
Any value other than `'light'` or `'dark'` follows the OS preference, including `'system'`, a typo, a number or null. The port maps every unknown value to `ThemeMode.dark`. That breaks the 1:1 behaviour, and the doc comment ("unknown theme -> dark") repeats the wrong claim. A wrong-typed `theme` also becomes `null` through `JsonReader` demotion, and `fromState` then substitutes `'dark'`.
**Fix:**
```dart
static ThemeMode _themeModeFromOpenGym(String? theme) => switch (theme) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};
```
In `fromState`, pass `s?.theme` without the `?? GymState.defaultTheme` fallback when a stored state exists. Keep dark only for the "no stored state at all" case, which gives dark because of DEF.

### WR-02: User-initiated saves never stamp `_ts`

**File:** `lib/features/shell/bloc/shell_bloc.dart:40-41,47-48`
**Issue:** openGym `persist()` (`useStore.js:145-146`) sets `S._ts = Date.now()` on every local change, because `_ts` decides which copy wins on the next pull (`restoredStateFor`). `ShellBloc` saves the change with the old `_ts` (or none). When sync arrives in Phase 5, the server's copy will look newer and the user's theme or accent change will be discarded. The repository deliberately does not stamp, which is correct for import/export, so the stamping has to happen at the mutation site.
**Fix:** `current.copyWith(theme: event.theme, ts: DateTime.now().millisecondsSinceEpoch)`. Or add a `GymStateRepository.persistChange(uid, state)` that stamps `_ts`, mirroring `persist(S, push, stamp=true)`, separate from `importState`.

### WR-03: `copyWith` cannot clear nullable fields

**File:** `lib/core/models/gym_state.dart:299-385`, `lib/core/models/workout.dart:137-169`
**Issue:** Every parameter uses `x ?? this.x`, so a field can never be set back to null. openGym routinely writes explicit nulls. Finishing or discarding a workout sets `active = null`. `targetW`, `effort`, `activeEquipId`, `lastGymCardId` and `reminder.tz` are also valid as null. There is a second trap: if a field had been demoted to `extra` (null or wrong-typed) and later received a typed value, `extra` still carries the stale entry, and it reappears as soon as the typed field goes null again.
**Fix:** Use a sentinel or `ValueGetter` pattern for nullable fields, and drop the key from `extra` when a typed value is assigned:
```dart
static const Object _unset = Object();
GymState copyWith({Object? active = _unset, ...}) => GymState(
  active: identical(active, _unset) ? this.active : active as Workout?,
  extra: identical(active, _unset) ? extra : ({...extra}..remove('active'))..addAll(active == null ? {'active': null} : {}),
  ...
);
```

### WR-04: `exportState` reads in several statements without a transaction, so it can return a torn document

**File:** `lib/core/data/gym_state_repository.dart:109-131`
**Issue:** `user_state` is queried first, then each array table is queried separately. If an `importState` for the same uid commits in between, the result mixes the old `doc_json` and presence flags with the new array rows. For example, old `workouts_present = 1` combined with the new, deleted rows gives `workouts: []`. CR-03 makes concurrent import/export realistic, and a caller that saves the torn document (as `ShellBloc` does) makes the loss permanent.
**Fix:** Run the whole read inside `_db.transaction((txn) async { ... })`, and pass `txn` to `_rebuildList`.

### WR-05: `fetchState` and `pushState` treat unexpected responses as success

**File:** `lib/core/api/open_gym_api_client.dart:100-146`
**Issue:**
- `fetchState` returns `(state: null, rev: 0)`, the same as "server has nothing", when the body is not a Map. That happens for an HTML error page with 200, a proxy or captive-portal page, or a mis-set content-type that leaves the body as a `String`. It also happens when `state` is present but not an object. A sync layer that sees an "empty server at rev 0" may push local state over, or adopt emptiness, based on garbage.
- `pushState` returns `baseRev` when the response has no numeric `rev`, so the caller records a successful write at the old revision. The next push then 409s, or the local and server revisions silently diverge.

**Fix:** Throw a typed exception, for example `UnexpectedResponseException`, when the body is not a Map, when `state` is present but neither null nor a Map, or when `rev` is missing or non-numeric in a PUT response. Keep `(null, 0)` only for an explicit `{"state": null}`.

### WR-06: `ApiClientFactory.create` silently ignores the required `baseUrl` when `dio` is supplied

**File:** `lib/core/api/open_gym_api_client.dart:45-64`
**Issue:** `baseUrl` is `required`, but it is dropped whenever a `Dio` is passed. A Phase 5 caller that reuses a shared `Dio` will talk to whatever server that instance was configured for, which could be a previous account's server.
**Fix:** Either apply it (`resolvedDio.options.baseUrl = baseUrl;`) or make `baseUrl` optional and assert that exactly one source of the base URL is provided.

### WR-07: A startup database failure crashes the app, and save errors escape the Bloc handlers

**File:** `lib/main.dart:15-18`, `lib/features/shell/bloc/shell_bloc.dart:41,48`
**Issue:** `AppDatabase.open` and `defaultPath` are awaited before `runApp` with no error handling. A failed open (disk full, corrupt file, failed migration) leaves a blank or crashed app, contradicting the "shell must always boot" requirement (T-1-12) the Bloc documents. In the Bloc, a throwing `saveState` escapes the handler: no state is emitted and the user gets no feedback.
**Fix:** Wrap the bootstrap in `try/catch` and show a minimal error or recovery `MaterialApp`. In the handlers, catch `saveState` errors, call `addError`, and emit a state that reflects the unsaved change or an error flag.

### WR-08: The "byte-for-byte" round-trip claim is false

**File:** `lib/core/models/json_passthrough.dart:9-10,136-149`, `lib/core/data/gym_state_repository.dart:19-23,186`
**Issue:** The documented contract promises byte-for-byte round-trips, but the output is only deep-equal:
- `emit` writes `extra` keys first, then typed keys in declaration order. Any input whose unknown keys come before known ones (including openGym's `Object.assign(DEF, loaded)` order) comes back reordered.
- `importState` removes `workouts`, `routines` and `bodyweight` from `rest`, and `exportState` appends them at the end.
- Dart `jsonEncode(60.0)` emits `60.0`, where JS emits `60`.

Anything that compares serialized strings, such as a backup-diff check, a hash, or a future "changed since last push" check, will see false differences.
**Fix:** Change the doc comments to "deep-equal (key order and numeric formatting not preserved)". Or, if byte stability is required, keep the original key order: store it on parse and emit in that order, and in the repository re-insert split arrays at their original index.

## Info

### IN-01: Unused dependencies

**File:** `pubspec.yaml:42,44`
**Issue:** Nothing under `lib/` (generated code included) imports `path_provider` or `collection`.
**Fix:** Remove them until a phase needs them.

### IN-02: Duplicated `MaterialApp.router` branches, and a dark flash for light-theme users

**File:** `lib/app/app.dart:51-68`
**Issue:** The two switch arms are identical apart from where `settings` comes from. `ShellInitial` always renders dark, so a user who chose light (or system) sees a dark frame before `ShellReady` arrives.
**Fix:** `final ThemeSettings settings = switch (state) { ShellInitial() => const ThemeSettings.defaults(), ShellReady(:final settings) => settings };` then build one `MaterialApp.router`. Consider loading theme settings before `runApp` to avoid the flash.

### IN-03: The default accent is defined in three places

**File:** `lib/core/theme/accents.dart:20`, `lib/core/models/gym_state.dart:177-178`, `lib/core/models/default_state.dart:24-25`
**Issue:** `kDefaultAccentKey`, `GymState.defaultAccent` and `kDefaultState['accent']` (the theme default likewise) are independent literals that can drift.
**Fix:** Derive them from `kDefaultState` (for example `kDefaultState['accent']! as String`), or reference one constant.

### IN-04: The fixture's clock pin does not cover `Date()` called as a function

**File:** `tool/fixtures/gen_state_fixture.mjs:30-37`
**Issue:** `PinnedDate` pins only `new Date()` and `Date.now()`. `Date()` called without `new` still returns the real current time as a string. If `demoSeed.js` or `format.js` ever uses that form, the "byte-identical on rerun" guarantee silently breaks.
**Fix:** Wrap `PinnedDate` in a Proxy with an `apply` trap that returns `new OriginalDate(FIXED_MS).toString()`.

### IN-05: Model `extra` maps share references with the input maps

**File:** `lib/core/models/json_passthrough.dart:20-41`, `lib/core/models/default_state.dart:100-105`
**Issue:** `extra` is unmodifiable only at the top level. Nested lists and maps are the caller's objects, and `overlayOnDefaults` assigns loaded values by reference. If the source JSON map is mutated after parsing, the supposedly immutable `Equatable` model changes too, and its equality and hash change with it.
**Fix:** Deep-copy values into `_extra`, reusing `_deepClone` from `default_state.dart`, or document that inputs must not be mutated after parsing.

---

_Reviewed: 2026-09-25T10:10:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
