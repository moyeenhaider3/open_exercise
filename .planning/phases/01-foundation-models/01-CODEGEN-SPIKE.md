# Phase 1 Plan 02: OpenAPI Codegen Spike

Throwaway spike evidence for FND-02 (choosing the OpenAPI → Dart/Dio generator). Nothing here
touches the app repo's `pubspec.yaml`, `lib/`, or `test/`. All work ran in a scratch directory
outside the repo (`$SCRATCHPAD/codegen-spike/`), against a copy of the real
`../openGym/api/openapi.yaml` (OpenAPI 3.1.0, 1536 lines, 29 explicit `operationId`s across 30
requests — `GET /api/data/rev` has no `operationId` in the spec itself; see Findings).

## Task 1 Checkpoint Resolution (recorded verbatim)

Task 1 (`checkpoint:human-verify`, `gate="blocking-human"`) was already resolved with the user
before this executor started:

- **Packages: ALL APPROVED** — `openapi_generator`, `openapi_generator_annotations`,
  `openapi_retrofit_generator`, `retrofit`, `retrofit_generator`, `json_annotation`,
  `json_serializable`, `build_runner`.
- **JDK: NO.** The user declined `brew install openjdk@21` (or any JVM install). Confirmed on
  this machine: `java -version` → "Unable to locate a Java Runtime."

Consequence: **Spike A (`openapi_generator`, the official OpenAPITools `dart-dio` generator) was
NOT run.** This is not recorded as a failure of that tool — it was never exercised because it
requires a JVM the user chose not to install. Only Spike B (`openapi_retrofit_generator`, pure
Dart, no JVM) was spiked, per the scope given to this executor.

## Spike B: `openapi_retrofit_generator` (pure Dart, no JVM)

**Scratch project:** `spike_b/` (plain `dart create -t console`), `test/` removed (no-tests
project rule applies to the whole session, not just the app repo).

**Dependency versions used** (pub.dev latest as of 2026-09-25, resolved via `dart pub get`):

| Package | Version |
|---|---|
| `dio` | 5.11.1 |
| `retrofit` | 4.10.0 |
| `json_annotation` | 4.12.0 |
| `build_runner` | 2.16.1 |
| `json_serializable` | 6.14.1 |
| `retrofit_generator` | 10.2.11 |
| `openapi_retrofit_generator` | 2.0.4 |

**Config** (`openapi_generator.yaml`):
```yaml
openapi_generator:
  schema_path: api/openapi.yaml
  output_directory: lib/api
  json_serializer: json_serializable
```

### Spike B1 — plain spec, no preprocessing

The real `../openGym/api/openapi.yaml` was copied in unmodified (still OpenAPI 3.1.0, still
containing the `oneOf: [State, {type: 'null'}]` construct on `GET /api/data`'s `state` property
that Pitfall 2 flagged as a known 3.1 edge case for other generators).

**Result: ran without error on the first try.** No preprocessing/downgrade was needed, so
**Spike B2 (preprocessed 3.1→3.0-style copy) was not required and was not run** — there was
nothing to work around.

```
$ dart run openapi_retrofit_generator
OpenAPI Retrofit Generator
Generate...
> openapi v1.3.8:
    7 rest clients, 30 requests, 66 data classes.
    74 files with 2 384 lines of code.
    Success (0.185 seconds)
```

```
$ dart run build_runner build
...
Built with build_runner/aot in 14s; wrote 136 outputs.
```
(retrofit_generator: 7 output/69 no-op; json_serializable: 61 output/15 no-op; zero build errors.)

```
$ dart analyze
Analyzing spike_b...
No issues found!
```
(One unrelated pre-existing warning about a missing `package:lints/recommended.yaml` include —
caused by the scratch scaffold's `analysis_options.yaml` referencing a lint package this
throwaway project never added as a dev dependency, nothing to do with codegen — was resolved by
deleting that scaffold file; not a manual fixup on generated code.)

### Results Table

| Generator + version | Ran w/o error | `dart analyze` errors | Methods generated / 30 ops | Missing operationIds | `GET /api/data` `state` (oneOf-with-null) type | `State` schema Dart type | Manual fixups | Toolchain |
|---|---|---|---|---|---|---|---|---|
| `openapi_generator` 7.0.0 (dart-dio) | **not run** — user declined JDK install (Task 1) | n/a | n/a | n/a | n/a | n/a | n/a | JVM (unavailable) |
| `openapi_retrofit_generator` 2.0.4, plain spec (**option-retrofit**) | **yes** | **0** | **30 / 30** | none | `State?` — nullable field, correctly derived from `oneOf: [State, null]` | **Closed `@JsonSerializable()` class** with one field per declared schema property (see Findings) | none | pure Dart, no JVM |
| `openapi_retrofit_generator` 2.0.4, preprocessed spec (**option-retrofit-preprocessed**) | **not run** — plain spec already succeeded, nothing to preprocess | n/a | n/a | n/a | n/a | n/a | n/a | pure Dart, no JVM |

