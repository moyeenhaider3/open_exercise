# Phase 1: Foundation & Models - Research

**Researched:** 2026-09-25
**Domain:** Flutter feature-first architecture, OpenAPI→Dart/Dio codegen, sqflite offline persistence
**Confidence:** MEDIUM (stack choices HIGH; codegen-vs-schema-fit finding HIGH; exact package pick for OpenAPI generator MEDIUM/LOW — flagged for human confirmation)

## Summary

Phase 1 has no CONTEXT.md — this research is the only steering document besides REQUIREMENTS.md/ROADMAP.md and CLAUDE.md. The phase is a pure data-layer phase: no UI logic, no JS engine, no auth flow yet (those are Phases 2–5). Three sub-problems, each researched independently:

1. **Folder structure + Bloc/Equatable conventions (FND-01, FND-05).** Dart 3's `sealed class` + `equatable` for Bloc state/event hierarchies is the current, well-established pattern (Dart ≥3.0, this project's SDK is 3.13.2). The official bloc library architecture guide does not mandate a specific DI package; `RepositoryProvider`/`MultiRepositoryProvider` (shipped inside `flutter_bloc` itself) is the officially-documented DI mechanism and needs no extra dependency — recommended over `get_it` for this phase's scope.

2. **OpenAPI → Dart/Dio codegen (FND-02).** This is the riskiest area. `../openGym/api/openapi.yaml` is OpenAPI **3.1.0**, and its own `State`/`Workout`/`Routine`/`BodyweightEntry` schemas are explicitly documented in the spec as **"representative, not enforced"** with `additionalProperties: true` everywhere — the server treats the whole app-state blob as opaque except for `workouts`/`routines` being arrays. This means: **codegen alone cannot produce the FND-03 model set.** Settings fields the app actually needs (`wc`, `wdec`, `weekStart`, `checkIn`, `weighIn`, `equipFilterOn`, `activeEquipId`, `gymCards`, `barWeights`, `exNotes`, `favEx`, `equipProfiles`, `customEx`, `exWeights`) are *not* individually typed in the OpenAPI spec at all — they only exist in `frontend/src/store/useStore.js`'s `DEF` constant. Plan for **two separate model-authoring tasks**: (a) codegen from `openapi.yaml` for the ~30 strictly-typed routes (auth, pairing, push, activity, admin, health, config, me), and (b) a hand-authored Dart domain model of the full state shape, sourced from `DEF` in `useStore.js`, independent of the OpenAPI spec.

3. **sqflite schema for lossless round-trip (FND-04).** Given the API's own "representative, not enforced" declaration and the deeply nested, evolving set shape (straight/dropset/restpause, per-side entries, drops, clusters — see `frontend/src/lib/workout-model.js`), a **normalized-columns-plus-raw-JSON-column hybrid** is recommended over full normalization or a single JSON blob. Indexed columns (date, id) serve Phase 3's History/Stats queries; a `raw_json` column per row guarantees byte-for-byte-equivalent round-trip of every field, known or not-yet-known.

**Primary recommendation:** Use `flutter_bloc` + `equatable` with Dart 3 sealed state/event classes and `RepositoryProvider` for DI (no `get_it` needed yet); generate Dio clients from `openapi.yaml` with the official OpenAPITools `dart-dio` generator run via the `openapi_generator` pub wrapper (`serializationLibrary: json_serializable`, not the default `built_value`, to avoid its documented free-form-object/`BuiltMap` pitfall) for the strictly-typed routes only; hand-author the full app-state Dart model from `DEF`; store state in sqflite with normalized indexed columns + a `raw_json` passthrough column per entity; test with `sqflite_common_ffi` in plain `flutter test`. **The `openapi_generator` package choice needs human confirmation** — it requires a JVM, which is not installed on this dev machine (see Environment Availability), and no Context7/official-docs source could be consulted for it in this session (Context7 MCP unavailable, `ctx7` CLI unavailable) — this whole area is `[ASSUMED]`.

## Project Constraints (from CLAUDE.md)

