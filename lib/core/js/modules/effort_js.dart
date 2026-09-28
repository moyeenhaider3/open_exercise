// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/set_entry.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase3_models.dart';

/// Facade for openGym `effort.js` functions and presets.
final class EffortJs {
  const EffortJs(this._engine);

  final JsEngineService _engine;

  double? rirOf(SetEntry s) {
    final Object? res = _engine.call('effort.rirOf', <Object?>[s.toJson()]);
    return jsDoubleOrNull(res, 'effort.rirOf');
  }

  double? toScale(String kind, num? rir) {
    final Object? res = _engine.call('effort.toScale', <Object?>[kind, rir ?? jsUndefined]);
    return jsDoubleOrNull(res, 'effort.toScale');
  }

  String? effortColor(num? rir) {
    final Object? res = _engine.call('effort.effortColor', <Object?>[rir ?? jsUndefined]);
    return jsStringOrNull(res, 'effort.effortColor');
  }

  List<EffortPreset> get presets {
    final List<Object?> list = jsList(_engine.read('effort.EFFORT_PRESETS'), 'effort.EFFORT_PRESETS');
    return list
        .whereType<Map<String, Object?>>()
        .map(EffortPreset.fromJson)
        .toList();
  }

  int get hardRir => jsInt(_engine.read('effort.HARD_RIR'), 'effort.HARD_RIR');
}

extension EffortJsAccess on JsEngineService {
  EffortJs get effort => EffortJs(this);
}