### Findings

1. **All 30 operations generated, none missing.** The spec has 29 explicit `operationId`s;
   `GET /api/data/rev` has no `operationId` in `openapi.yaml` (a spec gap, not a generator bug —
   confirmed by reading the spec directly). The generator synthesized `getApiDataRev` from the
   path/method, and every other method name matches its spec `operationId` 1:1 (`getData`,
   `putData`, `postActivity`, `adminAudit`, etc.). Verified by grepping every `@GET/@POST/@PUT`
   method across the 7 generated `*_client.dart` files: activity(1) + admin(8) + auth(7) +
   data(3) + meta(2) + pairing(2) + push(7) = 30.
2. **The 3.1 `oneOf`-with-null pitfall did not reproduce here.** `GetDataResponse.state` was
   generated as `final State? state;` — a plain nullable field, not a broken/empty type. This is
   the specific construct Pitfall 2 called out as a known dart-dio/OpenAPI-Generator-CLI 7.x edge
   case; `openapi_retrofit_generator` 2.0.4 handled it cleanly.
3. **`State` came out as a closed class, not a free-form `Map`.** Because `State`'s
   `additionalProperties` is implicit (the schema lists explicit properties but doesn't declare
   `additionalProperties: true`... the schema IS documented as "representative, not enforced" and
   grows with the app), the generator emitted one Dart field per *declared* property only
   (`unit`, `lang`, `theme`, `workouts`, `routines`, `week`, `dayPlan`, `bodyweight`, `customEx`,
   `exWeights`, `reminder`, `restSec`, `effort`, `equipProfiles`, `settings`, plus `_ts`/`_rev`
   renamed to `privateTs`/`privateRev` via `@JsonKey`). **Any state key the real app writes that
   isn't in this property list would be silently dropped on decode/re-encode through this
   generated `State` class** — the same failure mode Pitfall 1 warned about for `built_value`,
   reproduced here under `json_serializable` too (Assumption A3's risk materialized, just via a
   different generator). This confirms the plan's own guidance and CLAUDE.md's constraint: **the
   generated `State` model must not be used for round-tripping** — Plans 01-03/01-04's
   hand-authored `Map<String, dynamic>`-backed state model is the one that owns `/api/data`'s body
   for storage/round-trip purposes, exactly as the plan's `<context>` already mandates ("The State
   blob must stay a Map... Plans 01-03/01-04 own the typed state model"). The generated
   `DataClient.getData()`/`putData()` methods and `GetDataResponse`/`PutDataRequest` classes are
   still useful for every *other* field on those endpoints (`rev`, `baseRev`), but the `state`
   payload itself should be re-typed to `Map<String, dynamic>` (or decoded raw) rather than routed
   through the generated `State` class, when Plan 01-05 wires the real client.
4. **Zero manual fixups were needed to get from raw spec to `dart analyze` clean.** No spec
   preprocessing, no generator-config workaround, no hand-edited generated file.
5. **Minor naming quirk (non-blocking):** the `cat` query parameter on `GET /api/admin/audit`
   produced an enum named `Cat` (auto-derived from the param name) rather than something more
   descriptive like `AuditCategory`. Purely cosmetic; does not affect correctness.

## Recommendation

**`option-retrofit`** — `openapi_retrofit_generator` 2.0.4, run against the plain (unmodified)
spec. It is the only generator actually spiked (Spike A was withheld by user decision, not a
technical failure), and it cleared every acceptance bar the plan set: 0 `dart analyze` errors,
30/30 operations present, the 3.1 `oneOf`-with-null construct handled correctly, and no manual
fixups. `option-retrofit-preprocessed` is available as a fallback path if a *future* spec change
ever reintroduces a 3.1 construct this generator version can't parse, but nothing in today's spike
required it — the plain spec already passes cleanly, so preprocessing would be unnecessary
complexity in `tool/gen_api.sh` right now. `option-dart-dio` cannot be recommended or rejected on
evidence: it was never run (no JVM), consistent with Task 1's resolution.

Both `option-retrofit` and `option-retrofit-preprocessed` remain viable choices for Task 3 (no
JVM required for either); `option-dart-dio` is not viable on this machine unless the user later
reverses the JDK decision.

Decision: option-retrofit
Generator: openapi_retrofit_generator 2.0.4, plain spec, no preprocessing