- **License:** AGPL-3.0-or-later — every new source file this phase creates must carry (or the project must document) the AGPL header/notice consistent with the rest of the repo.
- **Stack is user-mandated, not negotiable:** `flutter_bloc`, `equatable`, `sqflite`, Dio (OpenAPI-generated), `flutter_js`, `flutter_local_notifications`, `flutter_passkey_service`, `xml`, `path_drawing`. Phase 1 only touches `flutter_bloc`, `equatable`, `sqflite`, and Dio — the rest are Phase 2/4/5 concerns; do not add them now.
- **Process:** one phase at a time, user approval required before Phase 2 starts. This RESEARCH.md is scoped to Phase 1 only.
- **GSD workflow enforcement:** file edits during execution must go through `/gsd-execute-phase` (already the intended path for this phase).
- No project-specific `STACK.md`/`CONVENTIONS.md`/`ARCHITECTURE.md` content exists yet (all say "not yet documented/established/mapped") — this phase is what establishes them.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | Feature-first layout (`lib/core/`, `lib/features/<feature>/{data,bloc,view}`), flutter_bloc + equatable, sealed State classes, explicit Event classes | See Architecture Patterns → Recommended Project Structure, Pattern 1 (Sealed Bloc State) |
| FND-02 | Dart models + Dio clients generated from `openapi.yaml`, covering every route (auth, pair, data/rev, push, activity, admin) | See Standard Stack (OpenAPI codegen), Common Pitfalls (built_value/additionalProperties), Code Examples |
| FND-03 | Dart models for full user state (`DEF` in `useStore.js`), including set `phase`/`type`, drops and clusters | See Summary finding #2, Architecture Patterns → Pattern 2 (Known-Fields-Plus-Passthrough Model), Don't Hand-Roll |
| FND-04 | sqflite schema stores that state; import/export round-trips a real `state-<uid>.json` losslessly | See Architecture Patterns → sqflite schema, Common Pitfalls (round-trip equality), Validation Architecture |
| FND-05 | App boots to empty shell with DI, routing, theme (dark/light, accent) wired up | See Architecture Patterns → Pattern 1, Code Examples (theme/accent), Standard Stack (go_router) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Feature-first folder structure, DI wiring, routing, theming | Client (Flutter app shell) | — | Pure client-side scaffolding; no server involved |
| Bloc state/event classes | Client (Bloc business-logic layer) | — | flutter_bloc pattern is entirely in-app |
| OpenAPI-generated Dio clients | Client → API boundary | API / Backend (openGym server, read-only reference) | Client owns the generated code; the server (`../openGym/api/server.js`) is the immutable contract source, never modified |
| Full app-state Dart models (DEF shape) | Client (domain model layer) | — | Mirrors `useStore.js`'s `DEF`; no server enforcement (schema is "representative, not enforced") |
| sqflite schema + repository | Client (Database/Storage tier) | — | On-device persistence; no server-side schema exists (server stores the same blob as flat JSON files, not SQL) |
| Round-trip import/export test | Client (Database/Storage tier) | — | Verifies local persistence fidelity only; no network call in the test |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_bloc` | 9.1.1 | State management (Bloc pattern) | User-mandated; official, most-adopted Bloc-pattern package for Flutter |
| `equatable` | 3.0.0 | Value equality for Bloc states/events and domain models | User-mandated; standard companion to flutter_bloc, avoids hand-written `==`/`hashCode` |
| `sqflite` | 2.4.4 | On-device SQLite persistence | User-mandated; the de-facto SQLite plugin for Flutter |
| `dio` | 5.11.1 | HTTP client | User-mandated; most-adopted Dart HTTP client, supports interceptors needed later for auth/sync (Phases 5–6) |
| `go_router` 【ASSUMED】 | 18.0.1 | Declarative routing for the empty shell | Not user-mandated but required by FND-05 ("routing… wired up"); officially maintained by the Flutter team, now the de-facto standard replacing hand-rolled `Navigator` 2.0 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sqflite_common_ffi` | 2.4.3 | Run sqflite against desktop SQLite in plain `flutter test` (no emulator) | Dev-dependency; required for the FND-04 round-trip test to run headless |
| `path_provider` | 2.1.6 | Resolve the on-device database file path | Needed anywhere `openDatabase(path)` is called outside tests |
| `path` | 1.9.1 | Join/normalize the sqflite db path | Small utility, avoids hand-rolled string concatenation |
| `json_annotation` + `json_serializable` | 4.12.0 / 6.14.1 | Hand-authored DEF-shape model (de)serialization | Standard, mature (2017), avoids hand-writing `toJson`/`fromJson` for ~25 top-level fields |
| `collection` | latest (verify) | `DeepCollectionEquality` for the round-trip test's JSON comparison | Official `dart-lang` package; deep-equality on decoded `Map`/`List` trees is the correct way to compare "equivalent JSON" (ignores key order) |
| `bloc_test` | 10.0.0 | Unit-testing Blocs (`blocTest()` helper) | Dev-dependency; needed once any Bloc exists (even the empty-shell theme/nav Bloc) |
| `mocktail` | 1.0.5 | Mocking repositories in Bloc/unit tests | Dev-dependency; null-safety-friendly alternative to `mockito` (no code generation step) |

### OpenAPI → Dart/Dio Codegen (needs human confirmation — see Assumptions Log A1–A3)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `openapi_generator` 【ASSUMED】 | 7.0.0 | Wraps the official OpenAPITools `dart-dio` generator via `build_runner` | Primary recommendation — mature (125 likes, ~10k downloads/30d), backed by the widely-used cross-language OpenAPITools project. **Requires a JVM on the build machine** (see Environment Availability — not installed here) |
| `openapi_retrofit_generator` 【ASSUMED】 | 2.0.4 | Pure-Dart generator, emits `retrofit` + `dio` clients, no JVM | Fallback if the JVM cannot be provisioned in CI/dev, or if `dart-dio`'s 3.1-parsing edge cases block codegen. Explicitly tested against OpenAPI 3.1 per its own docs, but young (published 2025-11, 5 likes on pub.dev) — treat as unverified until a spike proves it parses `openapi.yaml` cleanly |
| `retrofit` + `retrofit_generator` | 4.10.0 / 10.2.11 | Only needed if `openapi_retrofit_generator` fallback is used | These generate Dio-backed clients from `@RestApi`/`@GET` annotations; mature (2019), high adoption |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `openapi_generator` (dart-dio, JVM-based) | `openapi_retrofit_generator` (pure Dart) | No JVM dependency and explicit 3.1 support, but far less adopted (5 likes vs 125) and newer (published 2025-11) — less battle-tested |
| `openapi_generator` / `openapi_retrofit_generator` (full codegen) | Hand-written Dio client + hand-written `json_serializable` models for every route | Guarantees exact control over the loosely-typed `State` schema, but contradicts the user's explicit "Dio (OpenAPI-generated)" stack mandate and forfeits auto-regeneration when the server's `openapi.yaml` changes |
| `go_router` | Hand-rolled `Navigator`/`MaterialPageRoute` | go_router is declarative, has redirect/guard support useful once auth exists (Phase 5), and is the ecosystem standard; hand-rolling saves a dependency but adds boilerplate that has to be revisited in Phase 5 anyway |
| `RepositoryProvider`/`MultiRepositoryProvider` (built into flutter_bloc) | `get_it` service locator | `get_it` is popular for service-locator-style access outside the widget tree (useful once `JsEngineService` in Phase 2 needs to be reached from background isolates/notification callbacks) — defer introducing it until that need is concrete, per YAGNI; `RepositoryProvider` is sufficient for Phase 1's DI needs and is the officially-documented flutter_bloc DI mechanism |
| Normalized relational sqflite schema (one column per DEF field) | Single opaque JSON blob column (no structure at all) | A single blob round-trips perfectly but makes Phase 3's History/Stats queries (date-range filters, joins) impossible without loading and decoding the whole document; the hybrid (below) gets both |

**Installation:**
```bash
flutter pub add flutter_bloc equatable sqflite dio go_router path_provider path json_annotation collection
flutter pub add --dev sqflite_common_ffi bloc_test mocktail build_runner json_serializable
# OpenAPI codegen tool — pick ONE after the Wave-0 spike described in Open Questions:
flutter pub add --dev openapi_generator            # requires a JVM on PATH
# OR
flutter pub add --dev openapi_retrofit_generator retrofit retrofit_generator
flutter pub add retrofit dio
```

