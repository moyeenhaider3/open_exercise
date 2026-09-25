# Phase 2: Core Logic via QuickJS - Research

**Researched:** 2026-09-25
**Domain:** Bundling openGym's vanilla-JS domain modules and running them inside a Flutter app via `flutter_js` (QuickJS on Android, JavaScriptCore on iOS), with a non-test parity harness
**Confidence:** MEDIUM (HIGH on the JS module graph and esbuild mechanics, which were verified directly against the source and by running real bundling/version checks; LOW-MEDIUM on exact `flutter_js` runtime behavior, since its API docs are thin and some claims are `[ASSUMED]` from README/changelog text, not exercised code)

No `CONTEXT.md` exists yet for this phase (`/gsd:discuss-phase` has not run) — there is no `## User Constraints` section to reproduce here. The binding constraints are `CLAUDE.md` (below) and `PROJECT.md`/`STATE.md`.

## Project Constraints (from CLAUDE.md)

- **License:** AGPL-3.0-or-later; this port is a derivative work. Every hand-written Dart file gets `// SPDX-License-Identifier: AGPL-3.0-or-later` (established in Phase 1).
- **Stack is fixed by the user:** flutter_bloc, equatable, sqflite, Dio (OpenAPI-generated), **flutter_js**, flutter_local_notifications, flutter_passkey_service, xml, path_drawing. Phase 2 must use `flutter_js` — no swapping in `quickjs_engine` or another pure-Dart-FFI QuickJS binding, even though one exists with more modern QuickJS-NG semantics (see Pitfall 1).
- **One phase at a time; wait for approval before the next.**
- **NO TESTS rule (hook-enforced):** never write `test/`, `integration_test/`, `test_driver/`, `*_test.dart`, or install `bloc_test`/`mocktail`/`sqflite_common_ffi`/etc. No test tasks, no TDD tasks, no test-based acceptance criteria anywhere in the plan. Verify via `flutter analyze` and source/CLI assertions. JS-03's "parity script" must be a `tool/` CLI-style artifact, never a Dart test — see Pitfall 2 for what that has to mean given `flutter_js`'s runtime requirements.
- A PreToolUse hook blocks writes under test paths — plans must not route any Phase 2 artifact there.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JS-01 | openGym `frontend/src/lib/*.js` domain modules bundled (esbuild → single global/IIFE) into a Flutter asset by a reproducible script | Module graph fully mapped (Architecture Patterns); esbuild version/flags verified; vendoring pattern mirrors Phase 1's `third_party/opengym/` precedent; reproducibility fingerprint approach given (no `.git` in `../openGym`, so use `package.json` version + SHA256, not a commit hash) |
| JS-02 | `JsEngineService` loads the bundle in flutter_js and exposes typed Dart calls for 1RM, progression, plate/bar math, workout-model helpers, recovery/fatigue, history and session merge | `flutter_js` API surface documented (evaluate/evaluateAsync/JsEvalResult/onMessage); JSON round-trip pattern prescribed; function inventory per module given (Standard Stack, Code Examples); CR-02 fix (`SetEntry.resolvedPhase`) identified as an in-scope cleanup |
| JS-03 | Parity script (`tool/` CLI, not a Dart test) runs openGym's test fixtures (onerm, progression, bar, workout-model, recovery) through the Dart bridge and matches vitest results exactly | Critical finding: `flutter_js` cannot run headless under `dart run` — the "CLI script" must be a `flutter run -t <entry>` invocation on a device/emulator/simulator (Pitfall 2); fixture generation strategy given (live-computed via plain Node, not hand-transcribed or AST-scraped) because several test files derive inputs dynamically from the shipped exercise catalogue |
| JS-04 | No 1RM/progression/plate math hand-written in Dart | `SetEntry.resolvedPhase`/`_normalizedPhase` in Phase 1's `lib/core/models/set_entry.dart` already hand-ports `phaseForSet` — flagged by Phase 1's code review (CR-02) as exactly what JS-04 forbids; Phase 2 should delete the hand-port and route through `JsEngineService.phaseForSet` instead |
</phase_requirements>

## Summary

openGym's domain logic lives in `../openGym/frontend/src/lib/*.js` as plain ES modules with no Vite/React/browser dependency in the actual *code paths* that Phase 2 needs (two `import.meta` references exist but are either comment-only or guarded with `|| {}`, confirmed by directly `import`-ing every target module under plain Node 26 and calling real functions — all loaded and ran correctly). This means the entire relevant module graph (`onerm`, `progression`, `bar`, `workout-model`, `recovery`, `history`, `session-merge`, `session-start`, plus their shared dependencies `exercises`, `exercises-data`, `exercise-muscle-batch-1/2`, `muscles`, `format`, `i18n-core`, `rep-range`) can be (a) bundled by esbuild into a single IIFE for `flutter_js`, and (b) executed directly under plain Node to generate ground-truth fixtures — the same engine family (V8) that vitest itself runs on, so a live-computed fixture is definitionally what vitest would assert, without hand-transcribing numbers.

The two hardest parts of this phase are not the bundling — esbuild handles that cleanly, including the modern `import ... with { type: 'json' }` attribute syntax used by `exercise-muscle-batch-1.js` — but (1) **QuickJS version risk**: `flutter_js`'s Android QuickJS is a vendored fork last confirmed bumped to "2020-11-08" in its own changelog, of uncertain support for ES2021 runtime methods (`String.prototype.replaceAll`, used by `i18n-core.js`'s `t()`), even though esbuild can safely down-level *syntax* (optional chaining, nullish coalescing — both used ~100 times across the target modules) to a safe target; and (2) **`flutter_js` cannot run headless** — it requires a live Flutter engine, so the JS-03 "parity script" cannot be `dart run tool/parity.dart`. It must be a `flutter run -t tool/...` invocation against a device/emulator/simulator, which is compliant with the no-tests rule (no `test/`, no `flutter_test`) but is a materially different shape of "CLI script" than the project's existing `tool/gen_api.sh`/`tool/fixtures/*.mjs` precedents, and the plan must say so explicitly.

