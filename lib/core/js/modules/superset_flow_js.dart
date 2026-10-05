// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

/// Typed facade for openGym lib/supersetFlow.js rest decisions (JS-04).
///
/// The navigation helpers stay in lib/features/workout/data/superset_flow.dart (Phase 3).
final class SupersetFlowJs {
  const SupersetFlowJs(this._engine);

  final JsEngineService _engine;

  /// Whether completing a set should start a rest timer.
  bool restAfterSet({
    required bool unitDone,
    required bool lastUnit,
  }) {
    final Object? result = _engine.call(
      'supersetFlow.restAfterSet',
      <Object?>[
        <String, Object?>{
          'unitDone': unitDone,
          'lastUnit': lastUnit,
        },
      ],
    );
    return jsBool(result, 'supersetFlow.restAfterSet');
  }

  /// Whether re-checking an already-completed set should start a rest.
  bool restOnRecheck({
    required bool timerRunning,
    required bool unitDone,
    required bool lastUnit,
  }) {
    final Object? result = _engine.call(
      'supersetFlow.restOnRecheck',
      <Object?>[
        <String, Object?>{
          'timerRunning': timerRunning,
          'unitDone': unitDone,
          'lastUnit': lastUnit,
        },
      ],
    );
    return jsBool(result, 'supersetFlow.restOnRecheck');
  }

  /// How long the rest after a completed set should run, in seconds.
  int restSecFor(
    List<WorkoutEntry> entries,
    List<int> unit,
    num defaultRestSec,
  ) {
    final Object? result = _engine.call(
      'supersetFlow.restSecFor',
      <Object?>[
        entries.map((WorkoutEntry e) => e.toJson()).toList(),
        unit,
        defaultRestSec,
      ],
    );
    return jsInt(result, 'supersetFlow.restSecFor');
  }

  /// The rest a completed set earns when it was a warm-up ramp set.
  int warmupRestSecFor(
    WorkoutEntry entry,
    int setIdx,
    int workRestSec,
  ) {
    final Object? result = _engine.call(
      'supersetFlow.warmupRestSecFor',
      <Object?>[
        entry.toJson(),
        setIdx,
        workRestSec,
      ],
    );
    return jsInt(result, 'supersetFlow.warmupRestSecFor');
  }
}

extension SupersetFlowJsAccess on JsEngineService {
  SupersetFlowJs get supersetFlow => SupersetFlowJs(this);
}

