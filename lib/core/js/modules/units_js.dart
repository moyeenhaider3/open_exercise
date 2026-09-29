// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

/// Facade for openGym `units.js` conversions.
final class UnitsJs {
  const UnitsJs(this._engine);

  final JsEngineService _engine;

  /// Converts a weight value between 'kg' and 'lb' rounded to gym increments
  /// (lb to nearest 0.5, kg to nearest 0.25).
  /// Mirrors openGym `units.js` lines 9-14: `convertWeight(value, from, to)`.
  num? convertWeight(num? value, String from, String to) {
    final Object? res = _engine.call('units.convertWeight', <Object?>[
      value ?? jsUndefined,
      from,
      to,
    ]);
    if (res is num) return res;
    return null;
  }

  /// Converts a body weight value between 'kg' and 'lb' at 0.1 resolution.
  /// Mirrors openGym `units.js` lines 20-24: `convertBodyWeight(value, from, to)`.
  num? convertBodyWeight(num? value, String from, String to) {
    final Object? res = _engine.call('units.convertBodyWeight', <Object?>[
      value ?? jsUndefined,
      from,
      to,
    ]);
    if (res is num) return res;
    return null;
  }

  /// Converts an entire GymState between 'kg' and 'lb'.
  /// Mirrors openGym `units.js` lines 50-71: `convertStateUnit(S, to)`.
  GymState convertStateUnit(GymState s, String to) {
    final Object? res = _engine.call('units.convertStateUnit', <Object?>[
      s.toJson(),
      to,
    ]);
    final Map<String, Object?> map = jsMap(res, 'units.convertStateUnit');
    return GymState.fromJson(map);
  }
}

extension UnitsJsAccess on JsEngineService {
  UnitsJs get units => UnitsJs(this);
}
