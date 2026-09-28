// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/state_parts.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

/// Facade for openGym `exercises.js` functions.
final class ExercisesJs {
  const ExercisesJs(this._engine);

  final JsEngineService _engine;

  void registerCustom(List<CustomExercise>? list) {
    final List<Map<String, Object?>> arg =
        list?.map((CustomExercise c) => c.toJson()).toList() ?? <Map<String, Object?>>[];
    _engine.call('exercises.registerCustom', <Object?>[arg]);
  }

  bool isAssisted(Object? idOrEx) {
    final Object? arg = idOrEx is Map ? idOrEx : idOrEx?.toString();
    final Object? res = _engine.call('exercises.isAssisted', <Object?>[arg]);
    return jsBool(res, 'exercises.isAssisted');
  }

  double betterWeight(Object? idOrEx, num a, num b) {
    final Object? arg = idOrEx is Map ? idOrEx : idOrEx?.toString();
    final Object? res = _engine.call('exercises.betterWeight', <Object?>[arg, a, b]);
    return jsDouble(res, 'exercises.betterWeight');
  }

  bool beatsWeight(Object? idOrEx, num w, num prev) {
    final Object? arg = idOrEx is Map ? idOrEx : idOrEx?.toString();
    final Object? res = _engine.call('exercises.beatsWeight', <Object?>[arg, w, prev]);
    return jsBool(res, 'exercises.beatsWeight');
  }

  bool isCardio(Object? idOrEx) {
    final Object? arg = idOrEx is Map ? idOrEx : idOrEx?.toString();
    final Object? res = _engine.call('exercises.isCardio', <Object?>[arg]);
    return jsBool(res, 'exercises.isCardio');
  }

  bool isBodyweightEq(Object? idOrEx) {
    final Object? arg = idOrEx is Map ? idOrEx : idOrEx?.toString();
    final Object? res = _engine.call('exercises.isBodyweightEq', <Object?>[arg]);
    return jsBool(res, 'exercises.isBodyweightEq');
  }
}

extension ExercisesJsAccess on JsEngineService {
  ExercisesJs get exercises => ExercisesJs(this);
}