**Version verification:** All versions above were confirmed live against the pub.dev registry API (`https://pub.dev/api/packages/<name>`) on 2026-09-25 — see the exact commands and raw output captured during this research session. Re-run before planning tasks reference exact version pins, since pub.dev versions can move between research and execution:
```bash
curl -s https://pub.dev/api/packages/<package> | python3 -c "import json,sys;print(json.load(sys.stdin)['latest']['version'])"
```

## Package Legitimacy Audit

> `slopcheck` was installed and runs (`slopcheck install ... `), but **its `--ecosystem` flag only supports `pypi, npm, crates.io, go, rubygems, maven, packagist` — no Dart/pub.dev ecosystem exists.** Per the graceful-degradation rule, **every package in this document is tagged `[ASSUMED]`** regardless of how thoroughly it was cross-checked against the pub.dev registry API (registry existence is not equivalent to a slopcheck-style hallucination check). The planner **must** gate every new dependency behind a `checkpoint:human-verify` task before `flutter pub add` runs it for real.

| Package | Registry | Age (first published) | Downloads (30d) | Source Repo | slopcheck | Disposition |
|---------|----------|------------------------|------------------|--------------|-----------|-------------|
| `flutter_bloc` | pub.dev | 2018-10-23 (~8 yrs) | high (framework-tier) | github.com/felangel/bloc | N/A — no pub ecosystem support | Approved, `[ASSUMED]` |
| `equatable` | pub.dev | 2019-01-06 (~7.7 yrs) | high | github.com/felangel/equatable | N/A | Approved, `[ASSUMED]` |
| `sqflite` | pub.dev | 2017-06-28 (~9.2 yrs) | high | github.com/tekartik/sqflite | N/A | Approved, `[ASSUMED]` |
| `sqflite_common_ffi` | pub.dev | 2020-03-12 (~6.5 yrs) | high | github.com/tekartik/sqflite | N/A | Approved, `[ASSUMED]` |
| `dio` | pub.dev | (not resolved this session) | high | github.com/cfug/dio | N/A | Approved, `[ASSUMED]` |
| `go_router` | pub.dev | (Flutter-team maintained) | high | github.com/flutter/packages | N/A | Approved, `[ASSUMED]` |
| `json_annotation` / `json_serializable` | pub.dev | 2017 (~9 yrs) | high | github.com/google/json_serializable.dart | N/A | Approved, `[ASSUMED]` |
| `retrofit` / `retrofit_generator` | pub.dev | 2019-04-07 (~7.4 yrs) | moderate-high | github.com/trevorwang/retrofit.dart | N/A | Approved, `[ASSUMED]` |
| `bloc_test` | pub.dev | (felangel/bloc monorepo) | high | github.com/felangel/bloc | N/A | Approved, `[ASSUMED]` |
| `mocktail` | pub.dev | (felangel maintained) | high | github.com/felangel/mocktail | N/A | Approved, `[ASSUMED]` |
| `openapi_generator` | pub.dev | ~3 months before this session (v7.0.0) | 10,366 | pub.dev listing only, publisher `devappliance.com` (verified publisher badge) | N/A | **Flagged — moderate adoption (125 likes) but requires an unverified-here JVM toolchain; planner must add `checkpoint:human-verify`** |
| `openapi_retrofit_generator` | pub.dev | 2025-11-12 (~10 months old) | 2,227 | github.com/westito/openapi_retrofit_generator | N/A | **Flagged — young package, only 5 likes; planner must add `checkpoint:human-verify` and a Wave-0 spike before committing to it** |

**Packages removed due to slopcheck [SLOP] verdict:** none (slopcheck could not evaluate this ecosystem at all).
**Packages flagged as suspicious:** `openapi_generator` (JVM dependency risk), `openapi_retrofit_generator` (young, low-adoption) — planner must insert `checkpoint:human-verify` before either is actually installed, and should treat the OpenAPI-generator choice as a Wave-0 spike/decision point, not a locked task.

## Architecture Patterns

### System Architecture Diagram

```
 openGym server (read-only reference; never modified)
   ../openGym/api/openapi.yaml  ──────────┐
   ../openGym/frontend/src/store/useStore.js (DEF) ──┐
                                                       │
                                                       ▼
 ┌───────────────────────────── Flutter app (this repo) ─────────────────────────────┐
 │                                                                                     │
 │  lib/core/                                                                         │
 │   ├─ api/            <-- codegen output from openapi.yaml (Dio clients + strict    │
 │   │                       models: auth, pair, data/rev envelope, push, activity,    │
 │   │                       admin)                                                    │
 │   ├─ db/             <-- sqflite: schema, migrations, DatabaseProvider              │
 │   ├─ models/          <-- hand-authored GymState/Workout/Routine/SetEntry models,   │
 │   │                       sourced from useStore.js DEF, NOT from openapi.yaml        │
 │   ├─ theme/           <-- ColorScheme.fromSeed + ACCENTS map (ported 1:1 from        │
 │   │                       frontend/src/lib/format.js)                               │
 │   └─ router/          <-- go_router config, empty shell route                       │
 │                                                                                     │
 │  lib/features/<feature>/                                                           │
 │   ├─ data/    <-- repositories: GymStateRepository (sqflite <-> models),             │
 │   │               ApiRepository (Dio clients <-> network)                          │
 │   ├─ bloc/    <-- sealed State classes (Equatable), explicit Event classes           │
 │   └─ view/    <-- widgets consuming Bloc state via BlocBuilder/BlocListener          │
 │                                                                                     │
 │  Data flow for FND-04 (round-trip test):                                            │
 │   state-<uid>.json --(jsonDecode)--> raw Map --(GymState.fromJson, passthrough-safe) │
 │     --> GymStateRepository.importState() --(sqflite INSERT, normalized+raw_json)-->  │
 │     sqflite file --(GymStateRepository.exportState())--> GymState.toJson()           │
 │     --(jsonEncode)--> re-serialized JSON --(DeepCollectionEquality)--> assert equal   │
 │                        to the original decoded Map                                   │
 └─────────────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
lib/
├── core/
│   ├── api/                     # generated Dio clients + generated strict models (git-ignored .g.dart, committed .dart wrappers if any)
│   ├── db/
│   │   ├── app_database.dart    # openDatabase(), onCreate schema, migrations
│   │   └── tables/              # one file per table's SQL + column const names
│   ├── models/
│   │   ├── gym_state.dart       # full DEF-shape model, hand-authored
│   │   ├── workout.dart         # Workout + WorkoutEntry + SetRow (phase/type/drops/clusters)
│   │   ├── routine.dart
│   │   └── bodyweight_entry.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── accents.dart         # ACCENTS map ported from frontend/src/lib/format.js
│   └── router/
│       └── app_router.dart
├── features/
│   └── shell/                   # the empty themed shell for FND-05
│       ├── bloc/
│       │   ├── shell_event.dart
│       │   └── shell_state.dart
│       └── view/
│           └── shell_page.dart
└── main.dart
test/
├── core/
│   ├── db/
│   │   └── round_trip_test.dart # FND-04's automated round-trip test
│   └── models/
└── fixtures/
    └── state_sample.json        # synthetic-but-representative state-<uid>.json (see Open Questions)
```