**Primary recommendation:** Vendor only the modules actually needed into `third_party/opengym/lib/` (mirroring the Phase 1 `third_party/opengym/openapi.yaml` pattern), bundle them with a pinned, exact-version esbuild (`--bundle --format=iife --global-name=OpenGymLib --target=es2019`, plus a small defensive `replaceAll` polyfill banner) into `assets/js/opengym-lib.bundle.js`; generate parity fixtures by executing the *real* vendored modules under plain Node (not vitest, not AST-scraping) into frozen `tool/fixtures/js-parity/*.json`; and implement the JS-03 parity check as a Flutter app entrypoint (`tool/parity/parity_main.dart`) run via `flutter run -t ... -d <device>` against both an Android emulator (QuickJS) and the iOS Simulator (JavaScriptCore) — both already available in this environment, with no need to add an out-of-scope macOS desktop target.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 1RM estimation, progression rules, plate/bar math, recovery/fatigue math | JS engine (bundled openGym `lib/`) | Dart (`JsEngineService`, typed result mapping) | Core value requires byte-identical math to the web app; JS-04 forbids reimplementing it in Dart |
| Workout-model field resolution (`phaseForSet`, `setType`, `dropsOf`, `syncSideAggregate`) | JS engine | Dart (`SetEntry`/`WorkoutEntry` convenience getters that *delegate* to the JS engine, not reimplement) | Currently hand-ported in Dart (`SetEntry.resolvedPhase`) — flagged in Phase 1 review (CR-02) as conflicting with JS-04; Phase 2 should replace the Dart port with a JS-bridge call, or accept it only if pure structural (no numeric derivation) and document why |
| History/session helpers used for UI *decisions* (`buildSets`, `cascadeWeight`, `workoutVolume`, `nextTrainingDay`, `streakWeeks`) | JS engine | Dart (Bloc orchestration, Phase 3) | These decide *what* happens next (progression-adjacent), in scope for JS-04 |
| History/session helpers that produce **localized UI strings** (`setLabel`, `exLine`, `fmtSec`) | Dart (Phase 3/8, its own i18n) | JS engine only for the underlying numeric input | The bundle never loads `i18n.js` (Vite-only `import.meta.glob`) or calls `_setLangState`, so `i18n-core.js`'s `t()` always resolves to the English fallback inside the JS engine regardless of the app's selected language. Do not treat JS-returned label strings as localized; Phase 2 should bridge the *data* these functions operate on, and defer real i18n of presentation strings to Phase 8 |
| Bundle build (esbuild), fixture generation (plain Node) | Dev tooling (`tool/`), not shipped | — | Neither ships in the app; both are dev-time scripts per the established `tool/gen_api.sh` precedent |
| Parity verification | Flutter app entrypoint (`tool/parity/parity_main.dart`), executed via `flutter run`, not a test | — | `flutter_js` requires a live Flutter engine; there is no headless `dart run` path (see Pitfall 2) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_js` | 0.8.7 (published 2026-01-27) `[VERIFIED: pub.dev registry]` | Runs the bundled openGym JS inside the app; QuickJS on Android/Windows/Linux, JavaScriptCore on iOS/macOS, all via Dart FFI | User-mandated in `CLAUDE.md`; only actively-maintained Flutter JS-engine plugin matching that mandate. pub.dev score 140/160, 360 likes, 113,116 downloads/30 days, MIT-licensed, `dart3-compatible`, supports android/ios/linux/macos/windows |
| `esbuild` | 0.28.2 (npm, published 2026-08-08) `[VERIFIED: npm registry]` | Bundles the ES-module graph in `../openGym/frontend/src/lib/` into a single IIFE global, because `flutter_js` cannot resolve `import`/`export` | Industry-standard fast bundler; already the bundler openGym's own `vite build` uses under the hood; supports `--format=iife`, `--global-name`, `--target` down-leveling, and the modern `import ... with { type: 'json' }` attribute syntax used by `exercise-muscle-batch-1.js` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Node.js (already installed: v26.8.1) | n/a (dev tool only, not a dependency) | Executes the *original, unbundled* openGym ES modules directly to generate ground-truth parity fixtures | Fixture generation only — never shipped, never a runtime dependency of the Flutter app |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_js` | `quickjs_engine` (bundles QuickJS-NG 0.14.0, modern ES2020+, more actively engineered) | Rejected: not in the user-mandated stack (`CLAUDE.md`). Its existence is useful context for *why* `flutter_js`'s vendored engine may be behind on ES2021+ runtime methods, informing Pitfall 1's mitigation, but do not substitute it without a new user decision |
| Hand-transcribing vitest fixture literals into Dart/JSON | AST-parsing the `*.test.js` files to auto-extract `(args, expected)` pairs | Rejected as primary approach: several fixtures (`bar.test.js`, `recovery.test.js`) derive their inputs *at runtime* from the live `EXDB` catalogue (e.g. `EXDB.find(e => e.eq === eq).id`), not from literals in the source text, so static AST extraction would miss or mis-resolve them. A generator that actually executes the real modules under Node produces exactly what vitest would compute, by construction |
| Vendoring copied `.js` files | Reading `../openGym` directly from the Phase 2 build (no vendoring) | Rejected: breaks CI/other-machine reproducibility (the sibling `../openGym` checkout is a read-only reference, not guaranteed present in every environment) and breaks the "one script rebuilds the bundle" requirement's auditability. Phase 1 already established the vendor-then-sync pattern (`third_party/opengym/openapi.yaml`, `tool/gen_api.sh --sync`) — reuse it |

