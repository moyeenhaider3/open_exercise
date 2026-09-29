# Plan 03-11 Summary: PlanBloc, PlanScreen & Plan-Editing Sheets

## Overview
Ported openGym's `Plan.jsx` and its associated sheets (`DayAssign`, `DayAddRoutine`, and `StarterPlanChooser`) into a BLoC-driven architecture with `PlanBloc` managing schedule and routine-catalog mutations, and `PlanScreen` rendering the 7-day schedule, routine list, and empty states.

## Key Deliverables
1. **PlanBloc Architecture (`lib/features/plan/bloc/`)**:
   - `plan_event.dart`: Sealed hierarchy of 7 public events (`PlanRoutineAdded`, `PlanRoutineMoved`, `PlanDayAssigned`, `PlanDayRoutineAdded`, `PlanDayRoutineRemoved`, `PlanStarterLoadRequested`, `PlanStarterLoaded`) and internal `PlanGymStateChanged`.
   - `plan_state.dart`: Immutable state with `PlanSignal` sealed classes (`PlanNavigateToRoutineSignal`, `PlanToastSignal`, `PlanConfirmStarterSignal`).
   - `plan_bloc.dart`: Handles routine reordering, day assignments, starter plan builds via `JsEngineService.starter.buildStarterPlan()`, and plan metadata helpers matching openGym's `PLAN_COPY`. Mutations dispatched strictly via `GymStateCubit.mutate()`.
2. **Provider Registration (`lib/app/providers/plan_providers.dart`)**:
   - `BlocProvider<PlanBloc>` registered with global access for routing and dependency injection.
3. **PlanScreen View (`lib/features/plan/view/plan_screen.dart`)**:
   - `CustomScrollView` layout containing `SliverList.builder` for routine cards, 7-day schedule grid with week-start day configuration, and empty state with starter plan loading.
   - List virtualization compliance: strictly uses `.builder` constructors with zero `ListView(` usages (UI-08).
4. **Plan Sheets (`lib/features/plan/view/sheets/`)**:
   - `day_assign_sheet.dart`: Single-pick day selector dispatching `PlanDayAssigned`.
   - `day_add_routine_sheet.dart`: Multi-routine append sheet dispatching `PlanDayRoutineAdded`.
   - `starter_plan_sheet.dart`: Preconfigured starter plans chooser with confirmation signal listener.

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- Acceptance criteria:
  - 7 sealed events in `plan_event.dart`.
  - `buildStarterPlan` called via `JsEngineService.starter`.
  - Registered in `plan_providers.dart`.
  - No `GymStateRepository` or `saveState` calls.
  - Required literal strings ('Plan', 'Schedule', 'Routines', 'Add routine', 'Choose a starter plan', 'Choose a plan') present.
  - Zero raw `ListView(` instances.