### Pattern 1: Sealed Bloc State + Explicit Events (Dart 3)

**What:** Bloc state hierarchies use Dart 3 `sealed class` (exhaustive `switch` in the UI layer) combined with `Equatable` for value equality; events are explicit classes, not stringly-typed enums.
**When to use:** Every Bloc in `lib/features/*/bloc/`, starting with the Phase 1 shell/theme Bloc.
**Example:**
```dart
// lib/features/shell/bloc/shell_state.dart
sealed class ShellState extends Equatable {
  const ShellState();
  @override
  List<Object?> get props => [];
}

final class ShellInitial extends ShellState {
  const ShellInitial();
}

final class ShellReady extends ShellState {
  const ShellReady({required this.themeMode, required this.accent});
  final ThemeMode themeMode;
  final Color accent;
  @override
  List<Object?> get props => [themeMode, accent];
}

// lib/features/shell/bloc/shell_event.dart
sealed class ShellEvent extends Equatable {
  const ShellEvent();
  @override
  List<Object?> get props => [];
}

final class ShellStarted extends ShellEvent {
  const ShellStarted();
}
```
This is training-knowledge-standard Dart 3 practice, not sourced from a single official doc page in this session — `[ASSUMED]`, but low-risk (sealed classes + Equatable is a widely documented, mechanical pattern with no ambiguity).

### Pattern 2: Known-Fields-Plus-Passthrough Model (critical for FND-03/FND-04)

**What:** Because `openapi.yaml`'s `State`/`Workout`/`Routine` schemas are declared `additionalProperties: true` and explicitly "representative, not enforced" `[CITED: ../openGym/api/openapi.yaml lines 1264-1274]`, every hand-authored model must retain **any JSON key it doesn't explicitly know about** and re-emit it unchanged on `toJson()`. Do not model these as fully-closed classes.
**When to use:** `GymState`, `Workout`, `Routine`, and any per-set row model (`phase`, `type`, `drops`, `clusters` — see `../openGym/frontend/src/lib/workout-model.js` lines 14-107).
**Example:**
```dart
class GymState {
  GymState({required this.unit, required this.workouts, /* ...known fields... */, required Map<String, dynamic> extra})
      : _extra = Map<String, dynamic>.from(extra);

  final String unit;
  final List<Workout> workouts;
  // ...
  final Map<String, dynamic> _extra; // every key this class doesn't model explicitly

  factory GymState.fromJson(Map<String, dynamic> json) {
    final known = {'unit', 'workouts', 'routines', /* ... */};
    return GymState(
      unit: json['unit'] as String? ?? 'kg',
      workouts: (json['workouts'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Workout.fromJson)
          .toList(),
      // ...
      extra: {for (final k in json.keys.where((k) => !known.contains(k))) k: json[k]},
    );
  }

  Map<String, dynamic> toJson() => {
        ..._extra,           // unknown fields first so known fields can override if needed
        'unit': unit,
        'workouts': workouts.map((w) => w.toJson()).toList(),
        // ...
      };
}
```
This pattern is a standard forward-compatibility technique for evolving JSON APIs (not unique to this project) — `[ASSUMED]`, reasoning from the verified source comment in `openapi.yaml`.

### Recommended sqflite Schema (hybrid: normalized + raw JSON passthrough)

```sql
-- One row per locally-known profile (supports guest + multiple signed-in accounts on one device)
CREATE TABLE user_state (
  uid TEXT PRIMARY KEY,
  rev INTEGER NOT NULL DEFAULT 0,
  ts INTEGER,
  settings_json TEXT NOT NULL,   -- unit, lang, theme, accent, restSec, restPauseSec, sound,
                                  -- soundOnSilent, timerFlash, keepAwake, body, targetW, gifSize,
                                  -- workoutView, wc, effort, autoBackup, equipFilterOn,
                                  -- activeEquipId, weekStart, wdec, checkIn, weighIn,
                                  -- lastGymCardId, reminder{on,time,tz}
  week_json TEXT NOT NULL DEFAULT '{}',
  day_plan_json TEXT NOT NULL DEFAULT '{}',
  ex_weights_json TEXT NOT NULL DEFAULT '{}',
  custom_ex_json TEXT NOT NULL DEFAULT '[]',
  ex_notes_json TEXT NOT NULL DEFAULT '{}',
  fav_ex_json TEXT NOT NULL DEFAULT '[]',
  bar_weights_json TEXT NOT NULL DEFAULT '{}',
  gym_cards_json TEXT NOT NULL DEFAULT '[]',
  equip_profiles_json TEXT NOT NULL DEFAULT '[]',
  active_json TEXT,               -- in-progress workout; device-local, must still round-trip
  extra_json TEXT NOT NULL DEFAULT '{}'  -- catch-all for any future top-level key
);

-- Indexed for Phase 3 History/Stats date-range queries; raw_json guarantees lossless round-trip
CREATE TABLE workouts (
  id TEXT NOT NULL,
  uid TEXT NOT NULL,
  d TEXT,              -- ISO date, e.g. "2026-08-30"
  start INTEGER,
  end INTEGER,
  routine_id TEXT,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (uid, id)
);
CREATE INDEX idx_workouts_uid_d ON workouts(uid, d);

CREATE TABLE routines (
  id TEXT NOT NULL,
  uid TEXT NOT NULL,
  name TEXT,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (uid, id)
);

CREATE TABLE bodyweight (
  uid TEXT NOT NULL,
  d TEXT NOT NULL,
  w REAL,
  t INTEGER,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (uid, d, t)   -- (t included: verify whether openGym allows >1 entry/day before locking this)
);
CREATE INDEX idx_bodyweight_uid_d ON bodyweight(uid, d);
```
Rationale: `d` (date) is the column every future History/Stats/chart query in Phase 3 will filter and sort on; extracting it avoids `json_extract()` on every row. `raw_json` per entity is what makes the FND-04 round-trip test pass even for fields this phase's Dart models don't yet know about (the spec's own `additionalProperties: true` guarantees such fields exist and will keep being added, per the spec's changelog-style comments).

