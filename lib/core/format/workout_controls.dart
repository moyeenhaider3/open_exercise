// SPDX-License-Identifier: AGPL-3.0-or-later

/// Workout controls configuration ported from openGym workout-controls.js.
library;

import '../models/gym_state.dart';

// Ported from ../openGym/frontend/src/lib/workout-controls.js:WC_DEFAULT
final class WorkoutControlsView {
  const WorkoutControlsView({
    required this.steppers,
    required this.setShortcuts,
    required this.pairButtons,
    required this.exerciseButtons,
  });

  final bool steppers;
  final bool setShortcuts;
  final bool pairButtons;
  final bool exerciseButtons;

  WorkoutControlsView copyWith({
    bool? steppers,
    bool? setShortcuts,
    bool? pairButtons,
    bool? exerciseButtons,
  }) {
    return WorkoutControlsView(
      steppers: steppers ?? this.steppers,
      setShortcuts: setShortcuts ?? this.setShortcuts,
      pairButtons: pairButtons ?? this.pairButtons,
      exerciseButtons: exerciseButtons ?? this.exerciseButtons,
    );
  }
}

const WorkoutControlsView kWcDefault = WorkoutControlsView(
  steppers: true,
  setShortcuts: false,
  pairButtons: false,
  exerciseButtons: false,
);

// Ported from ../openGym/frontend/src/lib/workout-controls.js:workoutControls
WorkoutControlsView workoutControls(GymState? s) {
  if (s?.wc == null) return kWcDefault;
  final wc = s!.wc!;
  return WorkoutControlsView(
    steppers: wc.steppers ?? kWcDefault.steppers,
    setShortcuts: wc.setShortcuts ?? kWcDefault.setShortcuts,
    pairButtons: wc.pairButtons ?? kWcDefault.pairButtons,
    exerciseButtons: wc.exerciseButtons ?? kWcDefault.exerciseButtons,
  );
}
