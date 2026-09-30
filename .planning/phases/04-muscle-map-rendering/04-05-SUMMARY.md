# Plan 04-05 Summary: Stats Muscle Balance Card & Native Integration

## Executive Summary
Plan `04-05` ported openGym's `MuscleBalance` card (deferred from Phase 3.1) to Flutter using the native `BodyMap` widget and `MuscleViewJs` facade:
- **Card-scoped MuscleBalanceBloc**: Manages card state (`view`, `win`, `hard`, `selected`). Derives all numbers, sets, and shade levels from `engine.muscleView.muscleBalance`, `fatigueView`, and `strengthView` along with muscle display names from `engine.muscles.muscleName`. Runs a 60-second periodic timer matching openGym's `useNow` hook, cancelling cleanly on disposal.
- **MuscleBalanceCard**: Provides 3 views matching openGym's `Stats.jsx:145-232`:
  - **Balance view**: Window selector (`Week`, `30d`, `90d`, `All`), `Hard`/`All` toggle button when rated sets exist, native `BodyMap` shaded relative to hardest-worked muscle, top 4 bars with percentages, missed muscle chips (`_MChips`), and empty state notes.
  - **Fatigue view**: Native `BodyMap` with absolute fatigue levels, fatigue legend, explanation note, and ready/recovering/fatigued state for selected muscle.
  - **Strength view**: Native `BodyMap` with absolute strength levels and gold-glow top band, strength legend with bridged `strengthFloor`, exercise rows with estimated 1RM and decay progress opening `showExerciseHistorySheet`, and detrained rows.
- **StatsScreen Wiring**: Inserted `MuscleBalanceCard` directly between the Activity heatmap card and EffortCard when `state.workouts.isNotEmpty`, matching openGym layout order.

---

## Changes Implemented

### 1. MuscleBalanceBloc
- `lib/features/stats/bloc/muscle_balance_event.dart`:
  - Defined sealed `MuscleBalanceEvent` with 6 subclasses: `MuscleBalanceGymStateChanged`, `MuscleBalanceViewChanged`, `MuscleBalanceWindowChanged`, `MuscleBalanceHardToggled`, `MuscleBalanceMuscleToggled`, `MuscleBalanceTicked`.
- `lib/features/stats/bloc/muscle_balance_state.dart`:
  - Defined sealed `MuscleBalanceState` and `MuscleBalanceReady` containing typed views (`MuscleBalanceView`, `FatigueView`, `StrengthView`), window, hard toggle, selection, and unit.
- `lib/features/stats/bloc/muscle_balance_bloc.dart`:
  - Card-scoped Bloc subscribing to `GymStateCubit` and 60 s `Timer.periodic`.
  - Zero domain math in Dart; calls `muscleView.muscleBalance`, `muscleView.fatigueView`, and `muscleView.strengthView`.

### 2. MuscleBalanceCard & Presentation
- `lib/features/stats/view/widgets/muscle_balance_card.dart`:
  - Top `AppSegmented<String>` for Balance, Fatigue, and Strength views.
  - `_BalanceSection`: Header with hard/all toggle, window picker, `BodyMap`, `BodyMapLegend`, `_MRow` top bars, selection set count, missed muscle chips (`_MChip`).
  - `_FatigueSection`: `BodyMap` (fatigue variant), `BodyMapLegend`, status label.
  - `_StrengthSection`: `BodyMap` (strength variant), `BodyMapLegend`, exercise rows with decay bar linking to `showExerciseHistorySheet`, detrained rows.
  - `_MRow`, `_MChips`, `_MChip`, and `_StrengthExerciseItem` widgets with exact styling.
- `lib/features/stats/view/stats_screen.dart`:
  - Inserted `if (state.workouts.isNotEmpty) ...[const MuscleBalanceCard(), const SizedBox(height: 14.0)]` between Heatmap and EffortCard.

---

## Verification Results
- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS (0 forbidden imports or math operations).
- Exact acceptance criteria confirmed:
  - 6 event subclasses in `muscle_balance_event.dart`.
  - `on<MuscleBalanceEvent>(_onEvent, transformer: _sequential)` pattern followed.
  - 60 s tick with timer and subscription cancellation.
  - Exactly 3 `BodyMap` calls and 3 `BodyMapLegend` calls with fatigue and strength variants.
  - `showExerciseHistorySheet` wired to exercise rows.
  - Required message strings present verbatim.
  - Layout ordering confirmed: Heatmap (line 195) < MuscleBalanceCard (line 220) < EffortCard (line 226).