### Anti-Patterns to Avoid

- **Fully normalizing `Workout.entries[].sets[]` into per-set rows:** The set shape is deeply variable (straight/dropset/restpause, per-side sub-objects, optional `rir`/`rpe`, `drops`/`clusters` arrays of arbitrary length) and explicitly called out by the API author as representative-only. A rigid per-set table will silently drop fields the first time openGym's own schema grows (it has grown many times per the inline comments referencing issue numbers). Keep sets inside `workouts.raw_json`.
- **Using the OpenAPI generator's default `built_value` serializer:** For `dart-dio`, `built_value` is documented to mishandle free-form/`additionalProperties` objects (`BuiltMap` does not serialize as a plain map) — see Common Pitfalls. Force `serializationLibrary: json_serializable` if using this generator.
- **Trusting `openapi.yaml`'s `State` schema as the full FND-03 model:** it is missing `gymCards`, `barWeights`, `exNotes`, `favEx`, `wc`, `wdec`, `weekStart`, `checkIn`, `weighIn`, `equipFilterOn`, `activeEquipId`, `gifSize`, `workoutView`, `soundOnSilent`, `timerFlash`, `keepAwake`, `body`, `targetW`, `autoBackup` as named properties (they fall under the schema's blanket `additionalProperties: true`). Source these from `useStore.js`'s `DEF` constant directly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON (de)serialization boilerplate for ~25 top-level fields | Manual `toJson`/`fromJson` per model | `json_serializable` (code-gen `part 'x.g.dart'`) | Error-prone by hand at this field count; still compose with the passthrough pattern above for unknown keys |
| Value equality for Bloc states/models | Manual `==`/`hashCode` overrides | `equatable`'s `Equatable` mixin | User-mandated; exactly the problem it exists to solve |
| Deep JSON equality for the round-trip test | String-comparing re-serialized JSON | `package:collection`'s `DeepCollectionEquality` on decoded `Map`/`List` trees | Raw string comparison is brittle to key order and number formatting (`1.0` vs `1`); decode-then-deep-equal is what "equivalent JSON" means |
| Dio client method dispatch for 30 routes | Hand-written `dio.get('/api/...')` calls scattered through repositories | Generated client from `openapi.yaml` (whichever generator is chosen) | Exactly what FND-02 requires, and keeps the client in sync when the (read-only) reference spec changes |
| SQLite path/migration boilerplate | Hand-rolled `File` path joining, ad-hoc `ALTER TABLE` scripts | `path_provider` + `path` for the file location; `onCreate`/`onUpgrade` callbacks in `openDatabase()` for schema versioning | Standard sqflite lifecycle hooks exist precisely for this |

**Key insight:** The recurring theme in this phase is that the *reference API is intentionally loosely typed* (the spec says so in its own prose). Every "don't hand-roll" recommendation above still has to compose with the passthrough model, or it will silently violate FND-04's round-trip guarantee the first time a real profile has a field this phase's authors didn't anticipate.

## Common Pitfalls

### Pitfall 1: `dart-dio` generator's default serializer drops/mangles free-form objects
**What goes wrong:** Generated models for `additionalProperties: true` schemas (i.e., `State`, `Workout`, `Routine`) come out as `BuiltMap` under the generator's default `built_value` serializer, which does not serialize back to a plain JSON map — round-tripping through it silently corrupts the "opaque" parts of the state.
**Why it happens:** `built_value` is a strongly-typed, immutable-collection library; it was never designed for schema-less/`additionalProperties` JSON.
**How to avoid:** Set `serializationLibrary: json_serializable` in the generator config (documented as an available option), **or** — the recommended path here — don't run codegen against `State`/`Workout`/`Routine`/`BodyweightEntry` at all; treat the `/api/data` request/response bodies as raw `Map<String, dynamic>` in the generated client and hand-author the domain model per Pattern 2.
**Warning signs:** Generated model tests show `_rev`/`_ts`-style unknown fields disappearing after a round-trip, or the generated model exposes only the explicitly-declared `State` properties (missing e.g. `gymCards`).
`[CITED: OpenAPITools/openapi-generator GitHub issues #8497, #15670 — see Sources]`

