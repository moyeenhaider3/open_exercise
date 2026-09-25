# Third-party notices

**open_exercise** is a derivative work of [**openGym**](../openGym) (path `../openGym` in this
workspace), the self-hosted gym and body-weight tracker. It is a native Flutter (Android/iOS)
port that replicates openGym's features, offline persistence and UI layout using native Flutter
widgets instead of openGym's React/Capacitor WebView.

Because it is a derivative work of openGym, this project is licensed under the same license as
openGym: the **GNU Affero General Public License v3.0 or later** (AGPL-3.0-or-later). See
[LICENSE](LICENSE) for the full license text, copied verbatim from openGym's own `LICENSE`.

Every Dart source file under `lib/` and `test/` starts with the line:

```
// SPDX-License-Identifier: AGPL-3.0-or-later
```

## openGym's own third-party notices

openGym's domain logic (1RM estimation, progression suggestions, plate math, volume/fatigue
calculations, muscle map geometry, exercise data) is executed unchanged inside this app (via a
JS engine, see PROJECT.md), and openGym's own third-party attributions for that content —
including the MuscleMap body-diagram geometry, exercise metadata/instructions sourced through
`hasaneyldrm/exercises-dataset`/ExerciseDB v1, and the exercise images/animations whose ownership
is unresolved and are not redistributed by openGym — continue to apply unchanged. See openGym's
own `NOTICE.md` (`../openGym/NOTICE.md`) for the full text of those third-party notices.

Vendored openGym files (for example the `openapi.yaml` snapshot added in Plan 01-05) keep their
original notices as shipped by openGym.

## This project's own dependencies

The Flutter/Dart packages this project depends on (see `pubspec.yaml`) are used under their
respective published licenses (MIT/BSD-style for the current Phase 1 dependency set: flutter_bloc,
equatable, sqflite, dio, go_router, path_provider, path, collection). No modifications have been
made to their source; they are consumed as-is from pub.dev.
