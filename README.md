# open_exercise — Local-First Flutter Reference Architecture

## What This Is

`open_exercise` is an open-source reference implementation of a local-first, cross-language mobile architecture built in native Flutter (Material 3). While it implements the feature set of **openGym** (a self-hosted fitness tracker), the core purpose of this repository is to demonstrate how to execute complex interdependent JavaScript domain logic natively within Dart, and how to build a robust offline persistence layer.

## Ecosystem Value & Core Infrastructure

This repository solves two major pain points for the Flutter developer ecosystem:

1. **Cross-Language Domain Execution (QuickJS):** Instead of rewriting complex business logic (e.g., 1RM estimation, fatigue tracking, progression math), this project bundles interdependent ES modules using `esbuild` and executes them natively in Flutter via `flutter_js` (QuickJS). It serves as a blueprint for developers needing to share domain logic between Node.js/React and native Dart environments without WebViews.
2. **Lossless Local-First Sync Engine:** Implements a highly structured `sqflite` database schema that perfectly mirrors complex JSON states (like the `state-<uid>.json` used in web backends), guaranteeing lossless round-trips, strict offline persistence, and seamless local backups.

## Reference Source (read-only)

| Area | Location | Notes |
|------|----------|-------|
| API contract | `../openGym/api/openapi.yaml` (1.5k lines) | OpenAPI spec for generated Dart models + Dio clients |
| State shape | `../openGym/frontend/src/store/useStore.js` | Mirrors backend JSON schema precisely in `sqflite` |
| Domain logic | `../openGym/frontend/src/lib/*.js` | ES modules bundled and executed via `JsEngineService` |
| Exercise DB | `lib/exercises-data.js` (888 KB) | Local JSON batch processing |

## Architecture Requirements

### Validated Foundation
- [x] **Feature-first structure** (`lib/core/`, `lib/features/`) using `flutter_bloc` + `equatable` (sealed states, explicit events, isolated logic).
- [x] **Automated Networking** Dart models and Dio clients fully generated from `openapi.yaml`.
- [x] **Offline-First Schema** `sqflite` implementation that perfectly mirrors web state structures and handles complex nested persistence without data loss.

### Active Development
- [ ] **QuickJS Bridge:** Headless execution of `lib/*.js` via `JsEngineService`.
- [ ] **Automated Parity Scripting:** Infrastructure to run original JS `vitest` fixtures against the Dart/QuickJS engine to guarantee mathematical parity.
- [ ] **Advanced SVG Parsing:** Parsing muscle map SVG path strings with `xml` + `path_drawing` and rendering via `CustomPainter` to retain dynamic data shading.
- [ ] **Background Event Management:** Exact alarm processing via `flutter_local_notifications` when the app is backgrounded.
- [ ] **File-Based Master Copy:** Local JSON backup and restore system utilizing device folder targeting.

## Constraints & Process

- **License:** AGPL-3.0-or-later. This project is a derivative work. See `LICENSE` and `NOTICE.md` for full license text and third-party attributions.
- **Stack Mandate:** `flutter_bloc`, `equatable`, `sqflite`, `Dio` (OpenAPI-generated), `flutter_js`, `flutter_local_notifications`, `xml`, `path_drawing`.
- **Quality Control:** This project prioritizes architectural strictness over automated testing. Verify all structural changes via `flutter analyze`.