### Pitfall 2: OpenAPI 3.1 edge cases in `dart-dio`/OpenAPI Generator CLI 7.x
**What goes wrong:** The official generator's 3.1 support is real but has open edge-case bugs (e.g., `prefixItems`-only array schemas, null-schema checks) as of recent 7.x releases.
**Why it happens:** OpenAPI 3.1 adopted JSON Schema 2020-12 wholesale; the generator's internal model still carries assumptions from 3.0's more restrictive schema dialect, and the "openapi-normalizer" pass that bridges the two is still being iterated on.
**How to avoid:** Run a throwaway codegen spike against the actual `../openGym/api/openapi.yaml` (1.5k lines, real 3.1 constructs) *before* committing to task breakdown — if it throws, either pin an older/compatible generator version, pre-process the spec with a 3.1→3.0.3 downgrade step, or switch to `openapi_retrofit_generator` (explicitly validated against 3.1 per its own docs).
**Warning signs:** Generator throws during doc parsing/normalization, or silently produces empty/wrong-typed models for routes that use `oneOf: [..., {type: 'null'}]` (this exact pattern appears repeatedly in `openapi.yaml`, e.g. `GET /api/data`'s `state` property).

### Pitfall 3: `sqflite` factory not initialized for `flutter test`
**What goes wrong:** Calling `openDatabase()` in a plain `flutter test` run (no emulator/simulator attached) throws `MissingPluginException` — sqflite's platform channel doesn't exist outside a running app.
**Why it happens:** `sqflite`'s default `databaseFactory` talks to platform channels backed by native Android/iOS code, which the `flutter test` harness doesn't provide.
**How to avoid:** In test setup, call `sqfliteFfiInit()` then `databaseFactory = databaseFactoryFfi` (from `sqflite_common_ffi`) before any `openDatabase()` call; use `inMemoryDatabasePath` for a fresh DB per test.
**Warning signs:** `flutter test` output shows `MissingPluginException(No implementation found for method openDatabase on channel com.tekartik.sqflite)`.
`[CITED: sqflite_common_ffi/doc/testing.md, github.com/tekartik/sqflite]`

### Pitfall 4: Comparing round-tripped JSON as raw strings
**What goes wrong:** `jsonEncode(importedThenExported) == originalRawString` fails even when the data is semantically identical, because key order, number formatting, or whitespace can differ between the original file and Dart's `jsonEncode` output.
**Why it happens:** JSON key order is not significant per the JSON spec but IS significant to `==` on strings.
**How to avoid:** Decode both sides to `Map`/`List` trees (`jsonDecode`) and compare with `const DeepCollectionEquality().equals(a, b)` from `package:collection`, not string equality. Preserve array *order* though — `workouts` is documented as "chronological" and reordering would be a real bug, not a cosmetic difference.
**Warning signs:** A round-trip test that passes for a hand-written single-field fixture but fails the moment a real multi-workout state file (with nested arrays) is used.

### Pitfall 5: `PUT /api/data` semantics leaking into the local-only round-trip test
**What goes wrong:** The server strips `state.active` and stamps `_rev` on every `PUT` (`../openGym/api/server.js` lines 939-941). If the round-trip test's import/export path accidentally reuses that server-side logic (e.g., a shared "normalize state" function copy-pasted from `useStore.js`'s sync code), `active` and `_rev` will NOT round-trip, failing FND-04's "equivalent JSON" requirement.
**Why it happens:** The active-workout-stripping and rev-stamping behavior belongs to the *sync* protocol (Phase 6), not to local persistence. FND-04 is purely local: import a file, store it, export it back — `active` and `_rev`/`_ts` must survive untouched.
**How to avoid:** Keep the local import/export path (Phase 1) completely separate from any future sync-merge code (Phase 6); do not strip or stamp anything during local round-trip.
**Warning signs:** Round-trip test fails specifically on the `active` key or on `_rev` changing value.

## Code Examples

### `sqflite_common_ffi` test bootstrap
```dart
// test/core/db/round_trip_test.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('imports a real state-<uid>.json and exports equivalent JSON', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    // ... create schema, import fixture, export, assert deep-equal ...
  });
}
```
`[CITED: sqflite_common_ffi README/doc/testing.md]`

### Accent color parity (verified source)
```dart
// lib/core/theme/accents.dart
// Ported 1:1 from ../openGym/frontend/src/lib/format.js:94
const Map<String, Color> kAccents = {
  'lime':   Color(0xFF30D158),
  'sky':    Color(0xFF0A84FF),
  'orange': Color(0xFFFF9F0A),
  'violet': Color(0xFFBF5AF2),
  'pink':   Color(0xFFFF375F),
  'red':    Color(0xFFFF453A),
  'teal':   Color(0xFF40C8E0),
  'gold':   Color(0xFFFFD60A),
};
```
`[VERIFIED: grep of ../openGym/frontend/src/lib/format.js line 94, this session]` — this is a directly-observed source-code fact, not a package claim, so it earns `[VERIFIED]` (not `[ASSUMED]`) despite the general package-provenance rule, which applies to package names/registries, not to inline literal constants copied from the reference codebase.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Hand-rolled `abstract class State {}` + manual `==` | `sealed class` (Dart 3.0, 2023) + exhaustive `switch` in UI, `equatable` for equality | Dart 3.0 (2023) | Compiler-enforced exhaustiveness on state handling in the UI layer |
| `mockito` (code-gen mocks) for Bloc/repository tests | `mocktail` (no code-gen, pure Dart) | mocktail has been the de facto choice for null-safe Dart for several years | Simpler test setup, no `build_runner` step just for mocks |
| Hand-rolled `Navigator` 2.0 `RouterDelegate`/`RouteInformationParser` | `go_router` (Flutter-team maintained) | go_router has been the recommended approach for a few years now, current major v18 | Declarative routes, built-in redirect/guard hooks useful for Phase 5 auth gating |

**Deprecated/outdated:** N/A for this phase — no prior openGym-Flutter code exists to migrate away from (Phase 1 is greenfield).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `openapi_generator` (devappliance, v7.0.0) is the right wrapper for the official OpenAPITools `dart-dio` generator and is safely installable | Standard Stack, Package Legitimacy Audit | Requires a JVM this dev machine doesn't have; if the JVM can't be provisioned, the whole FND-02 codegen task needs to pivot to the fallback generator or a hand-written client, changing task shape |
| A2 | `openapi_retrofit_generator` (westito, v2.0.4) correctly parses this project's real OpenAPI 3.1 spec and produces working Dio-backed clients | Standard Stack, Alternatives Considered | Young package (5 likes, ~10 months old); a Wave-0 spike could reveal it fails on constructs `openapi.yaml` actually uses (`oneOf` with null, deeply nested `additionalProperties`) |
| A3 | Setting `serializationLibrary: json_serializable` on the `dart-dio` generator avoids the `built_value`/free-form-object pitfall cleanly (rather than just changing which way it breaks) | Common Pitfalls, Anti-Patterns | If it still mangles free-form objects under json_serializable mode too, the "codegen for strict routes only, hand-model for State" split becomes even more necessary — but the planner should not assume json_serializable mode is a full fix without a spike |
| A4 | No `state-<uid>.json` sample file exists anywhere on disk reachable from this project (`../openGym/` was searched; none found) | Open Questions | The round-trip test fixture must be either hand-authored or generated via `../openGym/frontend/src/lib/demoSeed.js`'s `buildDemoState()` (verified to exist and be a pure function) plus manual augmentation for dropset/restpause/per-side/equipProfiles/gymCards cases `demoSeed.js` doesn't cover — if the fixture is too thin, the round-trip test won't actually exercise FND-03's hardest cases |
| A5 | `RepositoryProvider`/`MultiRepositoryProvider` (no `get_it`) is sufficient DI for Phase 1's empty shell | Alternatives Considered | If Phase 2's `JsEngineService` genuinely needs service-locator-style access outside the widget tree, DI may need revisiting — but that's Phase 2's problem, not Phase 1's, per YAGNI |
| A6 | Dart 3 `sealed class` + `equatable` Bloc pattern (Pattern 1) is uncontroversial/standard enough to not need per-detail sourcing | Architecture Patterns | Low risk — this is widely-taught, mechanical Dart 3 practice, but flagged here for completeness per the tagging rule |

