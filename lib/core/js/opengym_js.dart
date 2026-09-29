// SPDX-License-Identifier: AGPL-3.0-or-later

/// Unified entry point for openGym domain logic and typed JavaScript facades.
///
/// This is the only import Phase 3+ needs for openGym logic; every function
/// delegates to the bundled openGym JavaScript runtime (JS-04).
library;

export 'js_bridge_exception.dart';
export 'js_codec.dart';
export 'js_engine_service.dart';

export 'models/history_models.dart';
export 'models/onerm_models.dart';
export 'models/phase3_models.dart';
export 'models/progression_models.dart';
export 'models/recovery_models.dart';

export 'modules/backfill_js.dart';
export 'modules/bar_js.dart';
export 'modules/effort_js.dart';
export 'modules/exercise_history_js.dart';
export 'modules/exercises_js.dart';
export 'modules/finish_workout_js.dart';
export 'modules/history_js.dart';
export 'modules/muscles_js.dart';
export 'modules/onerm_js.dart';
export 'modules/progression_copy_js.dart';
export 'modules/progression_js.dart';
export 'modules/recovery_js.dart';
export 'modules/rep_range_js.dart';
export 'modules/session_js.dart';
export 'modules/starter_js.dart';
export 'modules/units_js.dart';
export 'modules/workout_model_js.dart';
