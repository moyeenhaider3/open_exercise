// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase3_models.dart';

/// Facade for openGym `exercise-history.js` aggregation.
final class ExerciseHistoryJs {
  const ExerciseHistoryJs(this._engine);

  final JsEngineService _engine;

  ExerciseHistoryResult exerciseHistory(GymState s, String exId) {
    final Object? res = _engine.call('exerciseHistory.exerciseHistory', <Object?>[s.toJson(), exId]);
    final Map<String, Object?> map = jsMap(res, 'exerciseHistory.exerciseHistory');
    return ExerciseHistoryResult.fromJson(map);
  }
}

extension ExerciseHistoryJsAccess on JsEngineService {
  ExerciseHistoryJs get exerciseHistory => ExerciseHistoryJs(this);
}