**Installation (Flutter/Dart side):**
```yaml
# pubspec.yaml
dependencies:
  flutter_js: ^0.8.7
```

**Installation (Node-side dev tooling, NOT a Flutter/pubspec dependency):**
```bash
# tool/js/package.json (new, separate from pubspec.yaml — this is npm tooling used only to
# run esbuild and the fixture generator; nothing here ships in the app)
mkdir -p tool/js
cd tool/js && npm init -y
npm install --save-exact esbuild@0.28.2
# commit tool/js/package.json AND tool/js/package-lock.json for reproducibility
```

**Version verification:** confirmed live against the registries during this research session:
```
$ curl -s https://pub.dev/api/packages/flutter_js | ...   # latest.version = 0.8.7, published 2026-01-27
$ npm view esbuild version                                  # 0.28.2, published 2026-08-08
```
Both are current as of this research date; re-check before locking the plan if execution happens much later.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `flutter_js` | pub.dev | actively released (latest 2026-01-27; earliest changelog entries reference a 2020-11 QuickJS bump, so the project is multi-year) | 113,116/30 days, 360 likes, pub score 140/160 | github.com/abner/flutter_js (also mirrored at github.com/HeikoMueller/flutter_js) | **N/A — slopcheck has no `pub.dev`/Dart ecosystem support** (`--ecosystem` only accepts `pypi\|npm\|crates.io\|go\|rubygems\|maven\|packagist`) | Approved — verified manually via the pub.dev registry API (official source) instead: MIT license, `dart3-compatible`, multi-platform, high download/like counts, matches the exact name mandated in `CLAUDE.md`. Package name was supplied by the user's own constraint, not discovered via WebSearch/training, so the `[ASSUMED]` package-name-provenance rule does not apply here — but its *runtime behavior* (exact `JsEvalResult` shape, dispose/lifecycle) is still `[ASSUMED]` from README text, not exercised code (see Open Questions) |
| `esbuild` | npm | long-established (Evan Wallace's project, industry-standard; this session's `npm view` returned a routine point release from 2026-08-08) | not queried numerically, but esbuild is one of the most-downloaded npm packages overall (100M+/week class) | github.com/evanw/esbuild | **[OK]** — ran `slopcheck install esbuild --ecosystem npm --force` live in this session; returned `1 OK`, no slop/suspicious flags | Approved |

**Packages removed due to slopcheck `[SLOP]` verdict:** none
**Packages flagged as suspicious `[SUS]`:** none

*Note on `esbuild`'s postinstall script:* `npm warn install-scripts` flagged `esbuild@0.28.2 (postinstall: node install.js)` during the live check in this session. This is esbuild's well-known, expected behavior — it downloads the platform-specific native binary matching the host OS/arch after install. It is not a red flag, but the planner should still pin an *exact* version (`--save-exact`) and commit `tool/js/package-lock.json` so the download is deterministic and auditable, not a moving target.

