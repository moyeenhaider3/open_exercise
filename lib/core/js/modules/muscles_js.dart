// SPDX-License-Identifier: AGPL-3.0-or-later

import '../js_codec.dart';
import '../js_engine_service.dart';

/// Facade for openGym `muscles.js` functions and metadata.
final class MusclesJs {
  const MusclesJs(this._engine);

  final JsEngineService _engine;

  List<String> get muscles => jsStringList(_engine.read('muscles.MUSCLES'), 'muscles.MUSCLES');

  Map<String, String> get muscleName {
    final Map<String, Object?>? raw = jsMapOrNull(_engine.read('muscles.MUSCLE_NAME'), 'muscles.MUSCLE_NAME');
    if (raw == null) return const <String, String>{};
    return raw.map((String k, Object? v) => MapEntry<String, String>(k, v?.toString() ?? ''));
  }

  List<String> inMuscleOrder(List<String> list) {
    final Object? res = _engine.call('muscles.inMuscleOrder', <Object?>[list]);
    return jsStringList(res, 'muscles.inMuscleOrder');
  }

  bool hasExplicitMuscleMetadata(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.hasExplicitMuscleMetadata', <Object?>[ex]);
    return jsBool(res, 'muscles.hasExplicitMuscleMetadata');
  }

  List<String> normalizeMuscleGroups(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.normalizeMuscleGroups', <Object?>[ex]);
    return jsStringList(res, 'muscles.normalizeMuscleGroups');
  }

  Map<String, Object?>? exerciseMuscleSnapshot(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.exerciseMuscleSnapshot', <Object?>[ex]);
    return jsMapOrNull(res, 'muscles.exerciseMuscleSnapshot');
  }
}

extension MusclesJsAccess on JsEngineService {
  MusclesJs get muscles => MusclesJs(this);
}
