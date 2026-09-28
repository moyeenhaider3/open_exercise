// SPDX-License-Identifier: AGPL-3.0-or-later

import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase3_models.dart';

/// Facade for openGym `starter.js` plans and options.
final class StarterJs {
  const StarterJs(this._engine);

  final JsEngineService _engine;

  List<StarterPlanOption> starterPlanOptions() {
    final List<Object?> list = jsList(_engine.call('starter.starterPlanOptions'), 'starter.starterPlanOptions');
    return list
        .whereType<Map<String, Object?>>()
        .map(StarterPlanOption.fromJson)
        .toList();
  }

  List<int>? starterPlanDays(String id) {
    final Object? res = _engine.call('starter.starterPlanDays', <Object?>[id]);
    if (res == null) return null;
    final List<Object?> list = jsList(res, 'starter.starterPlanDays');
    return list.map((Object? v) => jsInt(v, 'starter.starterPlanDays item')).toList();
  }

  StarterPlan? buildStarterPlan(String id) {
    final Object? res = _engine.call('starter.buildStarterPlan', <Object?>[id]);
    final Map<String, Object?>? map = jsMapOrNull(res, 'starter.buildStarterPlan');
    if (map == null) return null;
    return StarterPlan.fromJson(map);
  }
}

extension StarterJsAccess on JsEngineService {
  StarterJs get starter => StarterJs(this);
}