*Note on the audit process itself:* installing `slopcheck` and running its `install esbuild` command in this session executed a real `npm install esbuild` in the working directory as a side effect (creating `node_modules/`, `package.json`, `package-lock.json` at the repo root). These were detected and removed (`rm -rf node_modules package-lock.json package.json`) immediately after the check; `git status` was confirmed clean afterward. The planner should be aware that `slopcheck install <pkg>` performs a real install as part of its check — run it inside a scratch/throwaway directory, never the repo root, when re-verifying package legitimacy during execution.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │  ../openGym/frontend/src/lib/*.js (read-only) │
                    │  onerm · progression · bar · workout-model    │
                    │  recovery · history · session-merge · deps    │
                    └───────────────────┬───────────────────────────┘
                                        │ tool/gen_js_bundle.sh --sync
                                        │ (copies only the needed files,
                                        │  same pattern as tool/gen_api.sh)
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  third_party/opengym/lib/*.js  (vendored,     │
                    │  committed — build never requires ../openGym) │
                    └───────────────────┬───────────────────────────┘
                                        │
                    ┌───────────────────┴───────────────────────────┐
                    │                                                 │
                    ▼                                                 ▼
      tool/js/entry.js (hand-written,             tool/js/gen-fixtures.mjs (plain Node,
      `export * as X from '.../X.js'`)             imports the vendored modules directly,
                    │                                calls curated representative args,
                    │ esbuild --bundle --format=iife                serializes {fn,args,expected})
                    │ --target=es2019 --global-name=OpenGymLib       │
                    │ + banner (SPDX + replaceAll polyfill)          ▼
                    ▼                                tool/fixtures/js-parity/*.json (frozen,
      assets/js/opengym-lib.bundle.js                 committed, regenerated only when the
      (Flutter asset, registered in pubspec.yaml)      vendored source changes)
                    │
                    ▼
      lib/core/js/js_engine_service.dart
      (flutter_js JavascriptRuntime, created once at
       app startup in main.dart alongside AppDatabase.open;
       evaluate(bundle) once, then evaluate() per typed call)
                    │
        ┌───────────┼─────────────────────────┐
        ▼           ▼                         ▼
  Dart result   Dart result              tool/parity/parity_main.dart
  models for    models for               (Flutter app entrypoint, NOT a test —
  1RM/plate/    progression/recovery/    run via `flutter run -t ... -d <device>`
  bar (narrow,  history/session-merge    against an Android emulator [QuickJS]
  Equatable)    (same pattern)           AND the iOS Simulator [JavaScriptCore];
                                          compares JsEngineService output to
                                          tool/fixtures/js-parity/*.json, prints
                                          PASS/FAIL, exits non-zero on mismatch)
```

### Recommended Project Structure
```
lib/core/js/
├── js_engine_service.dart     # singleton: create(), evaluate<T>(fn, args), dispose()
├── js_result_codec.dart       # shared JSON.stringify/jsonDecode call-building helper
└── models/
    ├── onerm_result.dart      # Equatable: {est, w, r} etc. (bestSetOf/is1RMRecord shape)
    ├── progression_result.dart
    ├── bar_result.dart        # plateSplit output (per-side plate list + bar weight)
    └── recovery_result.dart   # fatigueOf/strengthOf per-muscle maps

third_party/opengym/lib/       # vendored, synced (mirrors third_party/opengym/openapi.yaml)
tool/js/
├── entry.js                  # esbuild entry point, hand-written, re-exports every vendored module
├── package.json               # pinned esbuild devDependency (npm tooling, not pubspec)
└── gen-fixtures.mjs           # plain-Node fixture generator (the parity oracle)
tool/gen_js_bundle.sh           # reproducible build script (mirrors tool/gen_api.sh style)
tool/fixtures/js-parity/*.json  # frozen parity fixtures, committed
tool/parity/parity_main.dart    # Flutter app entrypoint, run via `flutter run -t`, NOT a test
assets/js/opengym-lib.bundle.js # committed build output (pubspec.yaml asset)
```

### Pattern 1: JSON round-trip bridge call (prescribed for every JS-02 typed call)

**What:** Every Dart→JS call builds a JSON-encodable argument list, evaluates a JS expression that calls the bundled function and wraps the result in `JSON.stringify(... ?? null)`, then `jsonDecode`s the string back in Dart.
**When to use:** Every single `JsEngineService` method — this is the only reliable transport `flutter_js` exposes (`evaluate()` returns a string via `JsEvalResult.stringResult`; there is no native object marshalling).
**Example:**
```dart
// Source: flutter_js README (github.com/abner/flutter_js) + this session's live verification
class JsEngineService {
  JsEngineService(this._runtime);
  final JavascriptRuntime _runtime;

  static Future<JsEngineService> create() async {
    final JavascriptRuntime runtime = getJavascriptRuntime();
    final String bundle = await rootBundle.loadString('assets/js/opengym-lib.bundle.js');
    final JsEvalResult loaded = runtime.evaluate(bundle);
    if (loaded.isError) {
      throw StateError('JS bundle failed to load: ${loaded.stacktrace}');
    }
    return JsEngineService._(runtime);
  }
  JsEngineService._(this._runtime);

  /// Never string-interpolate raw Dart values into the JS source directly (JS-injection risk,
  /// see Common Pitfalls) -- always go through jsonEncode.
  Map<String, Object?>? _callJson(String path, List<Object?> args) {
    final String argsJson = jsonEncode(args);
    final String expr = 'JSON.stringify(OpenGymLib.$path.apply(null, $argsJson) ?? null)';
    final JsEvalResult result = _runtime.evaluate(expr);
    if (result.isError) {
      throw StateError('$path failed: ${result.stacktrace}');
    }
    final Object? decoded = jsonDecode(result.stringResult);
    return decoded == null ? null : decoded as Map<String, Object?>;
  }

  OnermBestSet? bestSetOf(Map<String, Object?> entry) {
    final Map<String, Object?>? raw = _callJson('onerm.bestSetOf', <Object?>[entry]);
    return raw == null ? null : OnermBestSet.fromJson(raw);
  }
}
```

### Pattern 2: Bundle entry file (esbuild input, hand-written, not vendored)

**What:** A single small file that `export * as <name>` re-exports each vendored module so esbuild can bundle them all under one global.
**When to use:** As the one and only file passed to `esbuild --bundle`.
**Example:**
```javascript
// Source: esbuild docs (esbuild.github.io) -- `export * as ns` is standard ES2020 syntax esbuild bundles natively
// tool/js/entry.js
export * as onerm from '../../third_party/opengym/lib/onerm.js'
export * as progression from '../../third_party/opengym/lib/progression.js'
export * as bar from '../../third_party/opengym/lib/bar.js'
export * as workoutModel from '../../third_party/opengym/lib/workout-model.js'
export * as recovery from '../../third_party/opengym/lib/recovery.js'
export * as history from '../../third_party/opengym/lib/history.js'
export * as sessionMerge from '../../third_party/opengym/lib/session-merge.js'
```

```bash
# Source: esbuild.github.io/api (target down-leveling verified live in this session)
esbuild tool/js/entry.js \
  --bundle --format=iife --global-name=OpenGymLib \
  --target=es2019 \
  --banner:js="/* SPDX-License-Identifier: AGPL-3.0-or-later\n * Bundled from openGym frontend v1.3.8 (../openGym/frontend/package.json), unmodified except\n * for esbuild bundling/down-leveling. See NOTICE.md.\n */\nif(typeof String.prototype.replaceAll!=='function'){String.prototype.replaceAll=function(s,r){return this.split(s).join(r)}}" \
  --outfile=assets/js/opengym-lib.bundle.js
