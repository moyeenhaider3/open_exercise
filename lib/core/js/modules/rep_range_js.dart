// SPDX-License-Identifier: AGPL-3.0-or-later

import '../js_codec.dart';
import '../js_engine_service.dart';

/// Facade for openGym `rep-range.js` normalization.
final class RepRangeJs {
  const RepRangeJs(this._engine);

  final JsEngineService _engine;

  ({int reps, int repsMin}) normalizeRepRange(num? reps, num? repsMin, [int? stride]) {
    final Object? res = _engine.call(
      'repRange.normalizeRepRange',
      <Object?>[reps ?? jsUndefined, repsMin ?? jsUndefined, stride ?? jsUndefined],
    );
    final Map<String, Object?> map = jsMap(res, 'repRange.normalizeRepRange');
    return (
      reps: jsInt(map['reps'], 'repRange.normalizeRepRange.reps'),
      repsMin: jsInt(map['repsMin'], 'repRange.normalizeRepRange.repsMin'),
    );
  }
}

extension RepRangeJsAccess on JsEngineService {
  RepRangeJs get repRange => RepRangeJs(this);
}