**If this table is empty:** N/A — see rows above.

## Open Questions (RESOLVED)

1. **Which OpenAPI generator actually works cleanly against this real 3.1 spec?**
   - What we know: Two viable pub packages exist (`openapi_generator` JVM-based official generator wrapper; `openapi_retrofit_generator` pure-Dart). Neither was actually run against `../openGym/api/openapi.yaml` in this research session (no JVM available to test the first; the second wasn't executed either, to keep this research read-only).
   - What's unclear: Whether either cleanly handles this spec's `oneOf: [Schema, {type: 'null'}]` pattern (used repeatedly, e.g. `GET /api/data`'s `state` property) and its `additionalProperties: true` schemas without manual post-processing.
   - Recommendation: The planner should schedule a **Wave 0 spike task**: install a JVM (`brew install openjdk` or similar) and run `openapi_generator`'s codegen once against the real spec; in parallel/fallback, try `openapi_retrofit_generator` without a JVM. Whichever produces compiling Dart with the fewest manual fixups wins. Do not lock the generator choice in the plan without this spike.
   - **RESOLVED:** Plan 01-02 runs the generator spike followed by a `checkpoint:decision` to pick the generator.

2. **Is there any real `state-<uid>.json` file the team can use as the FND-04 fixture?**
   - What we know: None exists in `../openGym/` or anywhere searched on this machine. `demoSeed.js`'s `buildDemoState()` is a pure, dependency-light function that produces a realistic 12-week history (workouts, routines, bodyweight, effort ratings) but does **not** cover dropsets, restpause clusters, per-side (unilateral) entries, supersets, `equipProfiles`, `gymCards`, `customEx`, `favEx`, `barWeights`, or `exNotes`.
   - What's unclear: Whether the user has access to (or is willing to export) a real profile's `state-<uid>.json` from a running openGym instance, which would be the strongest possible fixture.
   - Recommendation: If no real file is available, generate a base fixture via Node (`node` v26 is available in this dev environment) importing `buildDemoState()` and merging onto `DEF` exactly as `useStore.js` does at its own `persist(Object.assign(clone(DEF), buildDemoState()), false)` call site, then hand-augment the JSON with at least one dropset, one restpause set with clusters, one per-side (unilateral) entry, one superset pairing, and non-empty `equipProfiles`/`gymCards`/`customEx`/`favEx`/`barWeights`/`exNotes` — cross-check the exact superset field name against `../openGym/frontend/src/lib/history.js`'s `supersetUnits()` before hand-authoring that part, since it wasn't located precisely in this session.
   - **RESOLVED:** Synthetic fixture (demoSeed.js + hand-augmented cases) in Plan 01-03. The user accepted this deviation on 2026-09-25; no real file will be supplied.

3. **Does openGym's bodyweight log allow more than one entry per calendar day?**
   - What we know: `BodyweightEntry` has `d` (date), `w` (weight), `t` (timestamp) — the presence of a separate timestamp alongside the date suggests multiple same-day entries might be intentional (or `t` might just be for sub-day timezone/ordering safety).
   - What's unclear: Whether `(uid, d)` should be the practical uniqueness constraint or whether `(uid, d, t)` (as proposed in the schema above) is required.
   - Recommendation: Before finalizing the `bodyweight` table's primary key, grep `useStore.js`'s bodyweight-logging action for any same-day dedupe/overwrite logic.
   - **RESOLVED:** Plan 01-06 uses a `(uid, pos)` key. openGym dedupes per date in the UI (sheets.jsx ~210), but stored duplicates are kept as they are so the round-trip stays exact.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter/Dart SDK | Entire project | ✓ | Flutter 3.47.2 / Dart 3.13.2 | — |
| Java/JVM | `openapi_generator` (dart-dio codegen wrapper) | ✗ | — | Install via `brew install openjdk` before the Wave-0 codegen spike, or use `openapi_retrofit_generator` (pure Dart, no JVM) instead |
| Node.js | Generating a realistic FND-04 fixture via `demoSeed.js`'s `buildDemoState()` | ✓ | v26.8.1 | — |
| `ctx7` CLI (Context7 fallback) | Documentation lookups in this research session | ✗ | — | Used WebSearch + WebFetch against pub.dev/GitHub directly instead; flagged every resulting package claim `[ASSUMED]` per the package-provenance rule |
| `slopcheck` (Python) | Package Legitimacy Audit | ✓ (installed this session) | 0.6.1 | No Dart/pub ecosystem support in this tool version — audit degraded to registry-only checks, all packages tagged `[ASSUMED]` |
| A real `state-<uid>.json` sample | FND-04 round-trip test fixture | ✗ | — | Synthesize via `demoSeed.js` + hand augmentation (see Open Questions #2) |

**Missing dependencies with no fallback:** none — every gap above has a documented fallback.
**Missing dependencies with fallback:** Java/JVM (fallback: install, or switch generator), a real state fixture (fallback: synthesize).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK) + `test` package for pure-Dart unit tests |
| Config file | none currently — only `test/widget_test.dart` (the default counter-app smoke test) exists; `analysis_options.yaml` has no test-specific config |
| Quick run command | `flutter test test/core/db/round_trip_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-01 | Feature-first folders exist; a Bloc's sealed states/events compile and are exhaustively handled | unit (compile-time + `bloc_test`) | `flutter test test/features/shell/bloc/shell_bloc_test.dart -x` | ❌ Wave 0 |
| FND-02 | Generated Dio clients compile and cover every `openapi.yaml` path | static/compile check + smoke test against a stub/mock Dio adapter | `flutter analyze && flutter test test/core/api/` | ❌ Wave 0 |
| FND-03 | `GymState`/`Workout`/`Routine` models correctly round-trip `phase`/`type`/`drops`/`clusters` | unit | `flutter test test/core/models/gym_state_test.dart` | ❌ Wave 0 |
| FND-04 | Real `state-<uid>.json` imports into sqflite and exports back to equivalent JSON | integration-style unit test via `sqflite_common_ffi` | `flutter test test/core/db/round_trip_test.dart` | ❌ Wave 0 |
| FND-05 | App boots to an empty themed shell (DI + routing + theme) | widget test | `flutter test test/features/shell/view/shell_page_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze && flutter test <changed-area>`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green (`flutter analyze` + `flutter test`) before `/gsd:verify-work`, matching the phase's own stated success criteria #4.

### Wave 0 Gaps
- [ ] `test/core/db/round_trip_test.dart` — covers FND-04, needs `sqflite_common_ffi` dev-dependency added first
- [ ] `test/fixtures/state_sample.json` — the synthesized fixture described in Open Questions #2
- [ ] `test/core/models/gym_state_test.dart` — covers FND-03
- [ ] `test/core/api/` smoke tests — covers FND-02 (at minimum: generated client compiles and one method can be invoked against a mocked Dio adapter)
- [ ] `test/features/shell/` — covers FND-01/FND-05
- [ ] Framework install: `flutter pub add --dev sqflite_common_ffi bloc_test mocktail` — none of these dev-dependencies exist in `pubspec.yaml` yet (only `flutter_test` and `flutter_lints`)

## Security Domain

> `security_enforcement` is not set in `.planning/config.json` — treated as enabled per default, but Phase 1 has very limited security surface (no network auth, no secrets — those are Phase 5/6). Included for completeness; most categories are N/A until later phases.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (Phase 5) | — |
| V3 Session Management | no (Phase 5) | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Use parameterized `sqflite` queries (`db.rawQuery('... WHERE uid = ?', [uid])`) exclusively — never string-interpolate user-controlled values (e.g., `uid`, exercise ids) into SQL. Validate decoded JSON shape defensively in `GymState.fromJson` (guard against non-Map/non-List types at every level, since the "representative, not enforced" spec means a real file could contain almost anything) |
| V6 Cryptography | no (no secrets stored this phase) | — |

### Known Threat Patterns for this phase's stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via string-built queries against local sqflite | Tampering | Always use `?` placeholders / `db.insert()`/`db.update()`/`db.query()` helper methods, never manual string concatenation of user-influenced values |
| Deserialization of untrusted/malformed JSON into models (a corrupted or maliciously-crafted `state-<uid>.json` from a compromised server or manual file tampering) | Tampering / Denial of Service | Defensive `fromJson` parsing (type-check every field, default gracefully) rather than force-casting (`json['x'] as List`), which would throw and crash the import path on malformed input |

## Sources

### Primary (HIGH confidence)
- `../openGym/api/openapi.yaml` (this repo's read-only reference, inspected directly) — routes, `State`/`Workout`/`Routine`/`BodyweightEntry` schemas, "representative, not enforced" language
- `../openGym/api/server.js` (inspected directly) — `readState`/`atomicWrite`/`stateFile`, `GET/PUT /api/data` handlers, active-stripping and `_rev` stamping behavior
- `../openGym/frontend/src/store/useStore.js` (inspected directly) — the `DEF` constant (full state shape)
- `../openGym/frontend/src/lib/workout-model.js` (inspected directly) — `phase`/`type`/`drops`/`clusters` helpers
- `../openGym/frontend/src/lib/format.js` (inspected directly) — `ACCENTS` color map
- `../openGym/frontend/src/lib/demoSeed.js` / `demo.js` (inspected directly) — `buildDemoState()` availability for fixture generation
- pub.dev registry API (`https://pub.dev/api/packages/<name>` and `/score`) — live version/likes/downloads/repository checks for every package listed in Standard Stack, run during this session

### Secondary (MEDIUM confidence)
- [OpenAPITools/openapi-generator dart-dio generator docs](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/dart-dio.md) — config options, `built_value` vs `json_serializable` serializer choice
- [OpenAPITools/openapi-generator GitHub issue #8497](https://github.com/OpenAPITools/openapi-generator/issues/8497) and [#15670](https://github.com/OpenAPITools/openapi-generator/issues/15670) — documented free-form/`additionalProperties` handling problems
- [OpenAPITools/openapi-generator v7.3.0 release notes](https://github.com/OpenAPITools/openapi-generator/releases/tag/v7.3.0) — OpenAPI 3.1 normalizer fixes, implying prior/ongoing edge cases
- [sqflite_common_ffi testing doc](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/testing.md) — `flutter test` bootstrap pattern
- [bloclibrary.dev architecture guide](https://bloclibrary.dev/architecture/) — layered structure, constructor-injection guidance, no specific DI package mandated

### Tertiary (LOW confidence)
- [openapi_retrofit_generator pub.dev page](https://pub.dev/packages/openapi_retrofit_generator) and [openapi_generator pub.dev page](https://pub.dev/packages/openapi_generator) — package existence/claims, not independently executed against the real spec in this session
- General WebSearch results on `flutter_bloc` + `get_it` community conventions — not an official source, used only to justify deferring `get_it`

## Metadata

**Confidence breakdown:**
- Standard stack (flutter_bloc/equatable/sqflite/dio core choices): HIGH — user-mandated, versions verified live against pub.dev
- OpenAPI generator selection: LOW — genuinely unresolved; needs a Wave-0 spike, flagged extensively in Assumptions Log and Open Questions
- FND-03 model-authoring approach (hand-author from DEF, not from openapi.yaml): HIGH — directly evidenced by reading both `openapi.yaml`'s own disclaimer and `useStore.js`'s `DEF` constant
- sqflite hybrid schema: MEDIUM — sound reasoning from verified source evidence, but not validated against a real multi-thousand-row profile
- Pitfalls (built_value, 3.1 edge cases, sqflite_common_ffi setup): MEDIUM-HIGH — cross-referenced against official GitHub issues/docs, not reproduced by actually running the generator in this session (no JVM available)

**Research date:** 2026-09-25
**Valid until:** ~30 days for the stack/architecture guidance (stable ecosystem); ~7 days for the specific pub.dev version numbers and the OpenAPI-generator recommendation, since that area is fast-moving and unresolved — re-verify immediately before the Wave-0 spike task runs.