```

### Anti-Patterns to Avoid
- **Hand-porting any JS-lib function to Dart "for convenience" (e.g. `SetEntry.resolvedPhase`'s `_normalizedPhase`):** this is exactly what JS-04 forbids and what Phase 1's code review (CR-02) already flagged. Delete the hand-port; route through `JsEngineService` instead, even for something as small as `phaseForSet`.
- **String-concatenating raw Dart values into the JS `evaluate()` expression:** always pass arguments through `jsonEncode`, never `'estimate1RM($weight, $reps)'`-style interpolation — a note or exercise name containing `"` or `)` would corrupt or inject into the evaluated script.
- **Re-parsing the ~1-2 MB bundle on every call:** call `runtime.evaluate(bundleSource)` exactly once (at `JsEngineService.create()`), then only evaluate small per-call expressions afterward.
- **Assuming the JS-returned strings from `history.js` (`setLabel`, `exLine`) are localized:** the bundle never loads `i18n.js`/`_setLangState`; they are always English fallback strings.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 1RM estimation (Epley/Brzycki/Lombardi), progression suggestions, deload math, plate/bar splitting, fatigue/recovery decay | A Dart reimplementation of any formula in `onerm.js`/`progression.js`/`bar.js`/`recovery.js` | The bundled JS via `JsEngineService` | JS-04 is explicit; the core value ("exactly the same numbers") is defeated by any independent Dart formula, even one that looks equivalent — floating-point rounding and edge-case ordering (e.g. `REP_CAP` refusal, warm-up exclusion) are easy to get subtly wrong |
| ES module bundling for a JS engine with no import resolution | A hand-written dependency-order concatenation script | `esbuild --bundle` | Correct scope handling for `export * as`, tree of ~14 modules with cross-imports, JSON import attributes, and dead-code elimination are all solved problems esbuild already handles |
| Verifying two independently-produced numbers are "the same" | Manual eyeballing of Dart output vs. openGym's UI | The `tool/parity/` fixture-diff harness | The core value is falsifiable and needs a repeatable, frozen oracle, not spot checks |

**Key insight:** Every one of these problems already has a working, tested implementation one directory away (`../openGym/frontend/src/lib/`) — the entire point of Phase 2 is to run that code, not re-derive it.

## Common Pitfalls

### Pitfall 1: QuickJS version/feature gap breaks the bundle silently on Android
**What goes wrong:** `flutter_js`'s own changelog only documents a QuickJS bump "to version 2020-11-08" (0.2.3+0) with later patches described as narrow (`0.7.2`: "upgraded quickjs code to allow set timeout and set maxMemory"). openGym's target modules use optional chaining and nullish coalescing roughly 100 times combined, and `i18n-core.js`'s `t()` calls `String.prototype.replaceAll` (an ES2021 runtime method, not just syntax) on every translated string substitution. If the vendored QuickJS predates full support, the bundle throws a `SyntaxError` at load time (for unsupported syntax) or a `TypeError: replaceAll is not a function` at first localized-string call (for the missing runtime method) — and iOS (JavaScriptCore, fully modern) would pass while Android silently fails, or vice versa, defeating "identical numbers on both platforms."
**Why it happens:** `flutter_js` deliberately minimizes its vendored QuickJS for footprint, and its docs do not commit to a specific ECMAScript feature-support matrix.
**How to avoid:** (1) Have esbuild down-level syntax defensively with `--target=es2019` (verified live: esbuild transforms optional chaining, nullish coalescing, and spread properties below their native ES2020/ES2018 targets) — this removes the *syntax* risk regardless of the actual QuickJS build. (2) Inject a tiny guarded polyfill for `String.prototype.replaceAll` via `--banner:js` (esbuild cannot down-level runtime methods, only syntax) so the *runtime-method* risk is closed too. (3) As a first execution task, before writing any `JsEngineService` code, run the bundle through `flutter_js` on the Android emulator and smoke-test `OpenGymLib.i18n?.t ? 'ok' : 'n/a'`-style calls plus one real `i18n-core`-touching function (e.g. `history.setLabel`) to confirm no runtime error, rather than assuming the polyfill was sufficient.
**Warning signs:** `JsEvalResult.isError == true` only on Android/Windows/Linux targets, never on iOS; error text mentioning `SyntaxError` at bundle-load time or `is not a function` at call time.

