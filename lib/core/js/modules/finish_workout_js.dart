// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase3_models.dart';

/// Facade for openGym `doFinishWorkout` completion (both live and backfill branches) via JS shim.
final class FinishWorkoutJs {
  const FinishWorkoutJs(this._engine);

  final JsEngineService _engine;

  FinishResult completeWorkout(GymState st, int endMs) {
    final Object? res = _engine.call('finish.completeWorkout', <Object?>[st.toJson(), endMs]);
    final Map<String, Object?> map = jsMap(res, 'finish.completeWorkout');
    return FinishResult.fromJson(map);
  }
}

extension FinishWorkoutJsAccess on JsEngineService {
  FinishWorkoutJs get finish => FinishWorkoutJs(this);
}
