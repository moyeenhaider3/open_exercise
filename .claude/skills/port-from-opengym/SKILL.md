---
name: port-from-opengym
description: Use when porting or implementing an openGym feature, screen, view, component, Bloc, store, API call, or domain calculation (1RM, progression, plates, volume, fatigue, history, session) into this Flutter app. Points at the original JS source and the JS-04 bridging workflow.
---

<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

## 1. Find the source

The original app lives at `../openGym` (sibling repo). Read the JS first, then match its
layout and behavior 1:1 with Material 3 widgets:

- `../openGym/frontend/src/views` -- screens
- `../openGym/frontend/src/components` -- widgets
- `../openGym/frontend/src/store` -- app state (singular `store`, not `stores`)
- `../openGym/frontend/src/lib` -- domain JS (source of truth for calculations)
- `../openGym/frontend/src/locales` -- strings
- `../openGym/frontend/src/App.jsx` -- navigation/routing
- `../openGym/api/server.js`, `../openGym/api/openapi.yaml` -- backend + API contract
- `../openGym/CLAUDE.md`, `../openGym/PROJECT_CONTEXT.md` -- background

## 2. Domain math rule (JS-04)

Never reimplement calculations in Dart. Import `lib/core/js/opengym_js.dart` (the single barrel
for openGym logic) and call its typed facades. Check current class names before writing code:

```bash
grep -n '^final class ' lib/core/js/modules/*.dart
```

Current facades: `OnermJs`, `BarJs`, `WorkoutModelJs`, `ProgressionJs`, `RecoveryJs`, `HistoryJs`,
`SessionStartJs`, `SessionMergeJs`. Audited mechanically by `bash tool/js04_audit.sh`.

## 3. Adding a new bridged function

1. If the JS module is new, vendor it with `bash tool/gen_js_bundle.sh --sync` (syncs
   `third_party/opengym/lib` + `MANIFEST.sha256` from `../openGym/frontend/src/lib`) and export it
   from `tool/js/entry.js`.
2. Add the function/constant/key name to `INVENTORY` in `tool/js/bridge-inventory.mjs`.
3. Add a typed method to the matching class in `lib/core/js/modules/<module>_js.dart`, calling
   `_engine.call('<module>.<fn>', [...])` and decoding with `lib/core/js/js_codec.dart` helpers
   (`jsUndefined` for omitted optionals). Put result shapes in `lib/core/js/models/`, and export
   any new files from `lib/core/js/opengym_js.dart`.
4. Add cases to `tool/js/fixture-cases/<module>.mjs`, then regenerate with
   `bash tool/gen_js_fixtures.sh` (writes `tool/fixtures/js-parity/<module>.json` and
   `tool/parity/parity_fixtures_data.dart`).
5. Add the new call to `tool/parity/dispatch/<module>_dispatch.dart`.
6. Run `bash tool/run_parity.sh <device-id>` (needs a running emulator/simulator -- `flutter_js`
   cannot run under plain `dart run`; comparison is exact `==`, no epsilon) and
   `bash tool/js04_audit.sh`.

## 4. App patterns (from real files)

- Feature folder: `lib/features/<feature>/{bloc,data,view}` (see `lib/features/shell`).
- State/events: `sealed class` extends `Equatable`, `final class` subclasses, `props` override;
  one `on<Event>(_onEvent, transformer: _sequential())` handler per Bloc.
- Repository injected via constructor; wired from `lib/app/dependencies.dart`
  (`AppDependencies`) and provided in `lib/app/app.dart` via `MultiRepositoryProvider`.
- Persistence: `lib/core/data/gym_state_repository.dart` (`GymStateRepository`) over
  `lib/core/db/app_database.dart` (`AppDatabase`, sqflite). Schema changes bump
  `kSchemaVersion` in `lib/core/db/schema.dart` and add an `onUpgrade` migration.
- Models under `lib/core/models` (and `lib/core/js/models`) expose `fromJson`/`toJson`.
- API access through `ApiClientFactory` (`lib/core/api/open_gym_api_client.dart`) and the
  generated client in `lib/core/api/generated`; regenerate with `bash tool/gen_api.sh`, never
  hand-edit generated output.

## 5. Rules

- SPDX `AGPL-3.0-or-later` header on every new hand-written file.
- No tests of any kind: no `test/`, `integration_test/`, `*_test.dart`, no test dev-dependencies.
  A PreToolUse hook blocks test-path writes.
- One phase at a time; wait for user approval before starting the next phase.

## 6. Verify

- `flutter analyze`
- `bash tool/js04_audit.sh`
- `bash tool/run_parity.sh <device-id>` whenever JS-bridged surface changed