### Pitfall 2: `flutter_js` cannot run headless — the JS-03 "parity script" cannot be `dart run`
**What goes wrong:** Planning JS-03 as a plain Dart CLI script (`dart run tool/parity.dart`) will fail: `flutter_js` is a Flutter *plugin* (native platform channel/FFI code registered through the Flutter engine's plugin loader), and its own documentation states plainly that it requires a running Flutter engine — there is no headless invocation path.
**Why it happens:** QuickJS is embedded via platform-specific native code (Kotlin+JNI on Android, Swift+JavaScriptCore on iOS) wired up through Flutter's plugin registration system, which only exists inside a running Flutter app process.
**How to avoid:** Build `tool/parity/parity_main.dart` as a genuine (tiny, possibly headless-UI) Flutter app entrypoint. Run it with `flutter run -t tool/parity/parity_main.dart -d <device-id>` against a real device/emulator/simulator — this is *not* `flutter test`, uses no `test/` path, no `flutter_test` package, and is not a `*_test.dart` file, so it is fully compliant with the no-tests rule; it is simply "run the app, but the app's job is to print a parity report and exit." Two devices are already available in this environment without adding any new platform folder (avoiding the "mobile-only, no desktop targets" scope note): the Android emulator (`Medium_Phone` / `sdk gphone16k arm64`, exercising the real QuickJS path) and the iOS Simulator (`apple_ios_simulator`, exercising the real JavaScriptCore path — same engine family as physical iOS). Do **not** add a `macos/` platform folder just to make the parity tool easier to run — that would violate "Out of Scope: Flutter web/desktop targets — mobile only" in REQUIREMENTS.md even though `flutter_js` itself supports macOS.
**Warning signs:** Any plan task phrased as "write a Dart script that instantiates `JavascriptRuntime` and runs under `dart run`" — this will not compile/run correctly outside a Flutter app process.

### Pitfall 3: Vitest fixtures are not literals — a static/AST scrape will silently miss cases
**What goes wrong:** Several target test files (`bar.test.js`, `recovery.test.js`) build their test inputs at runtime from the live exercise catalogue (`EXDB.find(e => e.eq === eq).id`, `musclesOf(ex)`), not from inline literal arguments. A naive script that regexes/AST-parses `expect(fn(...)).toBe(...)` call sites for literal arguments will either crash on these or produce a fixture with the wrong (or no) input.
**Why it happens:** The test authors deliberately kept fixtures "tied to the shipped catalogue" (their own comment in `recovery.test.js`) rather than hardcoding exercise IDs that could drift from the real data.
**How to avoid:** Generate fixtures by writing a **new** Node script that imports the real vendored modules and calls them with a curated table of representative args (chosen by reading each `*.test.js` file for its scenarios), computing `expected` live by executing the actual function — never by transcribing numbers out of the test file by hand, and never by statically parsing the test file's AST as the primary mechanism.
**Warning signs:** A fixture-generation script that contains regex/AST parsing of `.test.js` files as its primary data source rather than as inspiration for which scenarios to curate.

### Pitfall 4: `SetEntry.resolvedPhase` is already a JS-04 violation waiting to be inherited
**What goes wrong:** Phase 1 built `SetEntry.resolvedPhase`/`resolvedPhaseOr`/`_normalizedPhase` (in `lib/core/models/set_entry.dart`) as a hand-ported mirror of `workout-model.js`'s `phaseForSet`. Phase 1's own code review (`01-REVIEW.md`, finding CR-02) already flagged this as conflicting with JS-04 and recommended routing it through the JS bridge in Phase 2. If Phase 2 does not touch it, Phase 3's UI will keep consuming the hand-ported Dart version, and any future divergence between openGym's `phaseForSet` and this Dart copy becomes an unnoticed parity bug.
**Why it happens:** Phase 1 needed *some* phase-resolution logic before the JS bridge existed, and used a plain Dart getter as a stopgap.
**How to avoid:** As part of JS-02/JS-04 verification, either delete `SetEntry.resolvedPhase`'s Dart logic and have call sites go through `JsEngineService.workoutModel.phaseForSet(...)`, or (if a synchronous, JS-engine-free getter is truly needed for a hot path) get explicit user sign-off that this one field-resolution helper is exempt from JS-04 as "structural, not math" — do not leave it un-discussed.
**Warning signs:** `grep -rn "_normalizedPhase\|resolvedPhase" lib/` still finding logic (not just a delegating call) after Phase 2.

## Code Examples

### Fixture generator sketch (ground-truth via plain Node, not vitest, not AST scraping)
```javascript
// Source: this session's own verification (node --version: v26.8.1; all target modules import
// and execute successfully with zero transpilation)
// tool/js/gen-fixtures.mjs
import { estimate1RM, bestSetOf } from '../../third_party/opengym/lib/onerm.js'
import { writeFileSync } from 'node:fs'

const cases = [
  { fn: 'onerm.estimate1RM', args: [100, 5], expected: estimate1RM(100, 5) },
  { fn: 'onerm.estimate1RM', args: [100, 12], expected: estimate1RM(100, 12) },        // REP_CAP edge
  { fn: 'onerm.estimate1RM', args: [100, 13], expected: estimate1RM(100, 13) },        // beyond cap -> null
  {
    fn: 'onerm.bestSetOf',
    args: [{ id: 'x', sets: [{ w: 100, r: 5, done: true }, { w: 200, r: 5, done: false }] }],
    expected: bestSetOf({ id: 'x', sets: [{ w: 100, r: 5, done: true }, { w: 200, r: 5, done: false }] }),
  },
  // ... curated per-module, mirroring the scenarios in onerm.test.js / bar.test.js / etc.
]
writeFileSync('tool/fixtures/js-parity/onerm.json', JSON.stringify(cases, null, 2))
```

### Live verification performed in this research session (confirms the module graph is Node-loadable)
```
$ node tool-scratch/try_import.mjs
estimate1RM(100,5)= 116.7
bestSetOf= { est: 116.7, w: 100, r: 5 }

$ node tool-scratch/try_more.mjs
plateSplit 40
progression module loaded ok, typeof nextPrescription= function
recovery module loaded ok, typeof fatigueOf= function
history module loaded ok, typeof buildSets= function
session-merge module loaded ok, typeof buildCombinedEntries= function
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-porting `phaseForSet` to Dart (Phase 1 stopgap) | Delegate to `JsEngineService` | This phase (JS-04) | Removes a live JS-04 violation flagged by Phase 1's own review |
| N/A | `esbuild`'s `with { type: 'json' }` import-attribute parsing | Confirmed present in openGym's `exercise-muscle-batch-1.js` source; esbuild resolves this at bundle time (inlines the JSON), so the *shipped* bundle never contains the import statement at all — verify once with a real bundle build rather than assuming, since import-attribute syntax support varies across esbuild versions | If unsupported by the pinned esbuild version, the bundle build fails loudly at build time (not silently at runtime), which is the safer failure mode |

**Deprecated/outdated:** None — this is new integration work, not a migration.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `flutter_js`'s Android QuickJS build may lack full ES2020/2021 runtime-method support (specifically `String.prototype.replaceAll`) | Pitfall 1 | If actually fine, the defensive polyfill banner is harmless dead code (guarded by `typeof` check) — low cost either way, but if the risk is *understated* (more missing methods than just `replaceAll`), bundle calls could fail unpredictably on Android only |
| A2 | `flutter_js` cannot run headless via `dart run` (no way to instantiate `JavascriptRuntime` outside a running Flutter engine) | Pitfall 2, Standard Stack | This is the single largest planning-shape risk in the phase — if wrong (i.e. if there *is* a headless path via `dart:ffi` direct binding bypassing the plugin registration), the parity script could be far simpler and faster to run in CI. Verify by trying `dart run` against a trivial `getJavascriptRuntime()` call as the very first execution task, before committing to the `flutter run -t` design |
| A3 | `JsEvalResult` has fields `stringResult`, `isError`, `rawResult`, `stacktrace`, and there is no documented `dispose()` | Code Examples, Architecture Patterns | If a `dispose()` does exist and matters for memory (holding a live QuickJS context per test run across many `flutter run` invocations isn't a concern, but if `JsEngineService` needs to be recreated repeatedly inside a long-running app, an actual leak could accumulate). Verify against the installed package's Dart source (`.pub-cache`) once `flutter_js` is added to `pubspec.yaml`, rather than trusting only README text |
| A4 | `evaluate()` is synchronous and blocks the calling isolate/thread for the duration of the call (typical for FFI-backed Flutter plugins), so the ~1-2 MB initial bundle evaluation could cause a startup jank if run synchronously before `runApp()` | Architecture Patterns | If wrong (e.g. it's actually fast enough to be a non-issue, or `evaluateAsync` truly runs off-thread), the recommended "async initializer with loading indicator" design is over-engineering; if the risk is understated, first-launch jank could be worse than expected and need an isolate-based workaround (complicated by FFI pointers typically being isolate-bound) |
| A5 | openGym's own `frontend/package.json` version (`1.3.8`) plus a SHA256 of the vendored source files is an adequate reproducibility fingerprint, since `../openGym` has no `.git` in this workspace | Architecture Patterns, Package Legitimacy Audit | If `../openGym` later becomes a real git checkout (or the workspace layout changes), a commit hash would be strictly better traceability — revisit if that happens |

## Open Questions

1. **Does `flutter_js` truly have no headless/`dart run` path?**
   - What we know: its own project description says QuickJS/JavaScriptCore access goes through Dart FFI wired into the Flutter plugin system; a websearch-derived summary states plainly "Requires Flutter engine; cannot run standalone via `dart run`."
   - What's unclear: whether a trivial `getJavascriptRuntime()` + `evaluate()` call might actually work under plain `dart run` on desktop platforms (FFI *can* sometimes work outside the full plugin registration path if the native library loads directly) — this was not empirically tested in this session (no `flutter_js` dependency is installed yet; Phase 1 did not add it).
   - Recommendation: make "confirm headless vs. `flutter run`-only" the very first task of the first Phase 2 plan, before designing the rest of `tool/parity/`. If headless works, the parity script can be a much simpler `dart run tool/parity/parity_main.dart` (still not a test, still compliant) instead of a `flutter run -t` device invocation.

2. **Exact `JsEvalResult`/`JavascriptRuntime` Dart API (field names, `dispose()` existence, thread/isolate model).**
   - What we know: README-derived summary names `stringResult`, `isError`, `rawResult`, `stacktrace`, `onMessage()`, `evaluate()`, `evaluateAsync()`, `getJavascriptRuntime()`, `setInspectable()`.
   - What's unclear: a dartdoc page for the exact class members returned 404 in this session; the changelog mentions "memory leak corrections" in 0.8.5 without describing what `dispose()`-equivalent API exists.
   - Recommendation: once `flutter_js: ^0.8.7` is added to `pubspec.yaml`, read the installed package's actual Dart source under `~/.pub-cache/hosted/pub.dev/flutter_js-0.8.7/lib/` as the authoritative source before finalizing `JsEngineService`'s public API — do not rely on this research's README-derived summary for exact signatures.

3. **Does the shipped bundle need to support Windows/Linux QuickJS at all?**
   - What we know: REQUIREMENTS.md scopes this project to mobile only (Android/iOS); `flutter_js` happens to also support Windows/Linux/macOS.
   - What's unclear: whether the parity script's use of desktop platforms (if headless `dart run` doesn't work and a desktop `flutter run -d macos` fallback is ever considered) would need a `macos/`/`windows/`/`linux/` platform folder added to the *app* (out of scope) versus only to a throwaway/scratch Flutter project used solely for parity checking (in scope, since it never ships).
   - Recommendation: if the Android emulator + iOS Simulator combination (already available, no new platform folders) proves sufficient, this question is moot. Only resolve it if both of those prove unworkable for the parity harness.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Android emulator | JS-03 parity (QuickJS path) | ✓ | `Medium_Phone` (Android API 37, `sdk gphone16k arm64`), already running as `emulator-5554` | — |
| iOS Simulator | JS-03 parity (JavaScriptCore path) | ✓ | `apple_ios_simulator` emulator profile registered; iOS 26.5 runtime images present (iPhone 17 Pro, iPhone 17, etc., all currently shutdown — need `xcrun simctl boot` or `flutter emulators --launch apple_ios_simulator`) | Physical iPhone is also available wirelessly (`Xcelore's iPhone`, iOS 26.5.2) as a secondary JavaScriptCore target |
| Node.js | Fixture generation (`tool/js/gen-fixtures.mjs`) | ✓ | v26.8.1 | — |
| esbuild | JS-01 bundling | ✗ (not yet installed anywhere in either repo; `npx esbuild` would need network access on first run) | latest on npm: 0.28.2 | Install as a pinned devDependency under `tool/js/package.json` (`npm install --save-exact esbuild@0.28.2`) rather than relying on ad hoc `npx` |
| `flutter_js` (pub.dev) | JS-02 | ✗ (not yet in `pubspec.yaml` — Phase 1 deliberately did not add it) | latest: 0.8.7 | None needed — straightforward `flutter pub add flutter_js` |
| Xcode / `xcrun simctl` | Booting the iOS Simulator | ✓ | iOS 26.5 simulator runtime confirmed present via `xcrun simctl list devices available` | — |

**Missing dependencies with no fallback:** none — everything needed is either already present or a normal, no-network-surprise install (`flutter pub add`, `npm install` with an exact pinned version).

**Missing dependencies with fallback:** esbuild and `flutter_js` are simply not yet installed; both have a direct, low-risk installation path.

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so it is treated as enabled. This phase has no network/auth surface — it is purely local computation over already-trusted, locally-stored data (the same `GymState`/`Workout` data Phase 1 already persists) — so most ASVS categories do not apply. The one real risk is JS-injection into the bridge's `evaluate()` call string.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not touched by this phase |
| V3 Session Management | no | Not touched by this phase |
| V4 Access Control | no | Not touched by this phase |
| V5 Input Validation | yes | Every argument passed into a bridge call MUST go through `jsonEncode` before being placed into the evaluated JS expression string; never string-interpolate a raw Dart `String`/`num` directly into the expression (see Pattern 1 and the anti-pattern list) |
| V6 Cryptography | no | Not touched by this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JS injection via string-templated `evaluate()` calls (a workout note or custom exercise name containing `"`, `` ` ``, or `)` corrupting or extending the evaluated expression) | Tampering | Always build call arguments with `jsonEncode(args)` and pass them as a single JSON array spread with `.apply(null, ...)`, never by interpolating raw values into a hand-written argument list string |
| Loading a tampered/corrupted bundle asset silently (e.g. a bad build artifact shipped without the expected content) | Tampering | Check `JsEvalResult.isError` immediately after the initial `runtime.evaluate(bundleSource)` load in `JsEngineService.create()` and fail loudly (the code example above already does this) rather than proceeding with a partially-loaded engine |

## Sources

### Primary (HIGH confidence)
- Direct source inspection of `../openGym/frontend/src/lib/*.js` (imports/exports grepped, `import.meta` usage checked line-by-line) — this session
- Live execution: `node` v26.8.1 directly importing and calling `onerm.js`, `bar.js`, `progression.js`, `recovery.js`, `history.js`, `session-merge.js` — this session
- `npm view esbuild version` / `time.modified` — this session, npm registry
- `curl https://pub.dev/api/packages/flutter_js` and `/metrics` — this session, pub.dev registry (official)
- `esbuild.github.io/content-types/#javascript` (via WebFetch) — confirms `--target` down-leveling of optional chaining/nullish coalescing/spread
- `flutter devices` / `flutter emulators` / `xcrun simctl list devices available` — this session, confirms Android emulator + iOS Simulator availability without adding new platform folders
- `python3 -m slopcheck install esbuild --ecosystem npm --force` — this session, live legitimacy check

### Secondary (MEDIUM confidence)
- `github.com/abner/flutter_js` README (via WebFetch) — evaluate()/evaluateAsync()/onMessage()/JsEvalResult shape
- `flutter_js` CHANGELOG.md (via WebFetch) — QuickJS version bump history ("2020-11-08", "0.7.2 upgraded quickjs code")

### Tertiary (LOW confidence)
- WebSearch summary claiming "flutter_js... requires Flutter engine; cannot run standalone via `dart run`" and "5-year-old vendored copy of QuickJS" — plausible and consistent with the CHANGELOG date, but not independently confirmed against the actual native source (GitHub code search required auth and 404'd); treated as `[ASSUMED]` and flagged in Open Questions #1 and Assumption A1/A2 for empirical verification as the first execution task

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — both `flutter_js` and `esbuild` versions/legitimacy verified live against their registries in this session
- Architecture (module graph, bundling approach, fixture strategy): HIGH — verified by directly running the actual openGym source under Node, not inferred
- `flutter_js` runtime behavior (headless capability, exact API, QuickJS feature support): LOW-MEDIUM — based on README/changelog text and websearch summaries, not on exercised code, because installing `flutter_js` was out of scope for a research-only session (Phase 1 deliberately hasn't added it yet); this is the primary source of remaining risk and is called out explicitly as the first thing to verify empirically once execution starts
- Pitfalls: HIGH for the module-graph/fixture pitfalls (directly observed), MEDIUM for the QuickJS-version pitfall (plausible and evidenced by the changelog, but not confirmed against the actual bundled binary)

**Research date:** 2026-09-25
**Valid until:** ~14 days for the `flutter_js`/esbuild version pins (fast-moving npm/pub.dev ecosystem); the module-graph and bundling findings (based on the read-only `../openGym` reference source) are stable until that reference source itself changes
