# Plan 03-05 Summary: Exercise Catalogue, Search, Favourites, Equipment & Library BLoCs

## Overview
Implemented openGym's full exercise catalogue data layer, typo-tolerant accent-insensitive multi-token search, favourites and equipment profiles, plus `LibraryBloc` (screen-scoped) and `ExercisesBloc` (app-scoped mutations with single-writer D-04 compliance).

## Key Deliverables
1. **Catalogue Generator & Asset (`tool/gen_exercise_catalogue.sh`, `assets/data/exercise_catalogue.json`)**:
   - Deterministic Node script `tool/js/gen-catalogue.mjs` extracts 1,324 exercises, 11 body parts, 28 equipment, and muscle metadata overlays.
   - Pinned CDN commit: `7455efae41b330c265e7cd4b78dfa848e7ce5ebd` (matching `../openGym/frontend/package.json`).
   - Image & GIF media URLs loaded over jsDelivr CDN; zero binary media files stored in repository assets.
   - Media attribution recorded in `NOTICE.md` (© Gym Visual via `hasaneyldrm/exercises-dataset`).
2. **Exercise Definitions & Catalogue (`lib/core/catalogue/exercise_def.dart`, `lib/core/catalogue/exercise_catalogue.dart`)**:
   - `ExerciseDef` model with `fromJson` and `fromCustom` supporting custom exercises and passthrough metadata.
   - `ExerciseCatalogue` with CDN base URLs (`kMediaImgBase`, `kMediaGifBase`), lookup, `allExercises`, `equipmentOf`, and `smOf`.
   - Wired `registerCustom` in `GymStateCubit` to keep the QuickJS EXIDX in sync on load and on custom exercise state mutations.
3. **Search, Favourites & Equipment Helpers (`lib/core/catalogue/exercise_search.dart`, `favourites.dart`, `equipment.dart`)**:
   - `normalizeStr` with 497-entry precomposed Latin diacritics decomposition table covering U+00C0–U+024F and U+1E00–U+1EFF.
   - Typo-tolerant two-pass search matching openGym's exact token matching and name-word fuzzy fallback (`nearWord`).
   - Pure Dart implementation with zero Flutter dependencies.
   - `favourites.dart`: `favIds`, `isFav`, `toggleFav`, `sortFavouritesFirst`.
   - `equipment.dart`: `kAlwaysAvailableEquipment`, `activeProfile`, `exAvailable`, `newProfile`.
4. **Library & Exercises BLoCs (`lib/features/library/bloc/*`, `lib/app/providers/library_providers.dart`)**:
   - `LibraryBloc`: Screen-scoped, implements `Library.jsx` 40-per-page pagination and full derivation pipeline (`allExercises` → `bp` → `searchExercises` → `exAvailable` → `equipmentOf`/`eqOn` → `sortFavouritesFirst`), with lazy `bestWeightFor` computation for shown rows.
   - `ExercisesBloc`: App-scoped, strictly handles exercise mutations through `GymStateCubit.mutate` (D-04) with sequential event processing.
   - Populated `libraryBlocProviders` with `ExercisesBloc`.

## Verification & Parity Results
- **Catalogue Size**:
  - `catalogue.length`: 1324
  - `bodyParts.length`: 11
  - Matches `EXDB.length`: 1324
- **Search Parity**:
  - Verified 239 queries (specific test corpus + 200 generative variants with substitutions, deletions, transpositions, and multi-word phrases) against openGym's runtime catalogue:
  ```
  Specific checks:
  matchExercise(dbBenchDef, dumbell bench): true
  matchExercise(dbBenchDef, dummbell bench): true
  matchExercise(dbBenchDef, bnech press): true
  matchExercise(dbBenchDef, presss bench): true
  searchExercises(catalogue, 'sqat').length: 0
  searchExercises(catalogue, 'roww').length: 0
  searchExercises(catalogue, 'wrist').first.n: band reverse wrist curl
  SEARCH PARITY 239/239
  ```
- **Architectural Audits**:
  - `flutter analyze`: `No issues found!` (0 errors, 0 warnings).
  - `bash tool/js04_audit.sh`: `JS-04 audit: PASS`.
  - Single-writer (D-04): `grep -rn "saveState\|GymStateRepository" lib/features/library` returned 0 matches.
  - Media check: `find assets -iname "*.gif" -o -iname "*.jpg" -o -iname "*.webp" | wc -l` returned 0.
